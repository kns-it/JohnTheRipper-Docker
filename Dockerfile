FROM nvidia/cuda:8.0-runtime as build

RUN apt-get update && \
    apt-get install -y locales

# Locale settings
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen; locale-gen
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/librexgen/

RUN apt-get install -y build-essential \
    yasm \
    git \
    libpcap0.8 libpcap-dev \
    pkg-config \
    libbz2-1.0 libbz2-dev \
    libssl1.0.0 libssl-dev \
    libgmp10 libgmp-dev \
    libkrb5-3 libkrb5-dev \
    libnss3 libnss3-dev \
    libopenmpi1.10 libopenmpi-dev openmpi-bin \
    cmake \
    bison \
    flex \
    libicu55 libicu-dev

RUN apt-get install -y ocl-icd-libopencl1 \
    nvidia-opencl-dev && \
    mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd

RUN mkdir -p ~/src && \
    cd ~/src && \
    git clone --recursive https://github.com/teeshop/rexgen.git && \
    cd rexgen && \
    sed -i -e 's/sudo//g' install.sh && \
    ./build.sh && \
    ./install.sh && \
    ldconfig && \
    cd ~/src && \
    git clone git://github.com/magnumripper/JohnTheRipper -b bleeding-jumbo john && \
    cd john/src && \
    ./configure --enable-mpi && \
    make -s clean && \
    make -sj8

FROM nvidia/cuda:8.0-runtime

RUN apt-get update && \
    apt-get install -y locales

COPY --from=build /root/src/rexgen/build/librexgen /usr/local/lib/
COPY --from=build /root/src/rexgen/build/rexgen/rexgen /usr/bin/
COPY --from=build /root/src/john/run /usr/share/johntheripper
COPY --from=build /root/src/john/src/opencl/* /usr/share/johntheripper/kernels/

# Locale settings
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen; locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV PATH=$PATH:/usr/share/johntheripper
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/librexgen/:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV JOHN=/usr/share/johntheripper

ADD setup.sh /usr/bin/

RUN apt-get install -y libpcap0.8 \
    libbz2-1.0 \
    libssl1.0.0 \
    libgmp10 \
    libkrb5-3 \
    libnss3 \
    libopenmpi1.10 openmpi-bin \
    bison \
    flex \
    libicu55 \
    ocl-icd-libopencl1 && \
    mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd && \
    adduser --home /home/ripper --disabled-password --gecos "" ripper  && \
    cp /usr/share/johntheripper/john.bash_completion /etc/bash_completion.d/ && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    chown -R john /usr/share/johntheripper && \
    chmod +x /usr/bin/setup.sh

USER ripper
WORKDIR /home/ripper

ENTRYPOINT ["/bin/bash"]
