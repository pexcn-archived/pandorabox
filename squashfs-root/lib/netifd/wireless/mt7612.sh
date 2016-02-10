#!/bin/sh
#
# Copyright (c) 2014 OpenWrt
# Copyright (C) 2013-2015 D-Team Technology Co.,Ltd. ShenZhen
# Copyright (c) 2005-2015, lintel <lintel.huang@gmail.com>
# Copyright (c) 2013, Hoowa <hoowa.sun@gmail.com>
# Copyright (c) 2015, GuoGuo <gch981213@gmail.com>
#
# 	描述:RT2860v2 5G无线驱动netifd配置脚本
#
# 	嘿，对着屏幕的哥们,为了表示对原作者辛苦工作的尊重，任何引用跟借用都不允许你抹去所有作者的信息,请保留这段话。
#
. /lib/netifd/netifd-wireless.sh
. /lib/wifi/librt2860v2.sh

init_wireless_driver "$@"

#读取device相关设置项并写入json
drv_mt7612_init_device_config() { 
	config_add_string channel hwmode htmode country
	config_add_int beacon_int chanbw frag rts txburst
	config_add_int rxantenna txantenna antenna_gain txpower distance wmm
	config_add_boolean greenap diversity noscan
	config_add_int powersave
	config_add_int maxassoc
	config_add_boolean hidessid
	
	config_add_boolean \
		rxldpc \
		short_gi_80 \
		short_gi_160 \
		tx_stbc_2by1 \
		su_beamformer \
		su_beamformee \
		mu_beamformer \
		mu_beamformee \
		vht_txop_ps \
		htc_vht \
		rx_antenna_pattern \
		tx_antenna_pattern
	config_add_int vht_max_a_mpdu_len_exp vht_max_mpdu vht_link_adapt vht160 rx_stbc tx_stbc
	
	config_add_boolean \
		ldpc \
		greenfield \
		short_gi_20 \
		short_gi_40 \
		dsss_cck_40
}

#读取iface相关设置项并写入json
drv_mt7612_init_iface_config() { 
	config_add_boolean disabled
	config_add_string mode bssid ssid encryption
	config_add_boolean hidden
	config_add_string key key1 key2 key3 key4
	config_add_string wps
	config_add_string pin
	config_add_string macpolicy
	config_add_array maclist
	
	config_add_boolean wds
	config_add_int max_listen_int
	config_add_int dtim_period
}

