#!/bin/bash
set -e

# script to start a nat ap
# requirements: 
#  commands:
#   ifconfig
#   hostapd
#   udhcpd (symlink it from busybox)
#   iptables
#   sysctl
#   iw
#   modprobe (optional, for modprobing nat masq modules)
#   rfkill (optional, for unblocking if blocked)
#  configs:
#   /etc/hostapd/hostapd.conf
#   /etc/udhcpd.conf

# TODO: use iproute2

# interface to start ap
IFACE=ap0

# phy $IFACE is on
PHY=phy0

# ip of $IFACE
APIP=192.168.40.1

# mac of $IFACE, leave empty if no need to change
APHW=12:34:56:78:90:ab

# channel config copy from which iface (if it got an ip)
# useful if it is also on $PHY (#channels limit)
# leave empty if not needed
CHANNEL_IFACE=wlan0

if [ ! -n "$(id | grep uid\=0\(root\))" ];then
	echo "$0: Permission denied"
	exit 13
fi

modprobe iptable_nat || true
modprobe ipt_MASQUERADE || true

sysctl -w net.ipv4.ip_forward=1

if [ -n "$(which rfkill)" ] && [ -n "$(rfkill | grep $PHY | grep ' blocked')" ];then
	rfkill unblock "$(rfkill list | grep $PHY | cut -d ':' -f 1)"
fi
if [ ! -n "$(ifconfig -a | grep ^$IFACE)" ];then
	iw phy $PHY interface add $IFACE type __ap
fi
if [ -n "$APHW" ] && [ ! -n "$(ifconfig $IFACE | grep $APHW)" ];then
	ifconfig $IFACE hw ether $APHW
fi
if [ ! -n "$(iptables -t nat -L POSTROUTING | grep MASQUERADE)" ];then
	iptables -t nat -A POSTROUTING -j MASQUERADE
fi
if [ -n "$CHANNEL_IFACE" ] && [ -n "$(ifconfig $CHANNEL_IFACE | grep inet)" ];then
	CHANNEL=$(iw dev $CHANNEL_IFACE info | cut -f 2 | grep channel | cut -d ' ' -f 2)
	sed -i "{s/^channel=.*/channel=$CHANNEL/}" /etc/hostapd/hostapd.conf
fi
hostapd -B /etc/hostapd/hostapd.conf
sleep 1 # to wait for hostapd ready
ifconfig $IFACE $APIP
udhcpd -S
