IMAGE_NAME ?= docker-python-test


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
test: build
	docker run -it --rm -v $(PWD):/workspace $(IMAGE_NAME) pytest tests -v
