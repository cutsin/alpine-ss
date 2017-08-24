#!/bin/bash

# from: https://github.com/shadowsocks/shadowsocks-libev/blob/master/docker/alpine/Dockerfile

SS_VER="3.0.8"
SS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SS_VER/shadowsocks-libev-$SS_VER.tar.gz

SERVER_ADDR=0.0.0.0
SERVER_PORT=8388
PASSWORD=chobits
METHOD=chacha20
TIMEOUT=300
DNS_ADDR=8.8.8.8
DNS_ADDR_2=8.8.4.4
ARGS=

set -ex && \
  apk add --no-cache --virtual .build-deps \
                              autoconf \
                              build-base \
                              curl \
                              libev-dev \
                              libtool \
                              linux-headers \
                              libsodium-dev \
                              mbedtls-dev \
                              pcre-dev \
                              tar \
                              udns-dev && \
  cd /tmp && \
  curl -sSL $SS_URL | tar xz --strip 1 && \
  ./configure --prefix=/usr --disable-documentation && \
  make install && \
  cd .. && \

  runDeps="$( \
      scanelf --needed --nobanner /usr/bin/ss-* \
          | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
          | xargs -r apk info --installed \
          | sort -u \
  )" && \
  apk add --no-cache --virtual .run-deps $runDeps && \
  apk del .build-deps && \
  rm -rf /tmp/*

ss-server -s $SERVER_ADDR \
            -p $SERVER_PORT \
            -k ${PASSWORD:-$(hostname)} \
            -m $METHOD \
            -t $TIMEOUT \
            --fast-open \
            -d $DNS_ADDR \
            -d $DNS_ADDR_2 \
            -u \
            $ARGS