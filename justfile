export DOCKER_BUILDKIT := "1"
# technically, these could differ by 1 seconds, but thats unlikely and doesn't matter
# human readable, used as label in docker image
export BUILD_DATE := `date +'%y-%m-%dT%H:%M:%S.%3NZ'`
# monotonic, used as label in docker image *and* in docker tag
export BUILD_NUMBER := `date +'%y%m%d%H%M%S'`
export REVISION := `git rev-parse --short HEAD`

# build docker image for version
build version target="python" *args="":
    docker-compose --env-file {{ version }}/env build --pull {{ args }} {{ target }} 


# test docker image for version
test version *args="tests -v": (build version)
    docker-compose --env-file {{ version }}/env run --rm -v $PWD:/workspace python pytest {{ args }}


# run pip-compile to add new dependencies, or update existing ones with --upgrade
update version *args="": (build version)
    docker-compose --env-file {{ version }}/env run --rm -v $PWD:/workspace base pip-compile {{ args }} {{ version }}/requirements.in -o {{ version }}/requirements.txt
    {{ just_executable() }} render {{ version }}


# render package version information
render version *args:
    docker-compose --env-file {{ version }}/env run --rm -v $PWD:/workspace python ./scripts/render.py {{ args }} > {{ version }}/packages.md


# run linters
check:
    @docker pull hadolint/hadolint:v2.12.0
    @docker run --rm -i hadolint/hadolint:v2.12.0 < Dockerfile


# publish version (dry run by default - pass "true" to perform publish)
publish version publish="false":
    PUBLISH={{ publish }} ./scripts/publish.sh {{ version }}
