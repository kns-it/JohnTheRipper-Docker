FROM nvidia/cuda:8.0-runtime as build

RUN apt-get update && \
    apt-get install -y locales

# Locale settings
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen; locale-gen
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/librexgen/

RUN apt-get install -y build-essential yasm git libpcap0.8 libpcap-dev pkg-config libbz2-1.0 libbz2-dev libssl1.0.0 libssl-dev libgmp10 libgmp-dev libkrb5-3 libkrb5-dev libnss3 libnss3-dev libopenmpi1.10 libopenmpi-dev openmpi-bin cmake bison flex libicu55 libicu-dev nvidia-cuda-toolkit && \
   mkdir -p ~/src && \
   cd ~/src && \
   git clone --recursive https://github.com/teeshop/rexgen.git && \
   cd rexgen && \
   ./build.sh && \
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

# Locale settings
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen; locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV PATH=$PATH:/usr/share/johntheripper
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/librexgen/
ENV JOHN=/usr/share/johntheripper

RUN apt-get install -y libpcap0.8 libbz2-1.0 libssl1.0.0 libgmp10 libkrb5-3 libnss3 libopenmpi1.10 openmpi-bin bison flex libicu55 && \
   adduser --home /home/ripper --disabled-password --gecos "" ripper  && \
   ldconfig && \
   cp /usr/share/johntheripper/john.bash_completion /etc/bash_completion.d/ && \
   apt-get clean && \
   rm -rf /var/cache/apt/*

USER ripper

ENTRYPOINT ["john"]