mt7612_ap_vif_pre_config() {
	local name="$1"

	json_select config
	json_get_vars disabled encryption key key1 key2 key3 key4 ssid mode wps pin isolate doth hidden macpolicy
	json_get_values maclist maclist
	json_select ..
	[ $disabled == 1 ] && return
	echo "Ralink_5G_AP:Generating ap config for interface ra${ApBssidNum}"
	ifname="rai${ApBssidNum}"

	#MAC过滤方式相关设定 由于编号问题......我扔在这了......
	ra_maclist="${maclist// /;};"
	case "$macpolicy" in
	allow)
		echo "Ralink_5G_AP:Interface ${ifname} has MAC Policy.Allow list:${ra_maclist}"
		echo "AccessPolicy${ApBssidNum}=1" >> $CFG_FILES_2ND
		echo "AccessControlList$ApBssidNum=${ra_maclist}" >> $CFG_FILES_2ND
	;;
	deny)
		echo "Ralink_5G_AP:Interface ${ifname} has MAC Policy.Deny list:${ra_maclist}"
		echo "AccessPolicy${ApBssidNum}=2" >> $CFG_FILES_2ND
		echo "AccessControlList${ApBssidNum}=${ra_maclist}" >> $CFG_FILES_2ND
	;;
	esac

	let ApBssidNum+=1
	echo "SSID$ApBssidNum=${ssid}" >> $CFG_FILES_2ND #SSID
	case "$encryption" in #加密方式
	wpa*|psk*|WPA*|Mixed|mixed)
		local enc
		local crypto
		case "$encryption" in
			Mixed|mixed|psk+psk2|psk-mixed*)
				enc=WPAPSKWPA2PSK
			;;
			WPA2*|wpa2*|psk2*)
				enc=WPA2PSK
			;;
			WPA*|WPA1*|wpa*|wpa1*|psk*)
				enc=WPAPSK
			;;
			esac
			crypto="AES"
		case "$encryption" in
			*tkip+aes*|*tkip+ccmp*|*aes+tkip*|*ccmp+tkip*)
				crypto="TKIPAES"
			;;
			*aes*|*ccmp*)
				crypto="AES"
			;;
			*tkip*) 
				crypto="TKIP"
				echo "Warning!!! TKIP is not support in 802.11n 40Mhz!!!"
			;;
			esac
				ApAuthMode="${ApAuthMode}${enc};"
				ApEncrypType="${ApEncrypType}${crypto};"
				ApDefKId="${ApDefKId}2;"
			echo "WPAPSK$ApBssidNum=${key}" >> $CFG_FILES_2ND
	;;
	WEP|wep|wep-open|wep-shared)
		if [ "$encryption" == "wep-shared" ]; then
			ApAuthMode="${ApAuthMode}SHARED;"
		else  
			ApAuthMode="${ApAuthMode}OPEN;"
		fi
		ApEncrypType="${ApEncrypType}WEP;"
		K1Tp=$(get_wep_key_type "$key1")
		K2Tp=$(get_wep_key_type "$key2")
		K3Tp=$(get_wep_key_type "$key3")
		K4Tp=$(get_wep_key_type "$key4")

		[ $K1Tp -eq 1 ] && key1=$(echo $key1 | cut -d ':' -f 2- )
		[ $K2Tp -eq 1 ] && key2=$(echo $key2 | cut -d ':' -f 2- )
		[ $K3Tp -eq 1 ] && key3=$(echo $key3 | cut -d ':' -f 2- )
		[ $K4Tp -eq 1 ] && key4=$(echo $key4 | cut -d ':' -f 2- )
		echo "Key1Str${ApBssidNum}=${key1}" >> $CFG_FILES_2ND
		echo "Key2Str${ApBssidNum}=${key2}" >> $CFG_FILES_2ND
		echo "Key3Str${ApBssidNum}=${key3}" >> $CFG_FILES_2ND
		echo "Key4Str${ApBssidNum}=${key4}" >> $CFG_FILES_2ND
		ApDefKId="${ApDefKId}${key};"
		;;
	none|open)
		ApAuthMode="${ApAuthMode}OPEN;"
		ApEncrypType="${ApEncrypType}NONE;"
		ApDefKId="${ApDefKId}1;"
		;;
	esac
	ApHideESSID="${ApHideESSID}${hidden:-0};"
	ApK1Tp="${ApK1Tp}${K1Tp:-0};"
	ApK2Tp="${ApK2Tp}${K2Tp:-0};"
	ApK3Tp="${ApK3Tp}${K3Tp:-0};"
	ApK4Tp="${ApK4Tp}${K4Tp:-0};"
}

mt7612_ap_vif_post_config() {
	local name="$1"

	json_select config
	json_get_vars disabled encryption key key1 key2 key3 key4 ssid mode wps pin isolate doth hidden
	json_select ..

	[ $disabled == 1 ] && return
	
	[ $ApIfCNT -gt $CFG_RT2860V2_MAX_BSSID ] && return 
	
	ifname="rai${ApIfCNT}"
	let ApIfCNT+=1

	ifconfig $ifname up

	[ $isolate == "1" ] && {
		iwpriv $ifname set NoForwarding=1
	}
	[ $doth == "1" ] && {
		iwpriv $ifname set IEEE80211H=1
	}	

	if [ "$wps" == "pbc" ]  && [ "$encryption" != "none" ]; then
		echo "Ralink_5G_AP:Using iwpriv to enable WPS for ${ifname}."
		iwpriv $ifname set WscConfMode=7 
		iwpriv $ifname set WscConfStatus=2
		iwpriv $ifname set WscMode=2
		iwpriv $ifname set WscV2Support=0
	fi

	wireless_add_vif "$name" "$ifname"
	json_get_vars bridge
	[ -z `brctl show | grep $ifname` ] && [ ! -z $bridge ] && {
		echo "Ralink_5G_AP:Manually bridge interface $ifname into $bridge"
		brctl addif $bridge $ifname 
	}
}

