# https://github.com/tensorflow/tensorflow/blob/cab804f9712e4a430bb884f71270e74d99304158/tensorflow/tools/dockerfiles/dockerfiles/devel-gpu-jupyter.Dockerfile

# ARGs for FROM
ARG UBUNTU_VERSION=18.04
ARG ARCH=
ARG CUDA=10.0

FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION}
MAINTAINER Guillem Pascual <gpascualg93@gmail.com>

# ARGs for build
ARG ARCH
ARG CUDA
ARG CUDNN=7.6.2.24-1
ARG CUDNN_MAJOR_VERSION=7
ARG LIB_DIR_PREFIX=x86_64

# String substitution
SHELL ["/bin/bash", "-c"]

# Find closest mirror
RUN sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic main restricted universe multiverse' /etc/apt/sources.list && \
        sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-updates main restricted universe multiverse' /etc/apt/sources.list && \
        sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-backports main restricted universe multiverse' /etc/apt/sources.list && \
        sed -i '1i deb mirror://mirrors\.ubuntu\.com/mirrors\.txt bionic-security main restricted universe multivers' /etc/apt/sources.list

# Downloads deps
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
        	build-essential \
		checkinstall \
	        cuda-command-line-tools-${CUDA/./-} \
	        cuda-cublas-dev-${CUDA/./-} \
	        cuda-cudart-dev-${CUDA/./-} \
	        cuda-cufft-dev-${CUDA/./-} \
	        cuda-curand-dev-${CUDA/./-} \
	        cuda-cusolver-dev-${CUDA/./-} \
	        cuda-cusparse-dev-${CUDA/./-} \
	        libcudnn7=${CUDNN}+cuda${CUDA} \
	        libcudnn7-dev=${CUDNN}+cuda${CUDA} \
		libreadline-gplv2-dev \
		libncursesw5-dev \
		libssl-dev \
		libsqlite3-dev \
		libgdbm-dev \
		libc6-dev \
		libbz2-dev \
		libffi-dev \
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
	        git \
        	&& \
	find /usr/local/cuda-${CUDA}/lib64/ -type f -name 'lib*_static.a' -not -name 'libcudart_static.a' -delete && \
	rm /usr/lib/${LIB_DIR_PREFIX}-linux-gnu/libcudnn_static_v7.a

# NodeJS
ARG NODEJS_VERSION=10.16.3
RUN wget -O /opt/node.tar.xz https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.xz && \
	cd /opt && \
	tar xf node.tar.xz

# Build python from source
ARG PYTHON_MAJOR=3
ARG PYTHON_MINOR=7
ARG PYTHON_PATCH=4
ARG _PYTHON_VERSION=${PYTHON_MAJOR}.${PYTHON_MINOR}.${PYTHON_PATCH}

RUN wget -O /opt/python.tgz https://www.python.org/ftp/python/${_PYTHON_VERSION}/Python-${_PYTHON_VERSION}.tgz && \
	cd /opt && \
	tar xfz python.tgz && \
	cd Python-${_PYTHON_VERSION} && \
	./configure --enable-optimizations && \
	make install -j$(grep -c '^processor' /proc/cpuinfo)

ARG PYTHON=python${PYTHON_MAJOR}.${PYTHON_MINOR}
ARG PIP=pip${PYTHON_MAJOR}

## Export path
ENV PATH=/root/bin:/root/.local/bin:/opt/node-v${NODEJS_VERSION}-linux-x64/bin:/usr/local/bin:$PATH \
	LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64/stubs:$LD_LIBRARY_PATH

## Configure anaconda
EXPOSE 8888

# Fixed versions #
##############a################
# Make sure we have latest pip version first
RUN ${PIP} install --user --upgrade pip==19.2.3 wheel==0.33.6 setuptools==41.4.0 virtualenv==16.7.5 && \
	${PIP} install --user --upgrade \
		Pillow==6.2.0 \
		h5py==2.10.0 \
		keras_applications==1.0.8 \
		keras_preprocessing==1.1.0 \
		mock==3.0.5 \
		scipy==1.3.1 \
		scikit-learn==0.21.3 \
		future==0.17.1 \
		portpicker==1.3.1 \
		tqdm==4.36.1 \
		seaborn==0.9.0 \
		selenium==3.141.0 \
		pandas==0.25.1 \
		numpy==1.17.2 \
		matplotlib==3.1.1 \
		jupyterlab==1.1.4 \
		ipywidgets==7.5.1 && \
	jupyter nbextension enable --py widgetsnbextension && \
	jupyter labextension install @jupyter-widgets/jupyterlab-manager@1.0.2

# Default python is 3.7.4
RUN update-alternatives --install /usr/bin/python python $(which ${PYTHON}) 1

# Permanent volumnes #
######################
RUN mkdir /notebooks
VOLUME ["/notebooks"]

