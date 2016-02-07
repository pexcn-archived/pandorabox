#!/bin/sh
#.Distributed under the terms of the GNU General Public License (GPL) version 2.0
#.Christian Schoenebeck <christian dot schoenebeck at gmail dot com>
[ $# -lt 2 ] && exit 1
. /usr/lib/ddns/dynamic_dns_functions.sh
SECTION_ID="lucihelper"
LOGFILE="$LOGDIR/$SECTION_ID.log"
DATFILE="$RUNDIR/$SECTION_ID.$$.dat"
ERRFILE="$RUNDIR/$SECTION_ID.$$.err"
VERBOSE_MODE=0
use_syslog=0
use_logfile=0
__RET=0
case "$1" in
	get_registered_ip)
		local IP
		domain=$2
		use_ipv6=${3:-"0"}
		force_ipversion=${4:-"0"}
		force_dnstcp=${5:-"0"}
		dns_server=${6:-""}
		write_log 7 "-----> get_registered_ip IP"
		get_registered_ip IP
		__RET=$?
		[ $__RET -ne 0 ] && IP=""
		echo -n "$IP"
		;;
	verify_dns)
		use_ipv6=${3:-"0"}
		force_ipversion=${4:-"0"}
		write_log 7 "-----> verify_dns '$2'"
		verify_dns "$2"
		__RET=$?
		;;
	verify_proxy)
		use_ipv6=${3:-"0"}
		force_ipversion=${4:-"0"}
		write_log 7 "-----> verify_proxy '$2'"
		verify_proxy "$2"
		__RET=$?
		;;
	get_local_ip)
		local IP
		use_ipv6="$2"
		ip_source="$3"
		ip_network="$4"
		ip_url="$5"
		ip_interface="$6"
		ip_script="$7"
		proxy="$8"
		force_ipversion="0"
		use_https="0"
		[ -n "$proxy" -a "$ip_source" = "web" ] && {
			export HTTP_PROXY="http://$proxy"
			export HTTPS_PROXY="http://$proxy"
			export http_proxy="http://$proxy"
			export https_proxy="http://$proxy"
		}
		[ "$ip_source" = "web" -o  "$ip_source" = "script" ] && {
			write_log 7 "-----> timeout 3 -- get_local_ip IP"
			timeout 3 -- get_local_ip IP
		} || {
			write_log 7 "-----> get_local_ip IP"
			get_local_ip IP
		}
		__RET=$?
		;;
	*)
		__RET=255
		;;
esac
[ -f $DATFILE ] && rm -f $DATFILE
[ -f $ERRFILE ] && rm -f $ERRFILE
return $__RET