#!/bin/sh
set -e

# script to start a nat ap
# requirements: 
#  commands:
#   ip
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

# interface to start ap
IFACE=ap0

# phy $IFACE is on
PHY=phy0

# ip of $IFACE
APIP=192.168.40.1/24

# mac of $IFACE, leave empty if no need to change
APHW=12:34:56:78:90:ab

# if set, generate a random mac, overwrites $APHW
RND_APHW=

# if set, set reg domain to it
REG=

# channel config copy from which iface (if it got an ip)
# useful if it is also on $PHY (#channels limit)
# leave empty if not needed
CHANNEL_IFACE=wlan0

if [ 0 != "$(id -u)" ];then
	echo "$0: Permission denied"
	exit 13
fi

if [ -n "$RND_APHW" ];then
	APHW=$(printf '%02x' $((0x$(od /dev/urandom -A n -N 1 -t x1 | tr -d ' ') & 0xfe | 0x02)); od /dev/urandom -A n -N 5 -t x1 | tr ' ' ':')
fi

modprobe iptable_nat || true
modprobe ipt_MASQUERADE || true

sysctl -w net.ipv4.ip_forward=1

if [ -n "$(which rfkill)" ] && [ -n "$(rfkill | grep $PHY | grep ' blocked')" ];then
	rfkill unblock "$(rfkill list | grep $PHY | cut -d ':' -f 1)"
fi
if [ -z "$(ip l show $IFACE 2>/dev/null)" ];then
	iw phy $PHY interface add $IFACE type __ap
fi
if [ -n "$APHW" ];then
	ip l set $IFACE address $APHW
fi
if [ -z "$(iptables -t nat -L POSTROUTING | grep MASQUERADE)" ];then
	iptables -t nat -A POSTROUTING -j MASQUERADE
fi
if [ -n "$CHANNEL_IFACE" ] && [ -n "$(ip a show $CHANNEL_IFACE | grep inet)" ];then
	CHANNEL=$(iw dev $CHANNEL_IFACE info | cut -f 2 | grep channel | cut -f 2 -d ' ')
	sed -i "{s/^channel=.*/channel=$CHANNEL/}" /etc/hostapd/hostapd.conf
fi
if [ -n "$REG" ];then
	iw reg set $REG
fi
hostapd -B /etc/hostapd/hostapd.conf
sleep 1 # to wait for hostapd ready
ip a add $APIP dev $IFACE
udhcpd -S
