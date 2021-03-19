#################################################
#
# First build a base python image from the OS base image, so we only do this once.
FROM ghcr.io/opensafely-core/base-docker as base-python
COPY dependencies.txt .
# use space efficient utility from base image
RUN /root/docker-apt-install.sh dependencies.txt

#################################################
#
# Next, use that to create a build image
FROM base-python as builder

# install build time dependencies 
COPY build-dependencies.txt .
RUN /root/docker-apt-install.sh build-dependencies.txt

# install everything in venv for isolation from system python libraries
RUN python3 -m venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv/ PATH="/opt/venv/bin:$PATH" LLVM_CONFIG=/usr/bin/llvm-config-10

COPY requirements.txt .
# We ensure up-to-date build tools
# Note: the mount command does two things: 1) caches across builds to speed up
# local development and 2) ensures the pip cache does not get committed to the
# layer.
RUN python -m pip install -U pip setuptools wheel && \
    python -m pip install --requirement requirements.txt

################################################
#
# Finally, build the actual image from the base-python image
FROM base-python as python

# Some static metadata for this specific image
LABEL org.label-schema.name="python" \
      org.label-schema.description="Python action for opensafely.org" \
      org.label-schema.vcs-url="https://github.com/opensafely-core/python-docker" \
      org.opensafely.action="python"

# copy venv over from builder image
COPY --from=builder /opt/venv /opt/venv
# ACTION_EXEC is the default entrypoint executable
ENV VIRTUAL_ENV=/opt/venv/ PATH="/opt/venv/bin:$PATH" ACTION_EXEC=python

RUN mkdir /workspace
WORKDIR /workspace

# tag with build info
ARG BUILD_DATE
ARG GITREF
LABEL org.label-schema.build-date=$BUILD_DATE org.label-schema.vcs-ref=$GITREF
