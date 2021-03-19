# syntax=docker/dockerfile:1.2
#################################################
#
# We need base python dependencies on both the builder and python images, so
# create base image with those installed to save installing them twice.
#
# DL3007 ignored because base-docker a) doesn't have any other tags currently,
# and b) we specifically always want to build on the latest base image, by
# design.
#
# hadolint ignore=DL3007
FROM ghcr.io/opensafely-core/base-docker:latest as base-python
COPY dependencies.txt /root/dependencies.txt
# use space efficient utility from base image
RUN /root/docker-apt-install.sh /root/dependencies.txt

#################################################
#
# Next, use the base-docker-plus-python image to create a build image
FROM base-python as builder

# install build time dependencies 
COPY build-dependencies.txt /root/build-dependencies.txt
RUN /root/docker-apt-install.sh /root/build-dependencies.txt

# install everything in venv for isolation from system python libraries
RUN python3 -m venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv/ PATH="/opt/venv/bin:$PATH" LLVM_CONFIG=/usr/bin/llvm-config-10

COPY requirements.txt /root/requirements.txt
# We ensure up-to-date build tools (which why we ignore DL3013)
# Note: the mount command does two things: 1) caches across builds to speed up
# local development and 2) ensures the pip cache does not get committed to the
# layer (which is why we ignore DL3042).
# hadolint ignore=DL3013,DL3042
RUN --mount=type=cache,target=/root/.cache \
    python -m pip install -U pip setuptools wheel && \
    python -m pip install --requirement /root/requirements.txt

################################################
#
# Finally, build the actual image from the base-python image
FROM base-python as python

# Some static metadata for this specific image, as defined by:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md#pre-defined-annotation-keys
# The org.opensafely.action label is used by the jobrunner to indicate this is
# an approved action image to run.
LABEL org.opencontainers.image.title="python" \
      org.opencontainers.image.description="Python action for opensafely.org" \
      org.opencontainers.image.source="https://github.com/opensafely-core/python-docker" \
      org.opensafely.action="python"

# copy venv over from builder image
COPY --from=builder /opt/venv /opt/venv
# ACTION_EXEC sets the default executable for the entrypoint in the base-docker image
ENV VIRTUAL_ENV=/opt/venv/ PATH="/opt/venv/bin:$PATH" ACTION_EXEC=python

RUN mkdir /workspace
WORKDIR /workspace

# tag with build info as the very last step, as it will never be cached
ARG BUILD_DATE
ARG GITREF
LABEL org.opencontainers.image.created=$BUILD_DATE org.opencontainers.image.revision=$GITREF
