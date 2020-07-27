# https://github.com/tensorflow/tensorflow/blob/cab804f9712e4a430bb884f71270e74d99304158/tensorflow/tools/dockerfiles/dockerfiles/devel-gpu-jupyter.Dockerfile

# ARGs for FROM
ARG UBUNTU_VERSION=18.04
ARG ARCH=
ARG CUDA=10.1

FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION}
MAINTAINER Guillem Pascual <gpascualg93@gmail.com>

# ARGs for build
ARG ARCH
ARG CUDA
ARG CUDNN=7.6.4.38-1
ARG CUDNN_MAJOR_VERSION=7
ARG LIB_DIR_PREFIX=x86_64
ARG DEV=0

# String substitution
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Bootstrap apt and find closest mirror
RUN sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic main restricted universe multiverse' /etc/apt/sources.list && \
	sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-updates main restricted universe multiverse' /etc/apt/sources.list && \
	sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-backports main restricted universe multiverse' /etc/apt/sources.list && \
	sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-security main restricted universe multivers' /etc/apt/sources.list

ADD get_version.sh /opt/get_version.sh
RUN apt update && \
	apt install -y --no-install-recommends \
		ca-certificates \
		build-essential \
		checkinstall \
		cuda-command-line-tools-${CUDA/./-} \
		cuda-cudart-${CUDA/./-} \
		cuda-cufft-${CUDA/./-} \
		cuda-curand-${CUDA/./-} \
		cuda-cusolver-${CUDA/./-} \
		cuda-cusparse-${CUDA/./-} \
		cuda-license-${CUDA/./-} \
		libcublas${CUDA%.*}=$(/opt/get_version.sh libcublas${CUDA%.*} ${CUDA} ${CUDA}.9999999999) \
		libcudnn7=${CUDNN}+cuda${CUDA} \
		libreadline-gplv2-dev \
		libncursesw5-dev \
		libssl-dev \
		libsqlite3-dev \
		libgdbm-dev \
		libc6-dev \
		libbz2-dev \
		libffi-dev \
		liblzma-dev \
		zlib1g-dev \
		libcurl3-dev \
		libfreetype6-dev \
		libhdf5-serial-dev \
		libzmq3-dev \
		pkg-config \
		rsync \
		software-properties-common \
		unzip \
		zip \
		curl \
		bzip2 \
		cmake \
		vim \
		zlib1g-dev \
		wget \
		gnupg \
		git && \
( \
	test ${DEV} -eq 1 && \
	( \
		apt install -y --no-install-recommends \
			cuda-cudart-dev-${CUDA/./-} \
			cuda-cufft-dev-${CUDA/./-} \
			cuda-curand-dev-${CUDA/./-} \
			cuda-cusolver-dev-${CUDA/./-} \
			cuda-cusparse-dev-${CUDA/./-} \
			libcublas-dev=$(/opt/get_version.sh libcublas-dev ${CUDA} ${CUDA}.9999999999) \
			libcudnn7-dev=${CUDNN}+cuda${CUDA} \
	) || test ${DEV} -eq 0 \
)

# NodeJS
ARG NODEJS_VERSION=10.16.3
RUN wget -O /opt/node.tar.xz https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.xz && \
	cd /opt && \
	tar xf node.tar.xz

# Install miniconda
RUN wget -O /opt/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
	cd /opt && \
	chmod +x miniconda.sh && \
	./miniconda.sh -b -p /opt/miniconda

# Export path
ENV PATH=/root/bin:/root/.local/bin:/opt/node-v${NODEJS_VERSION}-linux-x64/bin:/usr/local/bin:/opt/miniconda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/lib64:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64/stubs:$LD_LIBRARY_PATH

# Install tensorflow
RUN conda create -n tf-gpu tensorflow-gpu
SHELL ["conda", "run", "-n", "tf-gpu", "/bin/bash", "-c"]

RUN conda install \
		pillow=7.2.0 \
		h5py=2.10.0 \
		mock=4.0.2 \
		scipy=1.5.2 \
		scikit-learn=0.23.1 \
		scikit-image=0.17.2 \
		future=0.18.2 \
		portpicker=1.3.1 \
		tqdm=4.48.0 \
		seaborn=0.10.1 \
		selenium=3.141.0 \
		pandas=1.0.5 \
		xlrd=1.2.0 \
		numpy=1.19.1 \
		networkx=2.4 \
		imageio=2.9.0 \
		opencv=4.4.0 \
		pyyaml=5.3.1 \
		semantic_version=2.8.5 \
		matplotlib=3.3.0 \
		jupyterlab=2.2.0 \
		ipywidgets=7.5.1 \
		-c conda-forge -y && \
	jupyter nbextension enable --py widgetsnbextension && \
	jupyter labextension install @jupyter-widgets/jupyterlab-manager@2.0 && \
	pip install --upgrade \
		pyqtree==1.0.0 \
		tensorflow-probability==0.10.1 \
		git+https://github.com/gpascualg/SenseTheFlow.git@tf-2.0

