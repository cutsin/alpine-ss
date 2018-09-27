#!/bin/bash

# Network
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "hostname" > /etc/hostname
hostname -F /etc/hostname
echo -e "nameserver 8.8.8.8\nnameserver 114.114.114.114" > /etc/resolv.conf
echo -e "auto lo\niface lo inet loopback\nauto eth0\niface eth0 inet dhcp" > /etc/network/interfaces
service networking start
sysctl -w net.ipv4.tcp_congestion_control=hybla
sysctl -w net.ipv4.tcp_fastopen=3

# Repositories
echo "http://dl-3.alpinelinux.org/alpine/edge/community\nhttp://dl-3.alpinelinux.org/alpine/edge/main\nhttp://dl-3.alpinelinux.org/alpine/v3.7/community\nhttps://alpine-repo.sourceforge.io/packages" >> /etc/apk/repositories
wget -P /etc/apk/keys https://alpine-repo.sourceforge.io/DDoSolitary@gmail.com-00000000.rsa.pub

# Firewall
apk add iptalbes ca-certificates libressl
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p udp --dport 443 -j ACCEPT

# bbr
echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.conf
sysctl -p

# ss
apk add shadowsocks-libev simple-obfs
