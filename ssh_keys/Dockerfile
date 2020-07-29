# https://github.com/tensorflow/tensorflow/blob/cab804f9712e4a430bb884f71270e74d99304158/tensorflow/tools/dockerfiles/dockerfiles/devel-gpu-jupyter.Dockerfile

# ARGs for FROM
ARG UBUNTU_VERSION=18.04
ARG ARCH=
ARG CUDA=10.1

FROM ubuntu${ARCH:+-$ARCH}:${UBUNTU_VERSION}
MAINTAINER Guillem Pascual <gpascualg93@gmail.com>

# String substitution
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Install miniconda
RUN apt update && \
    apt install -y \
        wget \
        keychain && \
    wget -O /opt/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
	cd /opt && \
	chmod +x miniconda.sh && \
	./miniconda.sh -b -p /opt/miniconda

# Export path
ENV PATH=/opt/miniconda/bin:$PATH
RUN conda install docker-py=4.2.2 -c conda-forge -y
ADD main.py /opt/main.py

# Permanent volumnes #
######################
RUN mkdir /keys
VOLUME ["/keys"]

# SSH fix
# RUN  echo "    IdentityFile ~/.ssh/id_rsa" >> /etc/ssh/ssh_config

###############
# Run from within the environment
ENTRYPOINT ["python", "-u", "/opt/main.py"]
