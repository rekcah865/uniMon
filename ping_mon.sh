#!/bin/env ksh

## Program	ping_mon.sh
## Purpose	Used to ping server monitor
## Usage	ping_mon.sh -f <server list file> [-m <mail configuration>] [-v]
## Version	1.0
## Author	Wei.Shen(rekcah865@gmail.com)
##
## Revision history
##	Wei.Shen	v1.0	Mar 1 2016	Creation
##

## Verbose 0 - Off, 1 - On
VERBOSE=0

function Usage { 
	echo  -e "\nERROR! Usage: ${0##*/} -f [Machine List Configuration File] -m [Mail configuration] -v\n"
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
VER=1.0
TMP=$PP/$PN.tmp
MAIL_FLAG=0

## Check command
BINS=(ping cat mailx)
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

## Loop the configuration list content
while read NAME IP; do
	## execute ping command
	ping -c 1 -W 3 $IP > $TMP.$IP 2>&1
	
	S=$(cat $TMP.$IP |grep "1 received"|wc -l)
	
	if [ $S -eq 1 ]; then
		[[ $VERBOSE -eq 1 ]] && echo "$(date "+%Y-%m-%d %H:%M:%S") $NAME($IP) is Up" 
	else
		[[ $VERBOSE -eq 1 ]] && echo "$(date "+%Y-%m-%d %H:%M:%S") $NAME($IP) Down"
		echo "$(date "+%Y-%m-%d %H:%M:%S") $NAME($IP) Down" >> ${MAIL_FILE}
	fi
	[[ -f $TMP.$IP ]] && rm $TMP.$IP
	
done < <(cat ${IP_LIST}|grep -v ^#|sed '/^$/d')

## Mail alert
if [[ ${MAIL_FLAG} -eq 1 && -f ${MAIL_FILE} ]]; then
	[[ $VERBOSE -eq 1 ]] && echo "Send ping failure list to ${MAIL_RECEIVER}"
	cat ${MAIL_FILE} |mailx -r ${MAIL_SENDER} -s "${MAIL_SUBJECT}" "${MAIL_RECEIVER}"	
fi
[[ -f ${MAIL_FILE} ]] && rm ${MAIL_FILE}


## End
