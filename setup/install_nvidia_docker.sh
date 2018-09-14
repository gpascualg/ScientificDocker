#!/bin/bash

# Already installed
if [ -f /usr/bin/nvidia-container-runtime ]
then
	exit 1
fi

# Has nvidia-docker
if [ -f $(which nvidia-docker) ]
then
	docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
	apt-get purge -y nvidia-docker
fi

# Are we running a compatible distribution?
COMPATIBLE=0
NVIDIA_COMPATIBLE=0
DISTRIBUTION=$(. /etc/os-release;echo $ID$VERSION_ID)
DISTRO_NAME=${DISTRIBUTION:0:6}
DISTRO_VERSION=${DISTRIBUTION:6}

# Some Debian versions are supported officially
if [ "$DISTRO_NAME" == "debian" ]
then
    COMPATIBLE=1
    if [ "$DISTRO_VERSION" -eq "8" ] || [ "$DISTRO_VERSION" -eq "9" ]
    then
        NVIDIA_COMPATIBLE=1
    fi
fi

# Some Ubuntu versions are supported officially
if [ "$DISTRO_NAME" == "ubuntu" ]
then
    COMPATIBLE=1
    if [ "$DISTRO_VERSION" -eq "14.04" ] || [ "$DISTRO_VERSION" -eq "16.04" ] || [ "$DISTRO_VERSION" -eq "18.04" ]
    then
        NVIDIA_COMPATIBLE=1
    fi
fi

# Use oficial channel
if [ "$NVIDIA_COMPATIBLE" -eq "1" ]
then
    # Install repo and we are ready to go
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$DISTRIBUTION/nvidia-docker.list >/etc/apt/sources.list.d/nvidia-docker.list
    apt-get update
    apt-get install -y nvidia-docker2

    # Restart docker
    service docker restart

    exit 0
fi

# Is it compatible at all?
if [ "$COMPATIBLE" -eq "0" ]
then
    echo "It seems like you are on an unsupported OS"
    exit 1
fi

# Install nvidia runtimes using ubuntu 16.04 as base
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' | sed 's/-ce//')
wget https://nvidia.github.io/libnvidia-container/ubuntu16.04/amd64/libnvidia-container1_1.0.0~alpha.3-1_amd64.deb
wget https://nvidia.github.io/libnvidia-container/ubuntu16.04/amd64/libnvidia-container-tools_1.0.0~alpha.3-1_amd64.deb
wget https://nvidia.github.io/nvidia-container-runtime/ubuntu16.04/amd64/nvidia-container-runtime_1.1.1+docker${DOCKER_VERSION}-1_amd64.deb
dpkg -i libnvidia-container1_*.deb libnvidia-container-tools_*.deb nvidia-container-runtime_*.deb
rm libnvidia-container1_*.deb libnvidia-container-tools_*.deb nvidia-container-runtime_*.deb

# Configure docker daemon
cat > /etc/docker/daemon.json <<- EOM
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOM

# Fix for debian
if [ "$DISTRO_NAME" == "debian" ]
then
	sed -i 's/ldconfig.real/ldconfig/' /etc/nvidia-container-runtime/config.toml
fi

# Restart docker
service docker restart
