IMAGE_NAME ?= docker-python-test
INTERACTIVE:=$(shell [ -t 0 ] && echo 1)


requirements.txt: requirements.in venv/bin/pip-compile
	venv/bin/pip-compile requirements.in

venv/bin/pip-compile: | venv
	venv/bin/pip install pip-tools

venv:
	virtualenv -p python3 venv

.PHONY: build
build:
	docker build . -t $(IMAGE_NAME)

.PHONY: test
ifdef INTERACTIVE
test: RUN_ARGS=-it
else
test: RUN_ARGS=
endif
test: build
	docker run $(RUN_ARGS) --rm -v $(PWD):/workspace $(IMAGE_NAME) pytest tests -v