mt7612_sta_vif_connect() {
	local name="$1"

	json_select config
	json_get_vars disabled encryption key key1 key2 key3 key4 ssid mode wps pin isolate doth hidden bssid
	json_select ..

	[ $stacount -gt 1 ] && {
		rt2860v2_dbg "Ralink_5G_STA:Ralink ApSoC drivers only support 1 sta config!"
		return
	}

	[ $disabled == 1 ] && return
	
	[ $ApIfCNT == 0 ] &&
	{
		#FIXME: need ra0 up before apcli0 start
		ifconfig rai0 up
		ifconfig apclii0 up
		ifconfig ra0 down
	}
	let stacount+=1

	if [ ! -z $bssid ] && [ ! -z $key ]
	then
		/sbin/apctrl rai0 connect "$ssid" "$key" $(echo $bssid | tr 'A-Z' 'a-z')
	else
		/sbin/apctrl rai0 connect "$ssid" "$key"
	fi
	
	sleep 2
	
#降低速率，默认以HT20连接保证最大兼容
	[ "$CFG_RT2860V2_2ND_FORCE_HT40" != "1" ] && {
	  #rt2860v2_dbg "apclii:Auto Fall Back to HT20"
	  iwpriv rai0 set AutoFallBack=1
	  iwpriv rai0 set ApCliAutoConnect=1
	  #iwpriv rai0 set HtBw=0
	}

	wireless_add_vif "$name" "apclii0"
}

#cleanup 如果不是MT7621则重载驱动
drv_mt7612_cleanup() {

	[ $(is_mt76x2e) == "1" ] && return
	
	rmmod mt76x2e >/dev/null
	insmod mt76x2e >/dev/null
	return
}

#下线全部接口
drv_mt7612_teardown() {
	rt2860v2_shutdown_if "5G"
}

#接口启动
drv_mt7612_setup() {
	json_select config
	json_get_vars main_if channel mode hwmode wmm htmode \
		txpower country macpolicy maclist greenap \
		diversity frag rts txburst distance hidden \
		disabled maxassoc macpolicy maclist noscan #device所有配置项
	json_select ..

	wireless_set_data phy="rai0"
#	echo "Ralink_5G_Global:All json data here:"
#	json_dump

#检查配置文件目录是否存在，否则创建目录
	[ ! -d $CFG_FILES_DIR ] && mkdir $CFG_FILES_DIR
	
#默认无线模式为11an/ac only
	WirelessMode=14
	
	hwmode=${hwmode##11}
	case "$hwmode" in
		a) 
			WirelessMode=14
		;;
		g)
			WirelessMode=9
		;;
		*) 
			echo "unknow hwmode!! use default!!"
		;;
	esac
	
#HT默认模式设定
	HT_BW=1  #允许HT40
	HT_CE=1  #允许HT20/40共存
	HT_AutoBA=1 #自动HT带宽
	HT_DisallowTKIP=0 #是否允许TKIP加密

	#HT_MIMOPSMode用于省电模式设置
	#HT_MIMOPSMode=3
	
#VHT默认模式设定
	VHT_BW=1 #允许VHT
	VHT_DisallowNonVHT=0 #是否禁止非VHT客户端连接，VHT80 only

	case "$htmode" in
		HT40 |\
		VHT20) 
			HT_BW=0
			VHT_BW=0
		;;
		HT40 |\
		VHT40)
			HT_BW=1
			VHT_BW=0
			VHT_DisallowNonVHT=0
		;;
		VHT80)
			HT_BW=1
			VHT_BW=1
		;;
		
		VHT160)
			echo "only VHT80 support!!"
			HT_BW=1
			VHT_BW=1
		;;
		*) 
		echo "unknow htmode!! use default!!"
		;;
	esac
	
#仅HT20以外才需要设置的参数
[ "$htmode" != "HT20" ] && {
#强制HT40/VHT80
	[ "$noscan" == "1" ] && HT_CE=0 && CFG_RT2860V2_2ND_FORCE_HT40=1
#HT HTC
	[ "$ht_htc" == "1" ] && HT_HTC=1
}
#自动处理CountryRegion
	[ "$channel" == "auto" ] && {
	#CountryRegion CN
	countryregion=0
	countryregion_a=4
	}
	
	#大于11的时候支持11-14号频道，5G支持全频段
	[ "$channel" != "auto" ] && {
	[ ${channel:-0} -ge 1 -a ${channel:-0} -le 11 ] && countryregion=0
	[ ${channel:-0} -ge 12 -a ${channel:-0} -le 13 ] && countryregion=1
	[ ${channel:-0} -eq 14 ] && countryregion=31
	[ ${channel:-0} -ge 36 -a ${channel:-0} -le 140 ] && countryregion_a=7
	debug "channel=$channel countryregion=$countryregion"
	}

