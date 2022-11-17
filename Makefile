ifeq ($(CONTAINER_NAME),)
	CONTAINER_NAME := ghcr.io/xarantolus/chromium-android-build
endif

run: container
	docker run -v ${CURDIR}:/build -t $(CONTAINER_NAME)

container:
	docker build -t $(CONTAINER_NAME) .

clean:
	rm -rf chromium/src/out

shell:
	docker run --entrypoint /bin/bash -v ${CURDIR}:/build -it $(CONTAINER_NAME)

.PHONY: build dependencies container clean
