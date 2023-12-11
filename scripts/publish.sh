#!/bin/bash
set -euo pipefail

version=$1
registry=ghcr.io/opensafely-core

run() {
    echo "$@"
    if test "${PUBLISH:-}" = "true"; then
        # shellcheck disable=SC2068
        $@
    fi
}

publish() {
    local local_tag=$1;
    local remote_tag=$2;

    run docker tag "$local_tag" "$remote_tag"
    run docker push "$remote_tag"
}

full_version="$(docker inspect --format='{{ index .Config.Labels "org.opencontainers.image.version"}}' "python:$version")"

publish "python:$version" "$registry/python:$version"
publish "python:$version" "$registry/python:${full_version}"

if test "$version" = "v1"; then
    # jupyter is only alias for v1
    publish "python:$version" "$registry/jupyter:$version"

    # v1 is also known as latest, at least until we transition fully
    publish "python:$version" "$registry/python:latest"
    publish "python:$version" "$registry/jupyter:latest"
fi
