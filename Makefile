ifeq ($(CONTAINER_NAME),)
	CONTAINER_NAME := ghcr.io/xarantolus/chromium-android-build
endif

run: bromite container
	docker run -v ${CURDIR}:/build -t $(CONTAINER_NAME)

container:
	docker build -t $(CONTAINER_NAME) .

bromite:
	if test -d "bromite"; then cd bromite && git pull --no-rebase; else git clone "https://github.com/bromite/bromite.git"; fi

clean:
	rm -rf chromium/src/out

.PHONY: bromite build dependencies container clean
