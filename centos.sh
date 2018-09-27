# core
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
chmod +x bbr.sh
./bbr.sh
# bbr
echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.conf
sysctl -p

# vi /etc/shadowsocks-libev/config.json
systemctl start shadowsocks-libev
systemctl disable firewalld

# 
echo 'fs.file-max = 6553560' > /etc/sysctl.conf
echo '* soft nofile 65535\n* hard nofile 65535\n* soft nproc 65535\n* hard nproc 65535' > /etc/security/limits.conf

# SS
wget https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo -P /etc/yum.repos.d/
wget https://copr.fedorainfracloud.org/coprs/outman/shadowsocks-libev/repo/epel-7/outman-shadowsocks-libev-epel-7.repo -P /etc/yum.repos.d/
yum install -y epel-release
yum install -y libsodium shadowsocks-libev simple-obfs
