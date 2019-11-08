FROM docker.pantheon.tech/ydk-dev as dev
FROM ubuntu:18.04 as base

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
    libxml2 \
    libcurl4-openssl-dev  \
    libssh-dev \
    libxslt1.1 \
    ca-certificates \
    iproute2 \
 && rm -rf /var/lib/apt/lists/*

# install micro runtime
RUN curl -fsSL https://micro.mu/install.sh | /bin/bash

# copy extra libyang libraries (the core is statically linked)
COPY --from=dev /usr/local/lib/libyang /usr/local/lib/libyang

FROM scratch
COPY --from=base / /

CMD /bin/bash

