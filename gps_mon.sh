#!/bin/env ksh

## Program	gps_mon.sh
## Purpose	Used to GPS(GetPutservice) monitor through the manage port with telnet
## Usage	gps_mon.sh -f <GPS server list> [-m <mail configuration>] [-v]
## Version	1.0
## Author	Wei.Shen(rekcah865@gmail.com)
##
## Revision history
##	Wei.Shen	v1.0	Mar 3 2016	Creation
##

## Verbose 0 - Off, 1 - On
VERBOSE=0

function Usage { 
	echo  -e "\nERROR! Usage: ${0##*/} -f [GPS Machine List File] -m [Mail configuration] -v\n"
}
function vecho {
	[[ $VERBOSE -eq 1 ]] && echo -e "$*"
}

######### Parameter define ################
while getopts f:m:v next; do
	case $next in
		f) CONFIG=$OPTARG ;;
		m) MAILF=$OPTARG ;;
		v) VERBOSE=1 ;;
		*) Usage ;;
	esac
done

PP=$(cd $(dirname $0) && pwd)
PN=$(basename $0 ".sh")
TMP=$PP/$PN.tmp
MAIL_FLAG=0

## Check command
BINS=(telnet cat mailx mknod ps exec)
for BIN in "${BINS[@]}" ; do
	[[ ! "$(command -v "$BIN")" ]] && echo "$BIN is required. Exit.." && exit 1
done

## Check configuration file
if [[ ! -f $CONFIG ]]; then
	if [[ ! -f $PP/$CONFIG ]]; then
		echo "Configuration File Required. Exit.."
		Usage
		exit 1
	else
		IP_LIST=$PP/$CONFIG
	fi
else
	IP_LIST=$CONFIG
fi

## Check mail configuration file
if [[ ! -f $MAILF ]]; then
	if [[ -f $PP/$MAILF ]]; then
		MAIL_CONFIG=$PP/$MAILF
		MAIL_FLAG=1
	fi
else
	MAIL_CONFIG=$MAILF
	MAIL_FLAG=1
fi

## Mail information
if [[ ${MAIL_FLAG} == 1 ]]; then
	MAIL_SENDER=$(awk -F ' * = *' '$1=="mail_sender"{print $2}' ${MAIL_CONFIG})
	MAIL_RECEIVER=$(awk -F ' * = *' '$1=="mail_receiver"{print $2}' ${MAIL_CONFIG})
	MAIL_SUBJECT=$(awk -F ' * = *' '$1=="mail_subject"{print $2}' ${MAIL_CONFIG})
	if [[ ${MAIL_SENDER} == "" || ${MAIL_RECEIVER} == "" || ${MAIL_SUBJECT} == "" ]]; then
		echo "Some of mail configuration is missed in ${MAIL_CONFIG}"
		MAIL_FLAG=0
	fi
	MAIL_FILE=$PP/$PN.mail
fi

## GPS PORT
PORT=2916
## GPS failure list
FGPS=$PP/$PN.f 
cat /dev/null > $FGPS
## 3 pipe for automatic telnet
IN=$PP/$PN.in
OUT=$PP/$PN.out
ERR=$PP/$PN.err
	
## Loop the configuration list content
while read NAME IP; do
	## check ping status
	ping -c 1 -W 2 $IP >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		#[[ $VERBOSE -eq 1 ]] && echo "Ping $NAME($IP) failed. Skip it." && continue
		vecho "ping $NAME($IP) failed. Skip it." && continue
	fi
	## Check previous command status
	if [[ ! -z $(ps -ef|grep "telnet $IP $PORT"|grep -v grep) ]]; then
		vecho "Found previous command for $IP $PORT"
		ps -ef|grep "telnet $IP $PORT"|grep -v grep
		## kill it
		PID=$(ps -ef|grep "telnet $IP $PORT"|grep -v grep|awk '{printf $2" "}')
		vecho "kill process PID = $PID"
		echo $PID|xargs kill -9
		
		## Remove pip file for last time
		[[ -p $IN.$IP ]] && rm $IN.$IP 
		[[ -f $OUT.$IP ]] && rm $OUT.$IP
		[[ -f $ERR.$IP ]] && rm $ERR.$IP
		[[ -f $TMP.$IP ]] && rm $TMP.$IP
	fi	

	## Create pipe for in(7), out(8) and err(9)
	mknod $IN.$IP p
	touch $OUT.$IP $ERR.$IP
	exec 7<> $OUT.$IP
	exec 8<> $IN.$IP
	exec 9<> $ERR.$IP
	## execute telnet command using pipe
	telnet $IP $PORT <&8 >&7 2>&9 &
	sleep 1 >> $IN.$IP
	echo bye >> $IN.$IP
	sleep 1
	[[ -f $OUT.$IP ]] && cat $OUT.$IP >> $TMP.$IP
	[[ -f $ERR.$IP ]] && cat $ERR.$IP >> $TMP.$IP
		
	## Get GPS status	
	if [[ ! -z $(cat $TMP.$IP|grep "Connection closed") ]] ; then
		## Get GPS version
		VER=$(cat $OUT.$IP|grep "FIS GetPutServer"|sed 's/FIS GetPutServer Rev. //g')
		vecho "telnet $NAME($IP) $PORT successful (GetPutServer Version = $VER)"
	elif [[ ! -z $(cat $TMP.$IP|grep "Connection refused") ]]; then
		echo "$NAME - $IP" >> $FGPS
		vecho "telnet $NAME($IP) $PORT failed"
	else
		echo "unknown status for $NAME - $IP"
	fi
	
	## Remove pipe file
	[[ -p $IN.$IP ]] && rm $IN.$IP 
	[[ -f $OUT.$IP ]] && rm $OUT.$IP
	[[ -f $ERR.$IP ]] && rm $ERR.$IP
	[[ -f $TMP.$IP ]] && rm $TMP.$IP
	
done < <(cat ${IP_LIST}|grep -v ^#|sed '/^$/d')

## Check GPS status and mail alert
if [[ -s $FGPS ]]; then
	vecho "Found $(cat $FGPS|wc -l) servers telnet $PORT failure"
	echo -e "The GetPutService of below server were abnormal \n================\n" >${MAIL_FILE}
	[[ -f $FGPS ]] && cat $FGPS >> ${MAIL_FILE} && rm $FGPS	
fi

## Mail alert
if [[ ${MAIL_FLAG} -eq 1 && -f ${MAIL_FILE} ]]; then
	vecho "Send GPS failure list to ${MAIL_RECEIVER}"
	cat ${MAIL_FILE} |mailx -r ${MAIL_SENDER} -s "${MAIL_SUBJECT}" "${MAIL_RECEIVER}"	
fi

[[ -f ${MAIL_FILE} ]] && rm ${MAIL_FILE}
[[ -f $TMP ]] && rm $TMP
[[ -f $FGPS ]] && rm $FGPS

## End
