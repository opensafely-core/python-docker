FROM ghcr.io/opensafely/base-docker

RUN apt-get update --fix-missing

# For numba
RUN apt-get install -y llvm-10 llvm-10-dev

RUN apt-get install -y python3.8 python3.8-dev python3-pip
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1

# Install pip requirements
COPY requirements.txt /tmp/
RUN LLVM_CONFIG=/usr/bin/llvm-config-10 python -m pip install --requirement /tmp/requirements.txt

RUN mkdir /workspace
WORKDIR /workspace
CMD python
