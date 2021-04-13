FROM ubuntu:18.04
  
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

RUN apt-get update && \
    apt-get install --yes \
    build-essential \
    cmake \
    git \
    libssl-dev \
    tcl \
    tcl-tclreadline \
    vim-nox \
    wget \
    zlib1g-dev

RUN git clone https://github.com/giltene/wrk2.git && cd wrk2 && make

ENTRYPOINT ["wrk2/wrk"]
