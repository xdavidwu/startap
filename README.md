# startap

A script to start a nat ap on linux

Automatically unblock phy, create dev, set mac, set up masq nat, set channel options if needed, set ip and launch hostapd and udhcpd

## Requirements

### Commands

* ifconfig

* hostapd

* udhcpd (symlink it from busybox)

* iptables

* sysctl

* iw

* modprobe (optional, for modprobing nat masq modules)

* rfkill (optional, for unblocking if blocked)

### Configs

* /etc/hostapd/hostapd.conf

* /etc/udhcpd.conf

# Options

See variables in the script
