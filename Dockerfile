# https://github.com/tensorflow/tensorflow/blob/cab804f9712e4a430bb884f71270e74d99304158/tensorflow/tools/dockerfiles/dockerfiles/devel-gpu-jupyter.Dockerfile

# ARGs for FROM
ARG UBUNTU_VERSION=18.04
ARG ARCH=
ARG CUDA=11.0

FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION}
MAINTAINER Guillem Pascual <gpascualg93@gmail.com>

# ARGs for build
ARG ARCH
ARG CUDA
ARG CUDNN=8.0.4.30-1
ARG CUDNN_MAJOR_VERSION=8
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=7.1.3-1
ARG LIBNVINFER_MAJOR_VERSION=7
ARG DEV=0

# String substitution
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Bootstrap apt and find closest mirror
RUN sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic main restricted universe multiverse' /etc/apt/sources.list && \
	sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-updates main restricted universe multiverse' /etc/apt/sources.list && \
	sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-backports main restricted universe multiverse' /etc/apt/sources.list && \
	sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-security main restricted universe multivers' /etc/apt/sources.list

ADD ./docker-data/get_version.sh /opt/get_version.sh
RUN apt update && \
	apt install -y --no-install-recommends \
		ca-certificates \
		build-essential \
		checkinstall \
		cuda-command-line-tools-${CUDA/./-} \
	        libcublas-${CUDA/./-} \
		cuda-nvrtc-${CUDA/./-} \
		libcufft-${CUDA/./-} \
		libcurand-${CUDA/./-} \
		libcusolver-${CUDA/./-} \
		libcusparse-${CUDA/./-} \
		libcudnn8=${CUDNN}+cuda${CUDA} \
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
			libcudnn8-dev=${CUDNN}+cuda${CUDA} \
	) || test ${DEV} -eq 0 \
)

# Install TensorRT if not building for PowerPC
RUN [[ "${ARCH}" = "ppc64le" ]] || { apt-get update && \
        apt-get install -y --no-install-recommends libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*; }

# NodeJS
ARG NODEJS_VERSION=15.11.0
RUN wget -O /opt/node.tar.xz https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.xz && \
	cd /opt && \
	tar xf node.tar.xz
ENV PATH=/opt/node-v${NODEJS_VERSION}-linux-x64/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/node-v${NODEJS_VERSION}-linux-x64/lib:$LD_LIBRARY_PATH

# Install miniconda
RUN wget -O /opt/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
	cd /opt && \
	chmod +x miniconda.sh && \
	./miniconda.sh -b -p /opt/miniconda

# Export path
ENV PATH=/root/bin:/root/.local/bin:/opt/node-v${NODEJS_VERSION}-linux-x64/bin:/usr/local/bin:/opt/miniconda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/lib64:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV LANG C.UTF-8

# Install tensorflow environment
#RUN conda create -n tf-gpu tensorflow-gpu
#SHELL ["conda", "run", "-n", "tf-gpu", "/bin/bash", "-c"]
#RUN conda-env config vars set PATH=/opt/node-v${NODEJS_VERSION}-linux-x64/bin:$PATH

# Temporarily install latest via pip
RUN pip install \
	absl-py==0.11.0 \
	tensorflow==2.4.1 \
	tensorflow-addons==0.12.1 \
	tensorflow-datasets==4.1.0 \
	tensorflow-probability==0.12.1 \
	tensorboard==2.4.1 \
	tensorboard-plugin-wit==1.8.0 \
	tensorboard-plugin-netron==0.2.0 \
	keras-preprocessing==1.1.2

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
RUN test "${ENABLE_SSH}" -eq 1 && \
( \
	apt update && \
	apt install -y openssh-server && \
	mkdir /var/run/sshd && \
	mkdir -p  ~/.ssh && \
	chmod 700 ~/.ssh && \
	touch /root/.ssh/authorized_keys && \
	chmod 600 /root/.ssh/authorized_keys \
) || test "${ENABLE_SSH}" -eq 0


# Conda/pip packages
RUN conda install \
		pillow=8.1.1 \
		h5py=3.1.0 \
		mock=4.0.3 \
		scipy=1.6.0 \
		scikit-learn=0.24.1 \
		scikit-image=0.18.1 \
		future=0.18.2 \
		portpicker=1.3.1 \
		tqdm=4.58.0 \
		seaborn=0.11.1 \
		selenium=3.141.0 \
		pandas=1.2.3 \
		xlrd=2.0.1 \
		numpy=1.20.1 \
		networkx=2.5 \
		imageio=2.9.0 \
		opencv=4.5.1 \
		pyyaml=5.4.1 \
		semantic_version=2.8.5 \
		matplotlib=3.3.4 \
		jupyterlab=3.0.9 \
		jupyterlab-lsp=3.4.1 \
		ipywidgets=7.6.3 \
		pylint=2.7.2 \
		xeus-python=0.11.2 \
		ptvsd=4.3.2 \
		cookiecutter==1.7.2 \
		-c conda-forge -y && \
	pip install --upgrade \
		pyqtree==1.0.0 \
		jupyter-starters==1.0.1a0 \
		git+https://github.com/gpascualg/SenseTheFlow.git@tf-2.0

# I like nbreuse + topbar but it is way to laggy
# nbresuse==0.3.6 \

# Pre "jupyter lab build" packages
RUN pip install \
	jupyterlab-git==0.23.3 \
	git+https://github.com/krassowski/python-language-server.git@main

