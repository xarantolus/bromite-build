ifeq ($(CONTAINER_NAME),)
	CONTAINER_NAME := ghcr.io/xarantolus/chromium-android-build
endif

all: chromium bromite

chromium: container
	docker run -v ${CURDIR}:/build -t $(CONTAINER_NAME) chromium

bromite:
	docker run -v ${CURDIR}:/build -t $(CONTAINER_NAME) bromite

container:
	docker build -t $(CONTAINER_NAME) .

clean:
	rm -rf chromium/src/out chromium/old_*

shell:
	docker run --entrypoint /bin/bash -v ${CURDIR}:/build -it $(CONTAINER_NAME)

.PHONY: all chromium bromite container clean shell