#第二信道自动切换
	EXTCHA=1
	[ "$channel" != "auto" ] && [ "$(( ($channel / 4) % 2 ))" == "0" ] && EXTCHA=0

#自动选择无线频道
    [ "$channel" == "auto" ] && {
        channel=149
        AutoChannelSelect=2 #增强型自动频道选择
    }



#设备配置文件生成
	cat > $CFG_FILES_2ND <<EOF
#The word of "Default" must not be removed
Default
CountryRegion=${countryregion:-0}
CountryRegionABand=${countryregion_a:-4}
CountryCode=${country:-CN}
BssidNum=${CFG_RT2860V2_MAX_BSSID:-1}
WirelessMode=${WirelessMode:-14}
FixedTxMode=
TxRate=0
Channel=${channel:-157}
BasicRate=15
BeaconPeriod=100
DtimPeriod=1
TxPower=${txpower:-100}
DisableOLBC=0
BGProtection=0
TxAntenna=
RxAntenna=
TxPreamble=1
RTSThreshold=${rts:-2347}
FragThreshold=${frag:-2346}
TxBurst=${txburst:-0}
PktAggregate=1
AutoProvisionEn=0
FreqDelta=0
TurboRate=0
WmmCapable=${wmm:-0}
APAifsn=3;7;1;1
APCwmin=4;4;3;2
APCwmax=6;10;4;3
APTxop=0;0;94;47
APACM=0;0;0;0
BSSAifsn=3;7;2;2
BSSCwmin=4;4;3;2
BSSCwmax=10;10;4;3
BSSTxop=0;0;94;47
BSSACM=0;0;0;0
AckPolicy=0;0;0;0
APSDCapable=0
DLSCapable=0
NoForwarding=0
NoForwardingBTNBSSID=0
ShortSlot=1
AutoChannelSelect=${AutoChannelSelect:-0}
IEEE8021X=0
IEEE80211H=0
CarrierDetect=0
ITxBfEn=0
PreAntSwitch=
PhyRateLimit=0
DebugFlags=0
ETxBfEnCond=0
ITxBfTimeout=0
ETxBfTimeout=0
ETxBfNoncompress=0
ETxBfIncapable=0
FineAGC=0
StreamMode=0
StreamModeMac0=
StreamModeMac1=
StreamModeMac2=
StreamModeMac3=
CSPeriod=6
RDRegion=
StationKeepAlive=0
DfsLowerLimit=0
DfsUpperLimit=0
DfsOutdoor=0
SymRoundFromCfg=0
BusyIdleFromCfg=0
DfsRssiHighFromCfg=0
DfsRssiLowFromCfg=0
DFSParamFromConfig=0
FCCParamCh0=
FCCParamCh1=
FCCParamCh2=
FCCParamCh3=
CEParamCh0=
CEParamCh1=
CEParamCh2=
CEParamCh3=
JAPParamCh0=
JAPParamCh1=
JAPParamCh2=
JAPParamCh3=
JAPW53ParamCh0=
JAPW53ParamCh1=
JAPW53ParamCh2=
JAPW53ParamCh3=
FixDfsLimit=0
LongPulseRadarTh=0
AvgRssiReq=0
DFS_R66=0
BlockCh=
PreAuth=0
WapiPsk1=0123456789
WapiPsk2=
WapiPsk3=
WapiPsk4=
WapiPsk5=
WapiPsk6=
WapiPsk7=
WapiPsk8=
WapiPskType=0
Wapiifname=
WapiAsCertPath=
WapiUserCertPath=
WapiAsIpAddr=
WapiAsPort=
RekeyMethod=DISABLE
RekeyInterval=3600
PMKCachePeriod=10
MeshAutoLink=0
MeshAuthMode=
MeshEncrypType=
MeshDefaultkey=0
MeshWEPKEY=
MeshWPAKEY=
MeshId=
HSCounter=0
HT_HTC=${HT_HTC:-0}
HT_RDG=1
HT_LinkAdapt=0
HT_OpMode=0
HT_MpduDensity=5
HT_EXTCHA=${EXTCHA}
HT_BW=${HT_BW:-0}
HT_AutoBA=1
HT_BADecline=0
HT_AMSDU=0
HT_BAWinSize=64
HT_GI=1
HT_STBC=1
HT_LDPC=0
HT_MCS=33
VHT_BW=${VHT_BW:-0}
VHT_SGI=1
VHT_STBC=0
VHT_BW_SIGNAL=0
VHT_DisallowNonVHT=${VHT_DisallowNonVHT:-0}
VHT_LDPC=0
HT_TxStream=2
HT_RxStream=2
HT_PROTECT=1
HT_DisallowTKIP=${HT_DisallowTKIP:-0}
HT_BSSCoexistence=${HT_CE:-1}
GreenAP=${greenap:-0}
WscConfMode=0
WscConfStatus=1
WCNTest=0
WdsEnable=0
WdsPhyMode=
WdsEncrypType=NONE
WdsList=
Wds0Key=
Wds1Key=
Wds2Key=
Wds3Key=
RADIUS_Server=
RADIUS_Port=1812
RADIUS_Key1=
RADIUS_Key2=
RADIUS_Key3=
RADIUS_Key4=
RADIUS_Key5=
RADIUS_Key6=
RADIUS_Key7=
RADIUS_Key8=
RADIUS_Acct_Server=
RADIUS_Acct_Port=1813
RADIUS_Acct_Key=
own_ip_addr=
Ethifname=
EAPifname=
PreAuthifname=
session_timeout_interval=0
idle_timeout_interval=0
WiFiTest=0
TGnWifiTest=0
ApCliEnable=0
ApCliSsid=
ApCliBssid=
ApCliAuthMode=
ApCliEncrypType=
ApCliWPAPSK=
ApCliDefaultKeyID=0
ApCliKey1Type=0
ApCliKey1Str=
ApCliKey2Type=0
ApCliKey2Str=
ApCliKey3Type=0
ApCliKey3Str=
ApCliKey4Type=0
ApCliKey4Str=
RadioOn=1
WscManufacturer=PandoraBox
WscModelName=PandoraBox Wireless Router
WscDeviceName=PandoraBox 5G WiFi
WscModelNumber=
WscSerialNumber=
PMFMFPC=0
PMFMFPR=0
PMFSHA256=0
LoadCodeMethod=0
MaxStaNum=${maxassoc:-0}
EOF

