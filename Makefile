ifeq ($(CONTAINER_NAME),)
	CONTAINER_NAME := ghcr.io/xarantolus/bromite-build:main
endif

RUN_ARGS=--rm -v "/etc/timezone:/etc/timezone:ro" -v "/etc/localtime:/etc/localtime:ro" -v ${CURDIR}:/build
# if in CI, don't use interactive flag
ifeq ($(CI),true)
	RUN_ARGS+= -t $(CONTAINER_NAME)
else
	RUN_ARGS+= -it $(CONTAINER_NAME)
endif


bromite:
	docker run $(RUN_ARGS) bromite

chromium:
	docker run -v $(RUN_ARGS) chromium

current:
	docker run --entrypoint /bin/bash $(RUN_ARGS) "/build/build_current.sh" bromite

patch-bromite:
	docker run -v $(RUN_ARGS) bromite patch

patch-chromium:
	docker run -v $(RUN_ARGS) chromium patch

patch:
	docker run -v --entrypoint /bin/bash $(RUN_ARGS) /build/extract_patches.sh

gc:
	docker run --entrypoint /bin/bash $(RUN_ARGS) -c "cd chromium/src && git gc"

clean:
	docker run --entrypoint /bin/bash $(RUN_ARGS) -c "rm -rf chromium/src/out chromium/old_* && find chromium -iwholename ".git/index.lock" -delete"

container:
	docker build -t $(CONTAINER_NAME) .

apks:
	mkdir -p apks
	cp chromium/src/out/Bromite/apks/ChromePublic.apk apks/Bromite-ChromePublic-$(shell date +%Y-%m-%d_%H-%M).apk >> /dev/null 2>&1 || true
	cp chromium/src/out/Chromium/apks/ChromePublic.apk apks/Chromium-ChromePublic-$(shell date +%Y-%m-%d_%H-%M).apk >> /dev/null 2>&1 || true
	fdupes -f apks | grep -v '^$$' | xargs rm -v >> /dev/null 2>&1 || true

install: install-windows

install-windows:
	adb.exe install -r chromium/src/out/Bromite/apks/ChromePublic.apk

shell: container
	docker run --entrypoint /bin/bash $(RUN_ARGS)

.PHONY: all chromium bromite container clean shell install-windows install patch-bromite patch-chromium patch gc apks
