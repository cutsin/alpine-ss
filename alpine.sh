#!/bin/bash

# Setup from ISO or manually
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
echo -e "http://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/v3.7/community\nhttps://alpine-repo.sourceforge.io/packages" >> /etc/apk/repositories
wget -P /etc/apk/keys https://alpine-repo.sourceforge.io/DDoSolitary@gmail.com-00000000.rsa.pub

apk add ca-certificates libressl

# Manual firewall (if no Firewall provide)
#apk add iptables
#iptables -F
#iptables -A INPUT -p tcp --dport 22 -j ACCEPT
#iptables -A INPUT -p tcp --dport 443 -j ACCEPT
#iptables -A INPUT -p udp --dport 443 -j ACCEPT
#iptables -P INPUT DROP
#iptables -P FORWARD DROP
#iptables -P OUTPUT ACCEPT
#iptables -A INPUT -i lo -j ACCEPT
#iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#service iptables save
#service iptables start

# bbr
echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.conf
sysctl -p

# ss
apk add shadowsocks-libev simple-obfs

# auto launch
rc-update add shadowsocks-server
rc-update add nginx

# install ssl
apk add openssl acme.sh --no-cache
export CF_Email="a@b.com" # Cloudflare login email
export CF_Key="abcadfasde" # Cloudflase api key
echo -e  'export CF_Email="a@b.com"\nexport CF_Key="abcadfasde"' >> /etc/profile
source /etc/profile
acme.sh --issue --dns dns_cf -d your.domain
acme.sh --upgrade --auto-upgrade
acme.sh --installcert -d your.domain --key-file /etc/nginx/ssl/your.domain.key --fullchain-file /etc/nginx/ssl/fullchain.cer --reloadcmd  "rc-service nginx restart"

# v2ray-plugin
cd /tmp && wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.2.0/v2ray-plugin-linux-amd64-v1.2.0.tar.gz
tar -xvzf v2ray-plugin-linux-amd64-v1.2.0.tar.gz -C ./
mv ./v2ray-plugin_linux_amd64 /usr/local/bin/v2ray-plugin

###

# Alpine Trojan

# 1. Domain & cloudfare api
apk add openssl acme.sh --no-cache
export CF_Email="a@b.com" # Cloudflare login email
export CF_Key="abcadfasde" # Cloudflase api key
echo -e  'export CF_Email="a@b.com"\nexport CF_Key="abcadfasde"' >> /etc/profile
source /etc/profile
acme.sh --issue --dns dns_cf -d your.domain
acme.sh --upgrade --auto-upgrade
acme.sh --installcert -d your.domain --key-file /etc/nginx/ssl/your.domain.key --fullchain-file /etc/nginx/ssl/fullchain.cer --reloadcmd  "reboot"

# 2. Build
apk add --no-cache git build-base make cmake boost-dev openssl-dev mariadb-connector-c-dev
git clone --branch v1.15.1 --single-branch https://github.com/trojan-gfw/trojan.git
cd trojan
cmake .
make
strip -s trojan

# 3. Run
apk add --no-cache tzdata ca-certificates libstdc++ boost-system boost-program_options mariadb-connector-c
cp /root/trojan/trojan /usr/bin
touch /usr/local/etc/trojan/config.json
## 
echo -e 'trojan' >> /etc/local.d/trojan.start
chmod +x /etc/local.d/trojan.start
rc-update add local


# Trojan-go
mkdir -p /srv/trojan-go
wget -qP /srv/trojan-go https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.2/trojan-go-linux-armv8.zip
unzip trojan-go-linux-armv8.zip -d /srv/trojan-go

## auto start
vi /etc/init.d/trojan-go
```sh
#!/sbin/openrc-run

cfgfile=${cfgfile:-/srv/trojan-go.config.json}
pidfile="/run/$RC_SVCNAME.pid"
command=${command:-/srv/trojan-go/trojan-go}
command_args="-config $cfgfile"
required_files="$cfgfile"

depend() {
  need net
  use dns logger netmount
}
```
chmod 755 /etc/init.d/trojan-go
