# How to use
# sudo -i
# wget -O -  https://raw.githubusercontent.com/cutsin/alpine-ss/master/trojan.onekey.sh | sh -m a@b.com -k cfkey -d abc.com -p mypwd -x https://www.google.com -y https://www.google.com

# Get Command Options
while getopts ':m:k:d:p:x:y:' opt
do
  case $opt in
    m) CFEMAIL=$OPTARG;;
    k) CFKEY=$OPTARG;;
    d) YOURDOMAIN=$OPTARG;;
    p) PASSWD=$OPTARG;;
    x) PROXYROOT=$OPTARG;;
    y) PROXYROOT2=$OPTARG;;
    [?])
    echo "Usage: $0 [-m Cloudflare login email] [-k 'Cloudflase api key'] [-d yourdomain] [-p password] [-x proxy path] [-y proxy path2]"
    exit 1;;
  esac
done

# Linux kernal

## Fastopen
sysctl -w net.ipv4.tcp_congestion_control=hybla
sysctl -w net.ipv4.tcp_fastopen=3

## BBR
echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.conf
sysctl -p

# Trojan Build
cd /srv
apk add --no-cache git build-base make cmake boost-dev openssl-dev mariadb-connector-c-dev
git clone --branch v1.16.0 --single-branch https://github.com/trojan-gfw/trojan.git
cd /srv/trojan
cmake .
make
strip -s trojan

## Trojan runtime dependencies
apk add --no-cache tzdata ca-certificates libstdc++ boost-system boost-program_options mariadb-connector-c

## config file
cat>/srv/trojan.config.json<<EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": [
    "${PASSWD}"
  ],
  "log_level": 2,
  "ssl": {
    "cert": "/srv/ssl/fullchain",
    "key": "/srv/ssl/key",
    "key_password": "",
    "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
    "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
    "prefer_server_cipher": true,
    "alpn": [
      "h2",
      "http/1.1"
    ],
    "alpn_port_override": {
      "h2": 81
    },
    "reuse_session": true,
    "session_ticket": false,
    "session_timeout": 600,
    "plain_http_response": "",
    "curves": "",
    "dhparam": ""
  },
  "tcp": {
    "prefer_ipv4": false,
    "no_delay": true,
    "keep_alive": true,
    "reuse_port": false,
    "fast_open": false,
    "fast_open_qlen": 20
  },
  "mysql": {
    "enabled": false,
    "server_addr": "127.0.0.1",
    "server_port": 3306,
    "database": "trojan",
    "username": "trojan",
    "password": ""
  }
}
EOF

## Add trojan as service
cat>/etc/init.d/trojan<<EOF
#!/sbin/openrc-run
cfgfile=\${cfgfile:-/srv/trojan.config.json}
pidfile="/run/\$RC_SVCNAME.pid"
command=\${command:-/srv/trojan/trojan}
command_args="--config \$cfgfile"
command_background=true
required_files="\$cfgfile"
depend() {
  need net
  use dns logger netmount
}
EOF
## Auto start
chmod +x /etc/init.d/trojan
rc-update add trojan

# Nginx
apk add nginx --no-cache
## Auto start
rc-update add nginx
## conf
cat>/etc/nginx/nginx.conf<<EOF
user nginx;
worker_processes auto;
pcre_jit on;
error_log /var/log/nginx/error.log warn;
include /etc/nginx/modules/*.conf;
events {
  worker_connections 1024;
}
http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  server_tokens off;
  client_max_body_size 1m;
  keepalive_timeout 65;
  sendfile on;
  tcp_nodelay on;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:2m;
  gzip on;
  gzip_vary on;
  gzip_static on;
  log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
      '\$status \$body_bytes_sent "\$http_referer" '
      '"\$http_user_agent" "\$http_x_forwarded_for"';
  access_log /var/log/nginx/access.log main;
  include /etc/nginx/conf.d/*.conf;
}
EOF
cat>/etc/nginx/conf.d/default.conf<<EOF
server {
  listen 80;
  listen 81 http2;
  server_name ${YOURDOMAIN};
  location = / {
    proxy_pass ${PROXYROOT};
  }
  location / {
    proxy_pass ${PROXYROOT2};
  }
}
server {
  listen 80;
  listen [::]:80;
  server_name _;
  return 301 https://${YOURDOMAIN}$request_uri;
}
EOF

# ACME
apk add openssl acme.sh --no-cache
export CF_Email=$CFEMAIL
export CF_Key=$CFKEY
echo -e "export CF_Email=$CFEMAIL\nexport CF_Key=$CFKEY" >> /etc/profile
source /etc/profile

## ENV
cat>/etc/local.d/trojan.start<<EOF
source /etc/profile
acme.sh --upgrade --auto-upgrade --force
EOF
## Auto start
chmod +x /etc/local.d/trojan.start
rc-update add local
## Issue
mkdir /srv/ssl
acme.sh --issue --dns dns_cf -d $YOURDOMAIN --keylength ec-256 --force
acme.sh --upgrade --auto-upgrade --force
acme.sh --installcert -d $YOURDOMAIN --cert-file /srv/ssl/cert --key-file /srv/ssl/key --ca-file /srv/ssl/ca --fullchain-file /srv/ssl/fullchain --reloadcmd "rc-service trojan restart && rc-service nginx restart" --ecc --force
