export DOCKER_BUILDKIT := "1"
export BUILD_DATE := `date +'%y-%m-%dT%H:%M:%S.%3NZ'`
export REVISION := `git rev-parse --short HEAD`

# TODO: calculate this
export BUILD_NUMBER := "1234"

build version target="python" *args="":
    docker-compose --env-file {{ version }}/env build --pull {{ args }} {{ target }} 

test version *args="tests -v":
    docker-compose --env-file {{ version }}/env run --rm -v $PWD:/workspace python pytest {{ args }}

update version *args="":
    docker-compose --env-file {{ version }}/env run --rm -v $PWD:/workspace base pip-compile {{ args }} {{ version }}/requirements.in -o {{ version }}/requirements.txt

check:
    @docker pull hadolint/hadolint:v2.12.0
    @docker run --rm -i hadolint/hadolint:v2.12.0 < Dockerfile

publish version:
    #!/bin/bash
    set -euxo pipefail
    docker tag python:{{ version }} ghcr.io/opensafely-core/python:{{ version }}
    echo docker push ghcr.io/opensafely-core/python:{{ version }}

    if test "{{ version }}" = "v1"; then
        # jupyter is only alias for v1
        docker tag python:{{ version }} ghcr.io/opensafely-core/jupyter:{{ version }}
        echo docker push ghcr.io/opensafely-core/jupyter:{{ version }}

        # v1 is also known as latest, at least until we transition fully
        docker tag python:{{ version }} ghcr.io/opensafely-core/python:latest
        docker tag python:{{ version }} ghcr.io/opensafely-core/jupyter:latest
        echo docker push ghcr.io/opensafely-core/python:latest
        echo docker push ghcr.io/opensafely-core/jupyter:latest
    fi



