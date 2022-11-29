ifeq ($(CONTAINER_NAME),)
	CONTAINER_NAME := ghcr.io/xarantolus/chromium-android-build
endif

bromite: container
	docker run -v ${CURDIR}:/build -t $(CONTAINER_NAME) -i bromite

chromium: container
	docker run -v ${CURDIR}:/build -t $(CONTAINER_NAME) -i chromium

patch-bromite: container
	docker run -v ${CURDIR}:/build -t $(CONTAINER_NAME) -i bromite patch

patch-chromium: container
	docker run -v ${CURDIR}:/build -t $(CONTAINER_NAME) -i chromium patch

patch: container
	docker run -v ${CURDIR}:/build --entrypoint /bin/bash -t $(CONTAINER_NAME) -i /build/extract_patches.sh

gc: container
	docker run --entrypoint /bin/bash -v ${CURDIR}:/build -it $(CONTAINER_NAME) -c "cd chromium/src && git gc"

container:
	docker build -t $(CONTAINER_NAME) .

clean:
	rm -rf chromium/src/out chromium/old_*
	find chromium -iwholename ".git/index.lock" -delete

install: install-windows

install-windows:
	adb.exe install -r chromium/src/out/Bromite/apks/ChromePublic.apk

shell:
	docker run --entrypoint /bin/bash -v ${CURDIR}:/build -it $(CONTAINER_NAME)

.PHONY: all chromium bromite container clean shell install-windows install patch-bromite patch-chromium patch gc
