ifeq ($(CONTAINER_NAME),)
	CONTAINER_NAME := ghcr.io/xarantolus/bromite-build:main
endif

ifeq ($(LOCAL_WORKSPACE_FOLDER),)
	LOCAL_WORKSPACE_FOLDER=${CURDIR}
endif

RUN_ARGS=--rm -v "/etc/timezone:/etc/timezone:ro" -v "/etc/localtime:/etc/localtime:ro" -v "${LOCAL_WORKSPACE_FOLDER}:/build" -e "CI=${CI}"
# if in CI, don't use interactive flag
ifeq ($(CI),true)
	RUN_ARGS+= -t $(CONTAINER_NAME)
else
	RUN_ARGS+= -it $(CONTAINER_NAME)
endif

help:
	@echo "See the README or Makefile for info on targets"

confirm-branch-reset:
	@if [ "$(CI)" != "true" ]; then \
		read -p "This will reset the current branch, which might lead to a complete rebuild. Do you want to continue? [y/N] " REPLY && echo && if [ ! $${REPLY:-'N'} = 'y' ]; then echo "Aborting."; exit 1; fi \
	fi

bromite: confirm-branch-reset
	docker run $(RUN_ARGS) bromite
	make apks

chromium: confirm-branch-reset
	docker run $(RUN_ARGS) chromium
	make apks

potassium: confirm-branch-reset
	docker run $(RUN_ARGS) potassium
	make apks

upgrade: confirm-branch-reset
	docker run --entrypoint /bin/bash $(RUN_ARGS) "/build/upgrade.sh"

current: current-potassium

current-potassium:
	docker run --entrypoint /bin/bash $(RUN_ARGS) "/build/build_current.sh" potassium
	make apks

patch-bromite: confirm-branch-reset
	docker run $(RUN_ARGS) bromite patch

patch-chromium: confirm-branch-reset
	docker run $(RUN_ARGS) chromium patch

patches: patch
patch:
	docker run --entrypoint /bin/bash $(RUN_ARGS) /build/extract_patches.sh

gc:
	docker run --entrypoint /bin/bash $(RUN_ARGS) -c "cd chromium/src && git gc"

clean: confirm-branch-reset
	docker run --entrypoint /bin/bash $(RUN_ARGS) -c "rm -rf chromium/src/out chromium/old_* && find chromium -iwholename ".git/index.lock" -delete"

container:
	docker build -t $(CONTAINER_NAME) .

apks:
	mkdir -p apks
	$(eval SUFFIX:="$(shell date +%Y-%m-%d_%H-%M)_$(shell cat patches/BROMITE_VERSION)")
	cp chromium/src/out/Potassium/apks/ChromePublic.apk apks/Potassium-ChromePublic-$(SUFFIX).apk >> /dev/null 2>&1 || true
	cp chromium/src/out/Bromite/apks/ChromePublic.apk apks/Bromite-ChromePublic-$(SUFFIX).apk >> /dev/null 2>&1 || true
	cp chromium/src/out/Chromium/apks/ChromePublic.apk apks/Chromium-ChromePublic-$(SUFFIX).apk >> /dev/null 2>&1 || true
	fdupes -f apks | grep -v '^$$' | xargs rm -v >> /dev/null 2>&1 || true

install: install-windows

install-windows:
	adb.exe install -r chromium/src/out/Potassium/apks/ChromePublic.apk

shell:
	docker run --entrypoint /bin/bash $(RUN_ARGS)

.PHONY: *