RUN mkdir /data
VOLUME ["/data"]

ARG CUDA_COMPUTE_CAPABILITIES=3.5,5.2,6.0,6.1,7.0
ARG TENSORFLOW=2.0.0
ARG TENSORFLOW_GENERIC=0
ARG BAZEL_VERSION=0.24.1
ARG NUM_JOBS=32

# Bazel build
ENV TF_NEED_MKL=1 \
        TF_DOWNLOAD_MKL=1 \
        TF_NEED_CUDA=1 \
        TF_NEED_OPENCL=0 \
        TF_NEED_JEMALLOC=1 \
        TF_NEED_AWS=0 \
        TF_NEED_KAFKA=0 \
        TF_NEED_OPENCL_SYCL=0 \
        TF_NEED_COMPUTECPP=0 \
        TF_NEED_TENSORRT=0 \
        TF_NEED_VERBS=0 \
        TF_NEED_HDFS=0 \
        TF_NEED_GDR=0 \
        TF_NEED_MPI=0 \
        TF_NEED_NCCL=1 \
        TF_ENABLE_XLA=1 \
        TF_CUDA_CLANG=0 \
        TF_NEED_GCP=0 \
        TF_CUDA_VERSION=${CUDA} \
        TF_CUDNN_VERSION=${CUDNN_MAJOR_VERSION} \
        TF_CUDA_COMPUTE_CAPABILITIES=${CUDA_COMPUTE_CAPABILITIES}

RUN test "${TENSORFLOW_GENERIC}" -eq 1 && ${PIP} install tensorflow-gpu==${TENSORFLOW_VERSION} || true
RUN test "${TENSORFLOW_GENERIC}" -eq 0 && \
	# Get Bazel # \
	############# \
	# 0.5.4 was working \
( \
	wget -O /tmp/bazel-installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
	wget -O /tmp/LICENSE.txt "https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE" && \
	chmod +x /tmp/bazel-installer.sh && \
	/tmp/bazel-installer.sh && \
	rm -rf /tmp/bazel-installer.sh && \
	git clone --branch="r${TENSORFLOW/%.[0-9]/}" --depth=1 https://github.com/tensorflow/tensorflow /opt/tensorflow && \
	cd /opt/tensorflow && \
	chmod +x configure && \
	./configure && \
	bazel build --config=opt --config=cuda --verbose_failures //tensorflow/tools/pip_package:build_pip_package --jobs=${NUM_JOBS} && \
	./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
	${PIP} install /tmp/tensorflow_pkg/$(ls /tmp/tensorflow_pkg) \
) || test "${TENSORFLOW_GENERIC}" -eq 1

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

# Configure jupyter at startup
ARG ENABLE_SSH=1
ENV ENABLE_SSH=${ENABLE_SSH}
RUN test ${ENABLE_SSH} -eq 1 && \
( \
	apt-get update && \
	apt-get install -y openssh-server && \
	mkdir /var/run/sshd && \
	mkdir -p  ~/.ssh && \
	chmod 700 ~/.ssh && \
	touch /root/.ssh/authorized_keys && \
	chmod 600 /root/.ssh/authorized_keys \
) || test "${ENABLE_SSH}" -eq 0

