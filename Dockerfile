# Taking as base image a Ubuntu Desktop container with web-based noVNC connection enabled
FROM dorowu/ubuntu-desktop-lxde-vnc:release-v1.2
MAINTAINER Miguel O. Bernabeu (miguel.bernabeu@ed.ac.uk)

##
# Dependencies
##
# CppUnit fails to compile if downloaded by HemeLB's CMake, install it system-wide
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    libcppunit-dev \
    libcgal-dev \
    python-wxtools \
    python-wxversion \
    swig \
    openmpi-bin \
    libopenmpi-dev \
    freeglut3-dev \
 && rm -rf /var/lib/apt/lists/*
RUN pip install --upgrade pip
RUN pip install cython numpy PyYAML joblib

##
# Download and install VMTK
##
WORKDIR /tmp
RUN git clone https://github.com/vmtk/vmtk.git
RUN mkdir vmtk-build && \
    cd vmtk-build && \
    cmake ../vmtk && \
    make
# The following two ENV statements are NOT concatenated as the setting of VMTKHOME isn't visible until the end of the command.
ENV VMTKHOME=/tmp/vmtk-build/Install
ENV PATH=$VMTKHOME/bin:$PATH \
    LD_LIBRARY_PATH=$VMTKHOME/lib:$LD_LIBRARY_PATH \
    PYTHONPATH=$VMTKHOME/lib/python2.7/site-packages:$PYTHONPATH

##
# Download and install HemeLB
##
WORKDIR /tmp
RUN git clone https://github.com/mobernabeu/hemelb.git
RUN mkdir hemelb/dependencies/build && \
    cd hemelb/dependencies/build && \
    cmake .. && \
    make && \
    cd ../../Code && \
    mkdir build && \
    cd build && \
    cmake -DHEMELB_STEERING_LIB:string=none -DHEMELB_KERNEL:string=NNCYMOUSE -DHEMELB_USE_SSE3:string=ON -DHEMELB_OPTIMISATION:string="-O3 -DNDEBUG" -DHEMELB_WALL_BOUNDARY:string=BFL -DHEMELB_WALL_INLET_BOUNDARY:string=NASHZEROTHORDERPRESSUREBFL -DHEMELB_WALL_OUTLET_BOUNDARY:string=NASHZEROTHORDERPRESSUREBFL .. && \
    make install

##
# Configure the setup tool
##
# Build the required python components
WORKDIR /tmp
RUN cd hemelb/Tools && \
    python setup.py build_ext --inplace && \
    cd setuptool && \
    python setup.py build_ext --inplace

# Install the setup tool scripts and set environment variables
ENV PYTHONPATH="/tmp/hemelb/Tools:/tmp/hemelb/Tools/setuptool:$PYTHONPATH"
RUN cp /tmp/hemelb/Tools/setuptool/scripts/* /usr/local/bin

# Create a mount point for data
VOLUME /data
