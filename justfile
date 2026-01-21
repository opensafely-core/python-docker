set dotenv-load := true

export UBUNTU_PRO_TOKEN_FILE := env_var_or_default('UBUNTU_PRO_TOKEN_FILE', justfile_directory() + "/.secrets/ubuntu_pro_token")
export DOCKER_BUILDKIT := "1"
# technically, these could differ by 1 seconds, but thats unlikely and doesn't matter
# human readable, used as label in docker image
export BUILD_DATE := `date +'%y-%m-%dT%H:%M:%S.%3NZ'`
# monotonic, used as label in docker image *and* in docker tag
export BUILD_NUMBER := `date +'%y%m%d%H%M%S'`
export REVISION := `git rev-parse --short HEAD`

ensure-pro-token:
  #!/bin/bash
  set -euo pipefail
  token_file="{{ UBUNTU_PRO_TOKEN_FILE }}"
  if test -z "${UBUNTU_PRO_TOKEN:-}"; then
    echo "UBUNTU_PRO_TOKEN is required to create $token_file" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$token_file")"
  umask 077
  printf '%s' "$UBUNTU_PRO_TOKEN" > "$token_file"

# build docker image for version
build version target="python" *args="": ensure-pro-token
    docker compose --env-file {{ version }}/env build --pull {{ args }} {{ target }} 


# test docker image for version
test version *args="tests -v": (build version)
    docker compose --env-file {{ version }}/env run --rm -v $PWD:/workspace python pytest {{ args }}


# run pip-compile to add new dependencies, or update existing ones with --upgrade
update version *args="":
    docker compose --env-file {{ version }}/env run --rm -v $PWD:/workspace base pip-compile {{ args }} {{ version }}/requirements.in -o {{ version }}/requirements.txt
    {{ just_executable() }} render {{ version }}
    {{ just_executable() }} test {{ version }}

# render package version information
render version *args:
    docker compose --env-file {{ version }}/env run --rm -v $PWD:/workspace python ./scripts/render.py {{ args }} > {{ version }}/packages.md


# run linters
check:
    @docker run --rm -i hadolint/hadolint:v2.14.0 < Dockerfile
    @ls scripts/*.sh | xargs docker run --rm -v "$PWD:/mnt:ro" koalaman/shellcheck:v0.11.0
    @docker run --rm -v "$PWD:/repo:ro" --workdir /repo rhysd/actionlint:1.7.10 -color


# publish version (dry run by default - pass "true" to perform publish)
publish version publish="false":
    PUBLISH={{ publish }} ./scripts/publish.sh {{ version }}
