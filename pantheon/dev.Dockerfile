FROM ubuntu:18.04

# install ydk build dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    wget \
    vim \
    gdebi-core \
    python-dev \
    python-pip \
    libtool-bin \
    libcurl4-openssl-dev \
    libpcre3-dev \
    libssh-dev \
    libxml2-dev \
    libxslt1-dev \
    cmake \
    g++ \
    gcc \
    ca-certificates \
    iproute2 \
    net-tools \
    git \
    unzip \
    curl \
 && rm -rf /var/lib/apt/lists/*

# build dependencies for gNMI
WORKDIR /opt
# v3.5.0 -> November 2017 - consider upgrading, requires changes in the gNMI plugin code
ARG PROTOBUF_VERSION=3.5.0
RUN wget https://github.com/google/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-cpp-${PROTOBUF_VERSION}.zip &&\
    unzip protobuf-cpp-${PROTOBUF_VERSION}.zip &&\
    cd protobuf-${PROTOBUF_VERSION} &&\
    ./configure &&\
    make &&\
    make install &&\
    ldconfig

# v1.9.1 -> February 2018 - consider upgrading, requires changes in the gNMI plugin code
ARG GRPC_VERSION=1.9.1 
RUN git clone -b v${GRPC_VERSION} https://github.com/grpc/grpc &&\
    cd grpc &&\
    git submodule update --init &&\
    make &&\
    make install &&\
    ldconfig

# copy local version of ydk-gen
COPY . "ydk-gen"
WORKDIR /opt/ydk-gen

# build YDK core library
RUN cd sdk/cpp/core &&\
    mkdir build &&\
    cd build &&\
    cmake .. &&\
    make &&\
    make install

# build gNMI package
RUN cd sdk/cpp/gnmi &&\
    mkdir build &&\
    cd build &&\
    cmake .. &&\
    make &&\
    make install

# install Python dependencies for the "generate.py" script
RUN pip install setuptools &&\
    pip install wheel &&\
    pip install -r requirements.txt

# check if generate works 
RUN ./generate.py --core --go --generate-doc &&\
    ./generate.py --service profiles/services/gnmi-0.4.0.json --go &&\
    ./generate.py --bundle profiles/bundles/ietf_0_1_5_post2.json --go &&\
    rm -rf ./gen-api

# install Go
ARG GO_VERSION=1.13.1
RUN set -eux; \
	dpkgArch="$(dpkg --print-architecture)"; \
		case "${dpkgArch##*-}" in \
			amd64) goRelArch='linux-amd64'; ;; \
			armhf) goRelArch='linux-armv6l'; ;; \
			arm64) goRelArch='linux-arm64'; ;; \
	esac; \
 	wget -nv -O go.tgz "https://golang.org/dl/go${GO_VERSION}.${goRelArch}.tar.gz"; \
 	tar -C /usr/local -xzf go.tgz; \
 	rm go.tgz;

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# workaround for https://github.com/CiscoDevNet/ydk-gen/issues/781
ENV CGO_ENABLED 1
ENV CGO_LDFLAGS_ALLOW "-fprofile-arcs|-ftest-coverage|--coverage"

CMD ["/bin/bash"]
