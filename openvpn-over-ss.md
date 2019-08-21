#

1. Open your .ovpn file
2. Add 2 lines:

```
socks-proxy 127.0.0.1 1081
route YOUR_SS_SERVER_IP 255.255.255.255 net_gateway
```