# Permanent volumnes #
######################
RUN mkdir /notebooks
VOLUME ["/notebooks"]

RUN mkdir /data
VOLUME ["/data"]

RUN mkdir /root/.vscode-server-insiders
VOLUME ["/root/.vscode-server-insiders"]

RUN mkdir /root/.vscode-server
VOLUME ["/root/.vscode-server"]

# RocksDB
ARG ROCKSDB_VERSION=6.3.6
RUN git clone https://github.com/facebook/rocksdb.git && \
	mkdir rocksdb/build && \
	cd rocksdb/build && \
	git checkout v${ROCKSDB_VERSION} && \
	cmake .. && \
	make -j $(grep -c '^processor' /proc/cpuinfo) && \
	make install && \
	cd ../.. && \
	rm -rf rocksdb

# Enable SSH access
ARG ENABLE_SSH=1
ENV ENBALE_SSH=${ENABLE_SSH}
RUN test ${ENABLE_SSH} -eq 1 && \
( \
	apt update && \
	apt install -y openssh-server && \
	mkdir /var/run/sshd && \
	mkdir -p  ~/.ssh && \
	chmod 700 ~/.ssh && \
	touch /root/.ssh/authorized_keys && \
	chmod 600 /root/.ssh/authorized_keys \
) || test "${ENABLE_SSH}" -eq 0

# Go back to the usual shell for this part
SHELL ["/bin/bash", "-c"]
RUN echo -e "#!/bin/bash\n\
echo 'Allow more inotify watches'\n\
sysctl fs.inotify.max_user_watches=524288\n\
echo 'Generating config'\n\
jupyter-notebook --allow-root --generate-config --config=/etc/jupyter-notebook.py\n\
echo 'Replacing config with password'\n\
sed -i \ \n\
	-e \"s/^# *c.NotebookApp.ip = 'localhost'$/c.NotebookApp.ip = '0.0.0.0'/\" \ \n\
	-e \"s/^# *c.NotebookApp.port = 8888$/c.NotebookApp.port = 8888/\" \ \n\
	-e \"s/^# *c.NotebookApp.open_browser = True$/c.NotebookApp.open_browser = False/\" \ \n\
	-e \"s/^# *c.IPKernelApp.matplotlib = None$/c.IPKernelApp.matplotlib = 'inline'/\" \ \n\
	-e \"s/^# *c.NotebookApp.password = u''$/c.NotebookApp.password = u'\$JUPYTER_PASSWORD'/\" \ \n\
	-e \"s/^# *c.NotebookApp.password = ''$/c.NotebookApp.password = '\$JUPYTER_PASSWORD'/\" \ \n\
	-e \"s/^# *c.NotebookApp.token = '<generated>'$/c.NotebookApp.token = ''/\" \ \n\
	-e \"s/^# *c.IPKernelApp.extensions = \[\]$/c.IPKernelApp.extensions = ['version_information']/\" \ \n\
	/etc/jupyter-notebook.py \n\
test \"\${ENABLE_JUPYTER_BASE_DIR}\" -eq 1 && (\n\
	sed -i \ \n\
		-e \"s/^# *c.NotebookApp.base_url = '\/'$/c.NotebookApp.base_url = '\/\$USERNAME\/jupyter\/'/\" \ \n\
		/etc/jupyter-notebook.py\n\
) || true\n\
# Fetch global libraries from GIT \n\
cd /opt/python-libs/\n\
eval \"GITHUB_URLS=\$GITHUB_URLS\"\n\
for url in \"\${GITHUB_URLS[@]}\"\n\
do\n\
    echo Cloning \$url\n\
    git clone \$url\n\
done\n\
cd /\n\
# Fetch extra pip libraies\n\
eval \"PIP_LIBRARIES=\$PIP_LIBRARIES\"\n\
for lib in \"\${PIP_LIBRARIES[@]}\"\n\
do\n\
    echo Installing pip \$lib\n\
    pip install -y \$lib\n\
done\n\
eval \"CONDA_LIBRARIES=\$CONDA_LIBRARIES\"\n\
for lib in \"\${CONDA_LIBRARIES[@]}\"\n\
do\n\
    echo Installing conda \$lib\n\
    conda install -y \$lib -c conda-forge\n\
done\n\
# SSH \n\
test \"${ENABLE_SSH}\" -eq 1 && /usr/sbin/sshd || true\n\
# Start \n\
jupyter-lab /notebooks --allow-root --config=/etc/jupyter-notebook.py &>/dev/null" > /opt/run_docker.sh.tpl && \
	sed 's/ *$//' /opt/run_docker.sh.tpl > /opt/run_docker.sh && \
	chmod +x /opt/run_docker.sh

###############
# Run from within the environment
ENTRYPOINT ["conda", "run", "-n", "tf-gpu", "/bin/bash", "-c", "/opt/run_docker.sh"]

