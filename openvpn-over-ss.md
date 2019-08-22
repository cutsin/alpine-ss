#

1. Open your .ovpn file, find path:

    * OSX: `/Library/Application Support/OpenVPN/profile/`;
    * Windows: `C:\Program Files (x86)\OpenVPN Technologies\OpenVPN Client\etc\profile`, you must replace all `\n\n` to '\n' first.

2. Add 2 lines:

```
socks-proxy 127.0.0.1 1081
route YOUR_SS_SERVER_IP 255.255.255.255 net_gateway
```
