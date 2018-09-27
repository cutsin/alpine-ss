#!/bin/bash

# Network
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "hostname" > /etc/hostname
hostname -F /etc/hostname
echo -e "nameserver 8.8.8.8\nnameserver 114.114.114.114" > /etc/resolv.conf
echo -e "auto lo\niface lo inet loopback\nauto eth0\niface eth0 inet dhcp" > /etc/network/interfaces
service networking start
# Firewall
apk add iptalbes
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p udp --dport 443 -j ACCEPT
# Repositories
echo "http://dl-3.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories

# bbr
echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.conf
sysctl -p

# ss
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
