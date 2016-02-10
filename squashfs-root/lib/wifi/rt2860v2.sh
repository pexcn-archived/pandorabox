#!/bin/sh
#
# Copyright (c) 2014 OpenWrt
# Copyright (C) 2013-2015 D-Team Technology Co.,Ltd. ShenZhen
# Copyright (c) 2005-2015, lintel <lintel.huang@gmail.com>
# Copyright (c) 2013, Hoowa <hoowa.sun@gmail.com>
# Copyright (c) 2015, GuoGuo <gch981213@gmail.com>
#
# 	描述:Ralink/MTK RT2860v2 2.4G无线驱动detect脚本
#
# 	嘿，对着屏幕的哥们,为了表示对原作者辛苦工作的尊重，任何引用跟借用都不允许你抹去所有作者的信息,请保留这段话。
#

append DRIVERS "rt2860v2"

. /lib/wifi/librt2860v2.sh

detect_rt2860v2() {
	#判断系统是否存在rt2860v2_ap相关模块，不存在则退出
	cd /sys/module/
		[ -d rt2860v2_ap ] || [ -d mt76x2e ] || [ -d mt7603e ]  || [ -d mt7628 ]  || return
		
	[ -d $CFG_FILES_DIR ] || mkdir -p $CFG_FILES_DIR
		
	#检查并创建WiFi驱动配置链接
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
	#检测系统是否存在ra0接口
	[ $( grep -c "ra0" /proc/net/dev) -eq 1 ] && {
		config_get type ra0 type
		[ "$type" = rt2860v2 ] && return

cat <<EOF
config wifi-device  ra0
	option type		rt2860v2
	option hwmode		11g
	option channel		auto
	option txpower		100
	option htmode		HT40
	option country		CN

config wifi-iface
	option device	ra0
	option network	lan
	option mode		ap
	option wps		pbc
	option ssid		PandoraBox${i#0}_$( echo $(rt2860v2_get_first_if_mac Factory) | awk -F ":" '{print $4""$5""$6 }'| tr a-z A-Z)
	option encryption	none
	
#	option encryption	psk2
#	option key		$(get_pre_wpa_key)
EOF
	}
}


