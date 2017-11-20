FROM nvidia/cuda:8.0-cudnn6-runtime

RUN apt-get update && \
    apt-get install -y locales

# Locale settings
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen; locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/librexgen/

RUN apt-get install -y build-essential yasm git libpcap0.8 libpcap-dev pkg-config libbz2-1.0 libbz2-dev libssl1.0.0 libssl-dev libgmp10 libgmp-dev libkrb5-3 libkrb5-dev libnss3 libnss3-dev libopenmpi1.10 libopenmpi-dev openmpi-bin cmake bison flex libicu55 libicu-dev nvidia-opencl-dev && \
   mkdir -p ~/src && \
   cd ~/src && \
  git clone --recursive https://github.com/teeshop/rexgen.git && \
  cd rexgen && \
  sed -i -e 's/sudo //g' install.sh && \
  ./install.sh && \
  mv ~/src/rexgen/build/librexgen /usr/lib && \
  cd ~/src && \
  git clone git://github.com/magnumripper/JohnTheRipper -b bleeding-jumbo john && \
  cd john/src && \
  ./configure --enable-mpi && \
  make -s clean && \
  make -sj8 && \
  mkdir /usr/share/johntheripper && \
  mv /root/src/john/run/* /usr/share/johntheripper/ && \
  rm -rf /root/src && \
  adduser --home /home/ripper --disabled-password --gecos "" ripper

ENV PATH=$PATH:/usr/share/johntheripper

USER ripper

ENTRYPOINT ["/root/src/john/run/john"]
