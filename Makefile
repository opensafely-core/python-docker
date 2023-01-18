INTERACTIVE:=$(shell [ -t 0 ] && echo 1)
export DOCKER_BUILDKIT=1
export BUILD_DATE=$(shell date +'%y-%m-%dT%H:%M:%S.%3NZ')
export REVISION=$(shell git rev-parse --short HEAD)

.PHONY: build
build:
	docker-compose build --pull python


.PHONY: test
test:
	docker-compose run --rm -v $(PWD):/workspace python pytest tests -v

# test basic python invocation
functional-test:
	docker-compose run --rm python -c ''
	docker-compose run --rm python python -c ''


.PHONY: lint
lint:
	@docker pull hadolint/hadolint:v2.8.0
	@docker run --rm -i hadolint/hadolint:v2.8.0 < Dockerfile

requirements.txt: requirements.in venv/bin/pip-compile
	venv/bin/pip-compile requirements.in

venv/bin/pip-compile: | venv
	venv/bin/pip install pip-tools

venv:
	virtualenv -p python3 venv


