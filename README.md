# startap

a script to start a nat ap on linux

automatically unblock phy, create dev, set mac, set up masq nat, set channel options if needed, set ip and launch hostapd and udhcpd

## requirements

### commands

* ifconfig

* hostapd

* udhcpd (symlink it from busybox)

* iptables

* sysctl

* iw

* modprobe (optional, for modprobing nat masq modules)

* rfkill (optional, for unblocking if blocked)

### configs

* /etc/hostapd/hostapd.conf

* /etc/udhcpd.conf

# options

see variables in the script