#接口配置生成
#	AP模式
#	统一设置的内容:
	ApEncrypType=""
	ApAuthMode=""
	ApBssidNum=0
	ApHideESSID=""
	ApDefKId=""
	ApK1Tp=""
	ApK2Tp=""
	ApK3Tp=""
	ApK4Tp=""

	for_each_interface "ap" mt7612_ap_vif_pre_config

	echo "AuthMode=${ApAuthMode}" >> $CFG_FILES_2ND
	echo "EncrypType=${ApEncrypType}" >> $CFG_FILES_2ND
	echo "HideSSID=${ApHideESSID}" >> $CFG_FILES_2ND
	echo "DefaultKeyID=${ApDefKId}" >> $CFG_FILES_2ND
	echo "Key1Type=${ApK1Tp}" >> $CFG_FILES_2ND
	echo "Key2Type=${ApK2Tp}" >> $CFG_FILES_2ND
	echo "Key3Type=${ApK3Tp}" >> $CFG_FILES_2ND
	echo "Key4Type=${ApK4Tp}" >> $CFG_FILES_2ND

#	STA模式数目
	stacount=0

#配置文件生成结束,重载驱动
	drv_mt7612_teardown
	
#FIXME:如果不重新加载驱动，apcli无法连接,MT7621却正常,BUG标记
	drv_mt7612_cleanup
	
#接口上线

#AP模式
	ApIfCNT=0
	for_each_interface "ap" mt7612_ap_vif_post_config
#STA模式
	stacount=0
	for_each_interface "sta" mt7612_sta_vif_connect

#设置无线上线
	wireless_set_up
}
add_driver mt7612
