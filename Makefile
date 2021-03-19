IMAGE_NAME ?= docker-python-test
INTERACTIVE:=$(shell [ -t 0 ] && echo 1)

.PHONY: build
build: BUILD_DATE=$(shell date +'%y-%m-%dT%H:%M:%S.%3NZ')
build: GITREF=$(shell git rev-parse --short HEAD)
build:
	docker build . --tag $(IMAGE_NAME) \
		--build-arg BUILD_DATE=$(BUILD_DATE) --build-arg GITREF=$(GITREF)


.PHONY: test
ifdef INTERACTIVE
test: RUN_ARGS=-it
else
test: RUN_ARGS=
endif
test:
	docker run $(RUN_ARGS) --rm -v $(PWD):/workspace $(IMAGE_NAME) pytest tests -v


requirements.txt: requirements.in venv/bin/pip-compile
	venv/bin/pip-compile requirements.in

venv/bin/pip-compile: | venv
	venv/bin/pip install pip-tools

venv:
	virtualenv -p python3 venv


