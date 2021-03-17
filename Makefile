requirements.txt: requirements.in venv/bin/pip-compile
	venv/bin/pip-compile requirements.in

venv/bin/pip-compile: | venv
	venv/bin/pip install pip-tools

venv:
	virtualenv -p python3 venv

.PHONY: build
build:
	docker build . -t docker-python-test

.PHONY: test
test: build
	docker run -it --rm -v $(PWD):/workspace docker-python-test pytest tests -v
