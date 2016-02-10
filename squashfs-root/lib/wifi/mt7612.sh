#!/bin/sh
#
# Copyright (c) 2014 OpenWrt
# Copyright (C) 2013-2015 D-Team Technology Co.,Ltd. ShenZhen
# Copyright (c) 2005-2015, lintel <lintel.huang@gmail.com>
# Copyright (c) 2013, Hoowa <hoowa.sun@gmail.com>
# Copyright (c) 2015, GuoGuo <gch981213@gmail.com>
#
# 	描述:Ralink/MTK RT2860v2 5G无线驱动detect脚本
#
# 	警告:对着屏幕的哥们,我们允许你使用此脚本，但不允许你抹去作者的信息,请保留这段话。
#

append DRIVERS "mt7612"

. /lib/wifi/librt2860v2.sh

detect_mt7612() {
	#判断系统是否存在rt2860v2_ap相关模块，不存在则退出
	cd /sys/module/
		[ -d mt76x2e ] || return

	[ -d $CFG_FILES_DIR ] || mkdir -p $CFG_FILES_DIR

	#检查并创建WiFi驱动配置链接
	[ -f /etc/Wireless/MT76X2/MT7612.dat ] || {
		mkdir -p /etc/Wireless/MT76X2/ 2>/dev/null
		touch $CFG_FILES_2ND
		ln -s $CFG_FILES_2ND /etc/Wireless/MT76X2/MT7612.dat 2>/dev/null
	}

	#检测系统是否存在ra0接口
	[ $( grep -c "rai0" /proc/net/dev) -eq 1 ] && {
		config_get type rai0 type
		[ "$type" = mt7612 ] && continue
cat <<EOF
config wifi-device  rai0
	option type     mt7612
	option hwmode	11a
	option channel  auto
	option txpower 	100
	option htmode	VHT80
	option country 	CN

config wifi-iface
	option device   rai0
	option network	lan
	option mode     ap
# 	option doth     1
	option ssid     PandoraBox_5G${i#0}_$( echo $(rt2860v2_get_second_if_mac Factory) | awk -F ":" '{print $4""$5""$6 }'| tr a-z A-Z)
	option encryption none
#	option encryption psk2
#	option key $(get_pre_wpa_key)

EOF
	}
}


