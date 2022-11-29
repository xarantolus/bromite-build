ifeq ($(CONTAINER_NAME),)
	CONTAINER_NAME := ghcr.io/xarantolus/chromium-android-build
endif

RUN_ARGS=-it $(CONTAINER_NAME)
# if in CI, don't use interactive flag
ifeq ($(CI),true)
	RUN_ARGS=-t $(CONTAINER_NAME)
endif

bromite: container
	docker run -v ${CURDIR}:/build $(RUN_ARGS) bromite

chromium: container
	docker run -v ${CURDIR}:/build $(RUN_ARGS) chromium

patch-bromite: container
	docker run -v ${CURDIR}:/build $(RUN_ARGS) bromite patch

patch-chromium: container
	docker run -v ${CURDIR}:/build $(RUN_ARGS) chromium patch

patch: container
	docker run -v ${CURDIR}:/build --entrypoint /bin/bash $(RUN_ARGS) /build/extract_patches.sh

gc: container
	docker run --entrypoint /bin/bash -v ${CURDIR}:/build $(RUN_ARGS) -c "cd chromium/src && git gc"

container:
	docker build -t $(CONTAINER_NAME) .

clean:
	rm -rf chromium/src/out chromium/old_*
	find chromium -iwholename ".git/index.lock" -delete

install: install-windows

install-windows:
	adb.exe install -r chromium/src/out/Bromite/apks/ChromePublic.apk

shell: container
	docker run --entrypoint /bin/bash -v ${CURDIR}:/build -it $(CONTAINER_NAME)

.PHONY: all chromium bromite container clean shell install-windows install patch-bromite patch-chromium patch gc
