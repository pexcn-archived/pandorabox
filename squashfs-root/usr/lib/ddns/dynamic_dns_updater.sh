#!/bin/sh
#.Distributed under the terms of the GNU General Public License (GPL) version 2.0
#.Christian Schoenebeck <christian dot schoenebeck at gmail dot com>
[ $# -lt 1 -o -n "${2//[0-3]/}" -o ${#2} -gt 1 ] && {
	echo -e "\n  USAGE:"
	echo -e "  $0 [SECTION] [VERBOSE_MODE]\n"
	echo    "  [SECTION]      - service section as defined in /etc/config/ddns"
	echo    "  [VERBOSE_MODE] - '0' NO output to console"
	echo    "                   '1' output to console"
	echo    "                   '2' output to console AND logfile"
	echo    "                       + run once WITHOUT retry on error"
	echo    "                   '3' output to console AND logfile"
	echo    "                       + run once WITHOUT retry on error"
	echo -e "                       + NOT sending update to DDNS service\n"
	exit 1
}
. /usr/lib/ddns/dynamic_dns_functions.sh
SECTION_ID="$1"
VERBOSE_MODE=${2:-1}
PIDFILE="$RUNDIR/$SECTION_ID.pid"
UPDFILE="$RUNDIR/$SECTION_ID.update"
DATFILE="$RUNDIR/$SECTION_ID.dat"
ERRFILE="$RUNDIR/$SECTION_ID.err"
LOGFILE="$LOGDIR/$SECTION_ID.log"
[ $VERBOSE_MODE -gt 1 -a -f $LOGFILE ] && rm -f $LOGFILE
trap "trap_handler 0 \$?" 0
trap "trap_handler 1"  1
trap "trap_handler 2"  2
trap "trap_handler 3"  3
trap "trap_handler 15" 15
################################################################################
################################################################################
load_all_config_options "ddns" "$SECTION_ID"
ERR_LAST=$?
[ -z "$enabled" ]	  && enabled=0
[ -z "$retry_count" ]	  && retry_count=0
[ -z "$use_syslog" ]      && use_syslog=2
[ -z "$use_https" ]       && use_https=0
[ -z "$use_logfile" ]     && use_logfile=1
[ -z "$use_ipv6" ]	  && use_ipv6=0
[ -z "$force_ipversion" ] && force_ipversion=0
[ -z "$force_dnstcp" ]	  && force_dnstcp=0
[ -z "$ip_source" ]	  && ip_source="network"
[ "$ip_source" = "network" -a -z "$ip_network" -a $use_ipv6 -eq 0 ] && ip_network="wan"
[ "$ip_source" = "network" -a -z "$ip_network" -a $use_ipv6 -eq 1 ] && ip_network="wan6"
[ "$ip_source" = "web" -a -z "$ip_url" -a $use_ipv6 -eq 0 ] && ip_url="http://checkip.dyndns.com"
[ "$ip_source" = "web" -a -z "$ip_url" -a $use_ipv6 -eq 1 ] && ip_url="http://checkipv6.dyndns.com"
[ "$ip_source" = "interface" -a -z "$ip_interface" ] && ip_interface="eth1"
[ $ERR_LAST -ne 0 ] && {
	[ $VERBOSE_MODE -le 1 ] && VERBOSE_MODE=2
	[ -f $LOGFILE ] && rm -f $LOGFILE
	write_log  7 "************ ************** ************** **************"
	write_log  5 "PID '$$' started at $(eval $DATE_PROG)"
	write_log  7 "uci configuration:\n$(uci -q show ddns | grep '=service' | sort)"
	write_log 14 "Service section '$SECTION_ID' not defined"
}
write_log 7 "************ ************** ************** **************"
write_log 5 "PID '$$' started at $(eval $DATE_PROG)"
write_log 7 "uci configuration:\n$(uci -q show ddns.$SECTION_ID | sort)"
write_log 7 "ddns version  : $(opkg list-installed ddns-scripts | cut -d ' ' -f 3)"
case $VERBOSE_MODE in
	0) write_log  7 "verbose mode  : 0 - run normal, NO console output";;
	1) write_log  7 "verbose mode  : 1 - run normal, console mode";;
	2) write_log  7 "verbose mode  : 2 - run once, NO retry on error";;
	3) write_log  7 "verbose mode  : 3 - run once, NO retry on error, NOT sending update";;
	*) write_log 14 "error detecting VERBOSE_MODE '$VERBOSE_MODE'";;
esac
[ $enabled -eq 0 ] && write_log 14 "Service section disabled!"
[ -n "$service_name" ] && get_service_data update_url update_script
[ -z "$update_url" -a -z "$update_script" ] && write_log 14 "No update_url found/defined or no update_script found/defined!"
[ -n "$update_script" -a ! -f "$update_script" ] && write_log 14 "Custom update_script not found!"
[ -z "$domain" ] && write_log 14 "Service section not configured correctly! Missing 'domain'"
[ -n "$update_url" ] && {
	[ -z "$username" ] && $(echo "$update_url" | grep "\[USERNAME\]" >/dev/null 2>&1) && \
		write_log 14 "Service section not configured correctly! Missing 'username'"
	[ -z "$password" ] && $(echo "$update_url" | grep "\[PASSWORD\]" >/dev/null 2>&1) && \
		write_log 14 "Service section not configured correctly! Missing 'password'"
}
[ -n "$username" ] && urlencode URL_USER "$username"
[ -n "$password" ] && urlencode URL_PASS "$password"
if [ "$ip_source" = "script" ]; then
	set -- $ip_script	#handling script with parameters, we need a trick
	[ -z "$1" ] && write_log 14 "No script defined to detect local IP!"
	[ -x "$1" ] || write_log 14 "Script to detect local IP not executable!"