# Jupyter extensions, make sure the first node to be found is the newest one
#RUN jupyter nbextension enable --py widgetsnbextension && \
#	jupyter labextension install --no-build @jupyter-widgets/jupyterlab-manager@2.0 && \
#	jupyter labextension install --no-build @jupyterlab/debugger && \
#	jupyter labextension install --no-build @krassowski/jupyterlab-lsp && \
#	jupyter lab build

# Other extensions that make jupyterlab too laggy
	#jupyter labextension install --no-build @mohirio/jupyterlab-horizon-theme && \
	#jupyter labextension install --no-build jupyterlab-topbar-extension jupyterlab-system-monitor && \
	#jupyter labextension install --no-build @aquirdturtle/collapsible_headings && \
	#jupyter labextension install --no-build @deathbeds/jupyterlab-starters && \

# Packages needed after labextensions
RUN pip install \
		pycodestyle==2.6.0 \
		autopep8==1.5.5 \
		pydocstyle==5.1.1 \
		pyflakes==2.2.0 \
		rope==0.18.0 \
		yapf==0.30.0 \
		parso==0.7.1

# Hotfix keras h5 errors, tf numpy requirements
RUN pip install --force-reinstall --upgrade \
	h5py==2.10.0 \
	numpy==1.19.2

# jupyterlab-lsp configuration, but disable it until it supports JLAB 2.2
ADD ./docker-data/pycodestyle /root/.config/pycodestyle
#RUN jupyter labextension disable @krassowski/jupyterlab-lsp

# Copy templates for jupyterlab-starters, if any
ADD ./docker-data/templates/* /templates/*

# Configuration if any
ADD ./docker-data/jupyter_notebook_config.json /root/.jupyter/jupyter_notebook_config.json

# Go back to the usual shell for this part
SHELL ["/bin/bash", "-c"]
RUN echo -e "#!/bin/bash\n\
echo 'Allow more inotify watches'\n\
sysctl fs.inotify.max_user_watches=524288\n\
echo 'Generating config'\n\
jupyter-notebook -y --allow-root --generate-config --config=/etc/jupyter_notebook_config.py\n\
echo 'Settings config'\n\
echo \"c.NotebookApp.open_browser = False\" >> /etc/jupyter_notebook_config.py\n\
echo \"c.IPKernelApp.matplotlib ='inline'\" >> /etc/jupyter_notebook_config.py\n\
echo \"c.ServerApp.ip = '0.0.0.0'\" >> /etc/jupyter_notebook_config.py\n\
echo \"c.ServerApp.port = 8888\" >> /etc/jupyter_notebook_config.py\n\
echo \"c.ServerApp.open_browser = False\" >> /etc/jupyter_notebook_config.py\n\
echo \"c.ServerApp.password = '\$JUPYTER_PASSWORD'\" >> /etc/jupyter_notebook_config.py\n\
echo \"c.ServerApp.token = ''\" >> /etc/jupyter_notebook_config.py\n\
echo \"c.Completer.use_jedi = False\" >> /etc/jupyter_notebook_config.py\n\
if [ \"\${ENABLE_JUPYTER_BASE_DIR}\" = \"1\" ]\n\
then\n\
	sed -i \ \n\
		-e \"s/^# *c.NotebookApp.base_url = '\/'$/c.NotebookApp.base_url = '\/\$USERNAME\/jupyter\/'/\" \ \n\
		/etc/jupyter_notebook_config.py \n\
fi\n\
# Fetch global libraries from GIT \n\
cd /opt/python-libs/\n\
echo \"Checking Github\"\n\
eval \"GITHUB_URLS=\$GITHUB_URLS\"\n\
for url in \"\${GITHUB_URLS[@]}\"\n\
do\n\
    echo Cloning \$url\n\
    git clone \$url\n\
done\n\
cd /\n\
# Fetch extra pip libraies\n\
echo \"Checking Pip\"\n\
eval \"PIP_LIBRARIES=\$PIP_LIBRARIES\"\n\
for lib in \"\${PIP_LIBRARIES[@]}\"\n\
do\n\
    echo Installing pip \$lib\n\
    pip install -y \$lib\n\
done\n\
echo \"Checking Conda\"\n\
eval \"CONDA_LIBRARIES=\$CONDA_LIBRARIES\"\n\
for lib in \"\${CONDA_LIBRARIES[@]}\"\n\
do\n\
    echo Installing conda \$lib\n\
    conda install -y \$lib -c conda-forge\n\
done\n\
# SSH \n\
test \"${ENABLE_SSH}\" -eq 1 && /usr/sbin/sshd || true\n\
# Start \n\
echo \"Starting Jupyter\"\n\
PATH=/opt/node-v10.16.3-linux-x64/bin:$PATH jupyter-lab /notebooks --allow-root --config=/etc/jupyter_notebook_config.py 2>&1 | tee /tmp/jupyter.log" > /opt/run_docker.sh.tpl && \
	sed 's/ *$//' /opt/run_docker.sh.tpl > /opt/run_docker.sh && \
	chmod +x /opt/run_docker.sh

# Last-time additions
# CV2 dependencies
RUN apt-get update && \
	apt-get install ffmpeg libsm6 libxext6  -y

# Custom python folder
RUN mkdir /opt/python-libs
ENV PYTHONPATH=/opt/python-libs:$PYTHONPATH

# Trigger updates without recompiling everything
RUN pip3 install --upgrade git+https://github.com/gpascualg/SenseTheFlow.git@tf-2.0

###############
# Run from within the environment
ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["/opt/run_docker.sh"]
