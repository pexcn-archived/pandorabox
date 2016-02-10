#!/bin/sh
#
# Copyright (c) 2014 OpenWrt
# Copyright (C) 2013-2015 D-Team Technology Co.,Ltd. ShenZhen
# Copyright (c) 2005-2015, lintel <lintel.huang@gmail.com>
# Copyright (c) 2013, Hoowa <hoowa.sun@gmail.com>
# Copyright (c) 2015, GuoGuo <gch981213@gmail.com>
#
# 	RT2860v2/MT7603/MT7610E/MT76X2E 脚本函数库
#
# 	嘿，对着屏幕的哥们,为了表示对原作者辛苦工作的尊重，任何引用跟借用都不允许你抹去所有作者的信息,请保留这段话。
#

CFG_FILES_DIR="/tmp/profiles/"
CFG_FILES_1ST=$CFG_FILES_DIR"rt2860v2_2g.dat"
CFG_FILES_2ND=$CFG_FILES_DIR"rt2860v2_5g.dat"

CFG_LOCK_FILE=$CFG_FILES_DIR"rt2860v2.lock"

CFG_RT2860V2_1ST_FORCE_HT40=0
CFG_RT2860V2_2ND_FORCE_HT40=0

CFG_RT2860V2_MAX_BSSID=4

rt2860v2_dbg() {
      echo -n "[RT2860v2 DBG]" 	>/dev/ttyS1
      echo "$1" 			>/dev/ttyS1
}

is_mt76x2e() {
	if 	[ -d /sys/module/mt76x2e/drivers/pci:rt2860/0000:01:00.0  -a  /sys/module/mt76x2e/drivers/pci:rt2860/0000:02:00.0 ];  then
		echo "1"
	else
		echo "0"
	fi;
}

cpu_is_mt7621() {
	local cpu_name
	cpu_name=$(awk 'BEGIN{FS="[ \t]+:[ \t]"} /system type/ {print $2}' /proc/cpuinfo)
	case "$cpu_name" in
	*"MediaTek MT7621A" | \
	*"MediaTek MT7621S" | \
	*"MediaTek MT7621")
		echo "1"
		;;
	*)
		echo "0"
		;;
	esac
}

cpu_is_mt7628() {
	local cpu_name
	cpu_name=$(awk 'BEGIN{FS="[ \t]+:[ \t]"} /system type/ {print $2}' /proc/cpuinfo)
	case "$cpu_name" in
	*"MediaTek MT7628AN" | \
	*"MediaTek MT7688AN" | \
	*"MediaTek MT7688" | \
	*"MediaTek MT7628")
		echo "1"
		;;
	*)
		echo "0"
		;;
	esac
}

rt2860v2_shutdown_if()
{
	case "$1" in
	*"2.4G")
		for vif in ra0 ra1 ra2 ra3 ra4 ra5 ra6 ra7 wds0 wds1 wds2 wds3 apcli0; do
		ifconfig $vif down 2>/dev/null
		done
		;;
	*"5G")
		for vif in rai0 rai1 rai2 rai3 rai4 rai5 rai6 rai7 wdsi0 wdsi1 wdsi2 wdsi3 apclii0; do
		ifconfig $vif down 2>/dev/null
		done
		;;
	*)
		for vif in ra0 ra1 ra2 ra3 ra4 ra5 ra6 ra7 wds0 wds1 wds2 wds3 apcli0 rai0 rai1 rai2 rai3 rai4 rai5 rai6 rai7 wdsi0 wdsi1 wdsi2 wdsi3 apclii0; do
		ifconfig $vif down 2>/dev/null
		done
		;;
	esac
}
#获取随机的WPA密钥
get_pre_wpa_key() {
		echo $(hexdump -n 8 /dev/urandom |awk '{print $2$3$4$5;}' | tr a-z A-Z)
}

#判断密钥类型

get_wep_key_type() {
	local KeyLen=$(expr length "$1")
	if [ $KeyLen -eq 10 ] || [ $KeyLen -eq 26 ]
	then
		echo 0
	else
		echo 1
	fi	
}
rt2860v2_get_first_if_mac() {
	factory_part=$(find_mtd_part $1)
	dd bs=1 skip=4 count=6 if=$factory_part 2>/dev/null | /usr/sbin/maccalc bin2mac	
}

rt2860v2_get_second_if_mac() {
	factory_part=$(find_mtd_part $1)
	dd bs=1 skip=32772 count=6 if=$factory_part 2>/dev/null | /usr/sbin/maccalc bin2mac	
}
