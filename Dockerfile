# Start with cuDNN base image
FROM nvidia/cuda:7.0-cudnn4-devel
# Copy from MAINTAINER Kai Arulkumaran <design@kaixhin.com>

MAINTAINER joe <zy3381@gmail.com>

# Install git and other dependencies
RUN apt-get update && apt-get install -y \
  git \
  libopenblas-dev \
  libopencv-dev \
  python-dev \
  python-numpy \
  python-setuptools \
  
#######################
# Install jupyter
RUN apt-get update && apt-get install -y python-pip
RUN pip install --upgrade pip
RUN pip install ipython jupyter

# Install matplotlib
RUN pip install matplotlib
RUN pip install Pillow
RUN pip install scipy
RUN pip install -U scikit-image

RUN pip install graphviz
RUN apt-get install -y graphviz

EXPOSE 9999 
EXPOSE 8888 
EXPOSE 7777 
EXPOSE 6666
EXPOSE 5555

WORKDIR /root/workspace
VOLUME ["/root/workspace"]

ENV TINI_VERSION v0.8.4 
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini 
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888","--no-browser"]
#######################

# Clone MXNet repo and move into it
RUN cd /root && git clone --recursive https://github.com/dmlc/mxnet && cd mxnet && \
# Copy config.mk
  cp make/config.mk config.mk && \
# Set OpenBLAS
  sed -i 's/USE_BLAS = atlas/USE_BLAS = openblas/g' config.mk && \
# Set CUDA flag
  sed -i 's/USE_CUDA = 0/USE_CUDA = 1/g' config.mk && \
  sed -i 's/USE_CUDA_PATH = NONE/USE_CUDA_PATH = \/usr\/local\/cuda/g' config.mk && \
# Set cuDNN flag
  sed -i 's/USE_CUDNN = 0/USE_CUDNN = 1/g' config.mk && \
# Make 
  make -j"$(nproc)"

# Install Python package
RUN cd /root/mxnet/python && python setup.py install

# Add R to apt sources
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list
# Install latest version of R
RUN apt-get update && apt-get install -y --force-yes r-base

# Install R package
# TODO