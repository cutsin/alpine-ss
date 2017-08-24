echo "hostname" > /etc/hostname
hostname -F /etc/hostname
echo -e "nameserver 8.8.8.8\nnameserver 114.114.114.114" > /etc/resolv.conf
echo -e "auto lo\niface lo inet loopback\nauto eth0\niface eth0 inet dhcp" > /etc/network/interfaces
service networking start
echo -e "echo "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.conf
sysctl -p