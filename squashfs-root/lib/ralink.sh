#!/bin/sh
# 
#   Copyright (C) 2014 D-Team Technology Co.,Ltd. ShenZhen
#   Copyright (C) 2014 lintel<lintel.huang@gmail.com>
# 
#
#    警告:对着屏幕的哥们,我们允许你使用此脚本，但不允许你抹去作者的信息,请保留这段话。
#
#    Copyright (C) 2010 OpenWrt.org
#


ralink_board_name() {
	local machine
	local name

	machine=$(awk 'BEGIN{FS="[ \t]+:[ \t]"} /machine/ {print $2}' /proc/cpuinfo)

	case "$machine" in
	*"ASUS RT-N13")
		name="rt-n13"
		;;
	*"HuaWei HG255D")
		name="hg255d"
		;;
	*"Mercury MW305R")
		name="mw305r"
		;;
	*"D-Team RY-1")
		name="ry1"
		;;
	*"Lenovo Y1S")
		name="y1s"
		;;
	*"Xunlei SuperDisk mini")
		name="superdisk_mini"
		;;
	*"Lenovo Y1")
		name="y1"
		;;
	*"Lenovo Y2S")
		name="y2s"
		;;
	*"PandoraBox PBR-M1")
		name="pbr-m1"
		;;
	*"AmazingBox")
		name="abox"
		;;
	*"XunLei Time Cloud Board")
		name="timecloud"
		;;
	*"Youku YK1")
		name="yk1"
		;;
	*"Xiaomi mini Board")
		name="xiaomi-mini"
		;;
	*"D-Link DIR-620 B2")
		name="dir620"
		;;
	*"MediaTek MT7620A Evaluation Board")
		name="mt7620a-evb"
		;;
	*"MediaTek MT7628A Evaluation Board")
		name="mt7628a-evb"
		;;
	*"PandoraBox AP7620A Board")
		name="ap7620a"
		;;
	*"PandoraBox AP7621A Board")
		name="ap7621a"
		;;
	*"MediaTek MT7621A Evaluation Board")
		name="mt7621a-evb"
		;;
	*"PandoraBox PBR-M1-JD")
		name="m1-jd"
		;;
	*"Baidu BR100 Board")
		name="br100"
		;;
	*"ZBT WR8305RT")
		name="wr8305rt"
		;;
	*"WRTnode Board")
		name="wrtnode"
		;;
	*"MicroWRT Board")
		name="microwrt"
		;;
	*"ZTE Q7 Board")
		name="q7"
		;;
	*"OYE-0001 Board")
		name="oye-0001"
		;;
	*"HiWiFi JI2 Board")
		name="ji2"
		;;
	*"HuaWei HG256")
		name="hg256"
		;;
	*"ZyXEL WAP120NF")
		name="wap120nf"
		;;
	*"ZBT AP8100RT")
		name="ap8100rt"
		;;
	*"RT-N10+")
		name="rt-n10-plus"
		;;
	*"RT-N15")
		name="rt-n15"
		;;
	*"RT-N56U")
		name="rt-n56u"
		;;

	*)
		name="generic"
		;;
	esac

	echo $name
}

ralink_get_mac_binary()
{
	local mtdname="$1"
	local seek="$2"
	local part

	. /lib/functions.sh

	part=$(find_mtd_part "$mtdname")
	if [ -z "$part" ]; then
		echo "ramips_get_mac_binary: partition $mtdname not found!" >&2
		return
	fi

	dd bs=1 skip=$seek count=6 if=$part 2>/dev/null | /usr/sbin/maccalc bin2mac
}

