FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
MAINTAINER Guillem Pascual <gpascualg93@gmail.com>

# Update + dependencies #
#########################

RUN apt-get update && \
	apt-get install -y curl bzip2 software-properties-common zip g++ unzip cmake vim \
		libxrender1 libfontconfig1 git \
		libnccl2=2.2.13-1+cuda9.0 libnccl-dev=2.2.13-1+cuda9.0 \
		swig pkg-config openjdk-8-jdk-headless autoconf locate build-essential \
		libpng12-dev libfreetype6-dev libzmq3-dev zlib1g-dev

# Get anaconda #
################
RUN curl -OL https://repo.continuum.io/archive/Anaconda3-5.2.0-Linux-x86_64.sh && \
	bash Anaconda3-5.2.0-Linux-x86_64.sh -b -p /opt/anaconda && \
	rm Anaconda3-5.2.0-Linux-x86_64.sh


## Export path
ENV PATH=/opt/anaconda/bin:/root/bin:/usr/local/bin:$PATH \
	LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64/stubs:$LD_LIBRARY_PATH

## Configure anaconda
EXPOSE 8888

# Install other dependencies #
##############################
RUN conda install anaconda python=3.6 pip -y && \
	pip install --upgrade pip && \
	pip install tqdm seaborn selenium keras

# Permanent volumnes #
######################
RUN mkdir /notebooks
VOLUME ["/notebooks"]

RUN mkdir /data
VOLUME ["/data"]


RUN pip install tensorflow-gpu



# Fetch RocksDB #
#################
RUN git clone https://github.com/facebook/rocksdb.git && \
	mkdir rocksdb/build && \
	cd rocksdb/build && \
	git checkout v5.3.6 && \
	cmake .. && \
	make -j $(grep -c '^processor' /proc/cpuinfo) && \
	make install && \
	cd ../.. && \
	rm -rf rocksdb



# Setup PYTHONPATH #
####################
ENV PYTHONPATH=/notebooks:/opt/python-libs


# Configure jupyter at startup
ENV LD_LIBRARY_PATH=/usr/lib64:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
RUN echo "#!/bin/bash\n\
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
        -e \"s/^# *c.IPKernelApp.extensions = \[\]$/c.IPKernelApp.extensions = ['version_information']/\" \ \n\
        /etc/jupyter-notebook.py \n\
# Hackity hack to make anaconda behave \n\
rm /opt/anaconda/lib/libstdc++.so.6 \n\
ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/anaconda/lib/libstdc++.so.6 \n\
if [ -n \"\$ENABLE_GOMP_HACK\" ] \n\
then \n\
    rm /opt/anaconda/lib/libgomp.so.1 \n\
    ln -s $(find /usr/lib -name libgomp.so.1) /opt/anaconda/lib/libgomp.so.1 \n\
fi \n\
# Fetch latest SenseTheFlow \n\
if [ -n \"\${FETCH_TF_CONTRIB}\" ] \n\
then \n\
    pip install git+https://www.github.com/farizrahman4u/keras-contrib.git \n\
    git clone https://github.com/gpascualg/SenseTheFlow.git /opt/python-libs/SenseTheFlow \n\
fi \n\
# SSH \n\
/usr/sbin/sshd \n\
# Start \n\
jupyter-notebook /notebooks --allow-root --config=/etc/jupyter-notebook.py &>/dev/null" > /opt/anaconda/run_jupyter.sh.tpl
RUN sed 's/ *$//' /opt/anaconda/run_jupyter.sh.tpl > /opt/anaconda/run_jupyter.sh
RUN chmod +x /opt/anaconda/run_jupyter.sh

# SSH #
#######

RUN apt-get update && \
	apt-get install -y openssh-server && \
	mkdir /var/run/sshd && \
	mkdir -p  ~/.ssh && \
	chmod 700 ~/.ssh && \
	touch /root/.ssh/authorized_keys && \
	chmod 600 /root/.ssh/authorized_keys

EXPOSE 22

ENV NODE_OPTIONS=--max-old-space-size=4096

# Jupyter lab
RUN conda install -y jupyterlab=0.31.12 nodejs && \
	echo "\n.p-Widget.jp-OutputPrompt.jp-OutputArea-prompt:empty {\n\
		padding: 0;\n\
		border: 0;\n\
	}" >> /opt/anaconda/lib/python3.6/site-packages/jupyterlab/themes/\@jupyterlab/theme-light-extension/index.css && \
	jupyter lab build && \
	jupyter serverextension enable --py jupyterlab --sys-prefix && \
	jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.34 && \
	conda update -y -c conda-forge ipywidgets

# Do not directly kill processes for god's sake!
RUN sed -i -e "s/content = dict(restart=restart)/content = dict(restart=restart)\n        self.signal_kernel(signal.SIGTERM)/" /opt/anaconda/lib/python3.6/site-packages/jupyter_client/manager.py

# Jupyter lab coranos

# Entry point #
###############
# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]
CMD ["/opt/anaconda/run_jupyter.sh"]
