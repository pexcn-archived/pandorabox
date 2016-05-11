#!/bin/sh

append DRIVERS "mt7612"

. /lib/wifi/librt2860v2.sh

detect_mt7612() {
	cd /sys/module/
		[ -d mt76x2e ] || return

	[ -d $CFG_FILES_DIR ] || mkdir -p $CFG_FILES_DIR

	[ -f /etc/Wireless/MT76X2/MT7612.dat ] || {
		mkdir -p /etc/Wireless/MT76X2/ 2>/dev/null
		touch $CFG_FILES_2ND
		ln -s $CFG_FILES_2ND /etc/Wireless/MT76X2/MT7612.dat 2>/dev/null
	}

	[ $( grep -c "rai0" /proc/net/dev) -eq 1 ] && {
		config_get type rai0 type
		[ "$type" = mt7612 ] && continue
cat <<EOF
config wifi-device  rai0
	option type     mt7612
	option hwmode	11a
	option channel  157
	option txpower 	100
	option htmode	VHT80
	option country 	US
	option noscan 	1
	option txburst 	1

config wifi-iface
	option device   rai0
	option network	lan
	option mode     ap
	# option doth     1
	option ssid     OpenWrt-5G${i#0}
	option encryption none

EOF
	}
}

