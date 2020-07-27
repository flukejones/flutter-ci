FROM fedora:31

# https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_1.17.0-stable.tar.xz
ENV FLUTTER_CHANNEL=dev
ENV FLUTTER_VERSION=1.21.0-1.0.pre-${FLUTTER_CHANNEL}

RUN dnf update -y \
    && dnf install -y wget git \
                      xz tar unzip which \
                      make autoconf automake  \
                      redhat-rpm-config \
                      lcov \
                      gcc gcc-c++ libstdc++.i686 \
    && dnf clean all

# Set up the default user
RUN useradd work -u 1000 --user-group --create-home --shell /bin/bash

# install fixuid to help prevent ownership issues
RUN USER=work && \
    GROUP=work && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml
ENTRYPOINT ["fixuid"]

# Run all further commands as user: work
USER work:work
RUN mkdir -p /home/work/src

RUN cd ~ \
    && wget --quiet --output-document=flutter.tar.xz https://storage.googleapis.com/flutter_infra/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}.tar.xz \
    && tar xf flutter.tar.xz -C ~/ \
    && rm flutter.tar.xz

ENV PATH=$PATH:/home/work/flutter/bin

RUN flutter channel $FLUTTER_CHANNEL
RUN flutter upgrade && flutter precache
WORKDIR /home/work/src
