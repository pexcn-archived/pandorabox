#!/bin/sh

append DRIVERS "rt2860v2"

. /lib/wifi/librt2860v2.sh

detect_rt2860v2() {
	cd /sys/module/
		[ -d rt2860v2_ap ] || [ -d mt76x2e ] || [ -d mt7603e ]  || [ -d mt7628 ]  || return

	[ -d $CFG_FILES_DIR ] || mkdir -p $CFG_FILES_DIR

	if [ $(cpu_is_mt7621) == "1" ]; then
	{
			[ -f /etc/Wireless/MT7603/MT7603.dat ] || {
				mkdir -p /etc/Wireless/MT7603/ 2>/dev/null
				touch $CFG_FILES_1ST
				ln -s $CFG_FILES_1ST /etc/Wireless/MT7603/MT7603.dat 2>/dev/null
			}
			[ -f /etc/Wireless/MT76X2/MT7602.dat ] || {
				mkdir -p /etc/Wireless/MT76X2/ 2>/dev/null
				touch $CFG_FILES_1ST
				ln -s $CFG_FILES_1ST /etc/Wireless/MT76X2/MT7602.dat 2>/dev/null
			}
	}
	else
	{
		[ -f /etc/Wireless/RT2860/RT2860.dat ] || {
			mkdir -p /etc/Wireless/RT2860/ 2>/dev/null
			touch $CFG_FILES_1ST
			ln -s $CFG_FILES_1ST /etc/Wireless/RT2860/RT2860.dat 2>/dev/null
		}
	}
	fi;

	[ $( grep -c "ra0" /proc/net/dev) -eq 1 ] && {
		config_get type ra0 type
		[ "$type" = rt2860v2 ] && return

cat <<EOF
config wifi-device  ra0
	option type rt2860v2
	option hwmode 11g
	option channel auto
	option txpower 100
	option htmode HT40
	option country CN
	option noscan 1
	option txburst 1

config wifi-iface
	option device ra0
	option network lan
	option mode ap
	option wps pbc
	option ssid OpenWrt${i#0}
	option encryption none
	
#	option encryption psk2
#	option key $(get_pre_wpa_key)
EOF
	}
}

