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
ARG BASE
# hadolint ignore=DL3007
FROM ghcr.io/opensafely-core/base-action:$BASE as base-python

RUN mkdir /workspace
WORKDIR /workspace

ARG MAJOR_VERSION
ARG BASE
# ACTION_EXEC sets the default executable for the entrypoint in the base-docker image
ENV ACTION_EXEC=python MAJOR_VERSION=${MAJOR_VERSION} BASE=${BASE}

COPY ${MAJOR_VERSION}/dependencies.txt /root/dependencies.txt
# use space efficient utility from base image
RUN /root/docker-apt-install.sh /root/dependencies.txt

# now we have python, set up a venv to install packages to, for isolation from
# system python libraries 
# hadolint ignore=DL3059
RUN python3 -m venv /opt/venv
# "activate" the venv
ENV VIRTUAL_ENV=/opt/venv/ PATH="/opt/venv/bin:$PATH"
# We ensure up-to-date build tools (which why we ignore DL3013)
# hadolint ignore=DL3013,DL3042
RUN --mount=type=cache,target=/root/.cache python -m pip install -U pip setuptools wheel pip-tools


#################################################
#
# Next, use the base-docker-plus-python image to create a build image
FROM base-python as builder
ARG MAJOR_VERSION

# install build time dependencies 
COPY ${MAJOR_VERSION}/build-dependencies.txt /root/build-dependencies.txt
RUN /root/docker-apt-install.sh /root/build-dependencies.txt

COPY ${MAJOR_VERSION}/requirements.txt /root/requirements.txt
# Note: the mount command does two things: 1) caches across builds to speed up
# local development and 2) ensures the pip cache does not get committed to the
# layer (which is why we ignore DL3042).
# hadolint ignore=DL3042
RUN --mount=type=cache,target=/root/.cache \
    python -m pip install --requirement /root/requirements.txt

################################################
#
# Finally, build the actual image from the base-python image
FROM base-python as python


ARG MAJOR_VERSION
# Some static metadata for this specific image, as defined by:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md#pre-defined-annotation-keys
# The org.opensafely.action label is used by the jobrunner to indicate this is
# an approved action image to run.
LABEL org.opencontainers.image.title="python:${MAJOR_VERSION}" \
      org.opencontainers.image.description="Python action for opensafely.org" \
      org.opencontainers.image.source="https://github.com/opensafely-core/python-docker" \
      org.opensafely.action="python:${MAJOR_VERSION}"

# copy venv over from builder image
COPY --from=builder /opt/venv /opt/venv

# tag with build info as the very last step, as it will never be cacheable
ARG BUILD_DATE
ARG REVISION
ARG BUILD_NUMBER
# RFC 3339.
LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$REVISION \
      org.opencontainers.image.build=$BUILD_NUMBER \
      org.opencontainers.image.version=$MAJOR_VERSION.$BUILD_NUMBER