# Theia editor
ARG ENABLE_THEIA=1
RUN test "${ENABLE_THEIA}" -eq 1 && \
( \
	# Npm/gyp/theia uses 2.7, fix current installation and allow 2.7
	update-alternatives --install /usr/bin/pip pip $(which ${PIP}) 1 && \
	apt-get install -y --no-install-recommends python python-pip && \
	${PYTHON} -m pip install -U --force-reinstall pip==19.2.3 setuptools==41.4.0 && \
	python2.7 -m pip install -U --force-reinstall pip==19.2.3 setuptools==41.4.0 && \
	npm config set python /usr/bin/python2.7 && \
	# public LLVM PPA, development version of LLVM
	wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
	echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main" > /etc/apt/sources.list.d/llvm.list && \
	apt-get update && apt-get install -y clang-tools-10 clangd-10 clang-tidy-10 && \
	ln -s /usr/bin/clangd-10 /usr/bin/clangd && \
	ln -s /usr/bin/clang-tidy-10 /usr/bin/clang-tidy && \
	# Python autocompletion
	${PIP} install --user --upgrade python-language-server==0.28.3 && \ 
	pip2 install --user --upgrade python-language-server==0.28.3 && \
	# Theia itself	
	npm install -g yarn && \
	mkdir /opt/theia && \
	cd /opt/theia && \
	echo -e "{\n\
    \"private\": true,\n\
    \"name\": \"@deepstack/editor\",\n\
    \"version\": \"0.0.1\",\n\
    \"license\": \"Apache-2.0\",\n\
    \"theia\": {\n\
      \"frontend\": {\n\
        \"config\": {\n\
          \"applicationName\": \"Deepstack Editor\",\n\
          \"preferences\": {\n\
            \"files.enableTrash\": false\n\
          }\n\
        }\n\
      }\n\
    },\n\
    \"dependencies\": {\n\
        \"@theia/callhierarchy\": \"next\",\n\
        \"@theia/console\": \"next\",\n\
        \"@theia/core\": \"next\",\n\
        \"@theia/cpp\": \"next\",\n\
        \"@theia/debug\": \"next\",\n\
        \"@theia/debug-nodejs\": \"next\",\n\
        \"@theia/editor\": \"next\",\n\
        \"@theia/editorconfig\": \"next\",\n\
        \"@theia/editor-preview\": \"next\",\n\
        \"@theia/file-search\": \"next\",\n\
        \"@theia/filesystem\": \"next\",\n\
        \"@theia/getting-started\": \"next\",\n\
        \"@theia/git\": \"next\",\n\
        \"@theia/json\": \"next\",\n\
        \"@theia/keymaps\": \"next\",\n\
        \"@theia/languages\": \"next\",\n\
        \"@theia/markers\": \"next\",\n\
        \"@theia/merge-conflicts\": \"next\",\n\
        \"@theia/messages\": \"next\",\n\
        \"@theia/metrics\": \"next\",\n\
        \"@theia/mini-browser\": \"next\",\n\
        \"@theia/monaco\": \"next\",\n\
        \"@theia/navigator\": \"next\",\n\
        \"@theia/outline-view\": \"next\",\n\
        \"@theia/output\": \"next\",\n\
        \"@theia/plantuml\": \"next\",\n\
        \"@theia/plugin\": \"next\",\n\
        \"@theia/plugin-ext\": \"next\",\n\
        \"@theia/plugin-ext-vscode\": \"next\",\n\
        \"@theia/preferences\": \"next\",\n\
        \"@theia/preview\": \"next\",\n\
        \"@theia/process\": \"next\",\n\
        \"@theia/python\": \"next\",\n\
        \"@theia/search-in-workspace\": \"next\",\n\
        \"@theia/scm\": \"next\",\n\
        \"@theia/task\": \"next\",\n\
        \"@theia/terminal\": \"next\",\n\
        \"@theia/textmate-grammars\": \"next\",\n\
        \"@theia/tslint\": \"next\",\n\
        \"@theia/typehierarchy\": \"next\",\n\
        \"@theia/typescript\": \"next\",\n\
        \"@theia/userstorage\": \"next\",\n\
        \"@theia/variable-resolver\": \"next\",\n\
        \"@theia/workspace\": \"next\",\n\
        \"typescript\": \"latest\"\n\
    },\n\
    \"devDependencies\": {\n\
        \"@theia/cli\": \"next\"\n\
    }\n\
}" > package.json.tpl && \
	sed 's/ *$//' package.json.tpl > package.json && \
	cat package.json && \
	yarn && \
	yarn theia build \
) || test "${ENABLE_THEIA}" -eq 0
		

# Entry point #RG FETCH_TF_CONTRIB=1
ENV FETCH_TF_CONTRIB=${FETCH_TF_CONTRIB}
ENV LD_LIBRARY_PATH=/usr/lib64:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

RUN echo -e "#!/bin/bash\n\
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
        -e \"s/^# *c.NotebookApp.base_url = '\/'$/c.NotebookApp.base_url = '\/\$USERNAME\/jupyter\/'/\" \ \n\
        /etc/jupyter-notebook.py \n\
# Fetch latest SenseTheFlow \n\
if [ -n \"\${FETCH_TF_CONTRIB}\" ] \n\
then \n\
    ${PIP} install git+https://www.github.com/farizrahman4u/keras-contrib.git \n\
    git clone -b tf-2.0 https://github.com/gpascualg/SenseTheFlow.git /opt/python-libs/SenseTheFlow \n\
fi \n\
# SSH \n\
test "${ENABLE_SSH}" -eq 1 && /usr/sbin/sshd || true\n\
test "${ENABLE_THEIA}" -eq 1 && (\n\
	cd /opt/theia && \n\
	nohup yarn theia start /notebooks --hostname 0.0.0.0 --port 8080 & \n\
) || true\n\
# Start \n\
jupyter-lab /notebooks --allow-root --config=/etc/jupyter-notebook.py &>/dev/null" > /opt/run_docker.sh.tpl && \
	sed 's/ *$//' /opt/run_docker.sh.tpl > /opt/run_docker.sh && \
	chmod +x /opt/run_docker.sh

# Make sure we have python-libs in path
ENV PYTHONPATH=/opt/python-libs:$PYTHONPATH
RUN mkdir /opt/python-libs

###############
# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]
CMD ["/opt/run_docker.sh"]