fi
get_seconds CHECK_SECONDS ${check_interval:-10} ${check_unit:-"minutes"}
get_seconds FORCE_SECONDS ${force_interval:-72} ${force_unit:-"hours"}
get_seconds RETRY_SECONDS ${retry_interval:-60} ${retry_unit:-"seconds"}
[ $CHECK_SECONDS -lt 300 ] && CHECK_SECONDS=300
[ $FORCE_SECONDS -gt 0 -a $FORCE_SECONDS -lt $CHECK_SECONDS ] && FORCE_SECONDS=$CHECK_SECONDS
write_log 7 "check interval: $CHECK_SECONDS seconds"
write_log 7 "force interval: $FORCE_SECONDS seconds"
write_log 7 "retry interval: $RETRY_SECONDS seconds"
write_log 7 "retry counter : $retry_count times"
stop_section_processes "$SECTION_ID"
[ $? -gt 0 ] && write_log 7 "'SIGTERM' was send to old process" || write_log 7 "No old process"
echo $$ > $PIDFILE
get_uptime CURR_TIME
[ -e "$UPDFILE" ] && {
	LAST_TIME=$(cat $UPDFILE)
	[ -z "$LAST_TIME" ] && LAST_TIME=0
	[ $LAST_TIME -gt $CURR_TIME ] && LAST_TIME=0
}
if [ $LAST_TIME -eq 0 ]; then
	write_log 7 "last update: never"
else
	EPOCH_TIME=$(( $(date +%s) - CURR_TIME + LAST_TIME ))
	EPOCH_TIME="date -d @$EPOCH_TIME +'$DATE_FORMAT'"
	write_log 7 "last update: $(eval $EPOCH_TIME)"
fi
[ -n "$dns_server" ] && verify_dns "$dns_server"
[ -n "$proxy" ] && {
	verify_proxy "$proxy" && {
		export HTTP_PROXY="http://$proxy"
		export HTTPS_PROXY="http://$proxy"
		export http_proxy="http://$proxy"
		export https_proxy="http://$proxy"
	}
}
get_registered_ip REGISTERED_IP "NO_RETRY"
ERR_LAST=$?
[ $ERR_LAST -eq 0 -o $ERR_LAST -eq 127 ] || get_registered_ip REGISTERED_IP
write_log 6 "Starting main loop at $(eval $DATE_PROG)"
while : ; do
	get_local_ip LOCAL_IP
	[ $FORCE_SECONDS -eq 0 -o $LAST_TIME -eq 0 ] \
		&& NEXT_TIME=0 \
		|| NEXT_TIME=$(( $LAST_TIME + $FORCE_SECONDS ))
	get_uptime CURR_TIME
	if [ $CURR_TIME -ge $NEXT_TIME -o "$LOCAL_IP" != "$REGISTERED_IP" ]; then
		if [ $VERBOSE_MODE -gt 2 ]; then
			write_log 7 "Verbose Mode: $VERBOSE_MODE - NO UPDATE send"
		elif [ "$LOCAL_IP" != "$REGISTERED_IP" ]; then
			write_log 7 "Update needed - L: '$LOCAL_IP' <> R: '$REGISTERED_IP'"
		else
			write_log 7 "Forced Update - L: '$LOCAL_IP' == R: '$REGISTERED_IP'"
		fi
		ERR_LAST=0
		[ $VERBOSE_MODE -lt 3 ] && {
			send_update "$LOCAL_IP"
			ERR_LAST=$?
		}
		if [ $ERR_LAST -eq 0 ]; then
			get_uptime LAST_TIME
			echo $LAST_TIME > $UPDFILE
			[ "$LOCAL_IP" != "$REGISTERED_IP" ] \
				&& write_log 6 "Update successful - IP '$LOCAL_IP' send" \
				|| write_log 6 "Forced update successful - IP: '$LOCAL_IP' send"
		else
			write_log 3 "Can not update IP at DDNS Provider"
		fi
	fi
	[ $VERBOSE_MODE -le 2 ] && {
		write_log 7 "Waiting $CHECK_SECONDS seconds (Check Interval)"
		sleep $CHECK_SECONDS &
		PID_SLEEP=$!
		wait $PID_SLEEP
		PID_SLEEP=0
	} || write_log 7 "Verbose Mode: $VERBOSE_MODE - NO Check Interval waiting"
	REGISTERED_IP=""
	get_registered_ip REGISTERED_IP
	if [ "$LOCAL_IP" != "$REGISTERED_IP" ]; then
		if [ $VERBOSE_MODE -le 1 ]; then
			ERR_UPDATE=$(( $ERR_UPDATE + 1 ))
			[ $retry_count -gt 0 -a $ERR_UPDATE -gt $retry_count ] && \
				write_log 14 "Updating IP at DDNS provider failed after $retry_count retries"
			write_log 4 "Updating IP at DDNS provider failed - starting retry $ERR_UPDATE/$retry_count"
			continue
		else
			write_log 4 "Updating IP at DDNS provider failed"
			write_log 7 "Verbose Mode: $VERBOSE_MODE - NO retry"; exit 1
		fi
	else
		ERR_UPDATE=0
	fi
	[ $VERBOSE_MODE -gt 1 ]  && write_log 7 "Verbose Mode: $VERBOSE_MODE - NO reloop"
	[ $FORCE_SECONDS -eq 0 ] && write_log 6 "Configured to run once"
	[ $VERBOSE_MODE -gt 1 -o $FORCE_SECONDS -eq 0 ] && exit 0
	write_log 6 "Rerun IP check at $(eval $DATE_PROG)"
done
write_log 12 "Error in 'dynamic_dns_updater.sh - program coding error"
