#!/bin/sh
#monitor the device disk/mem/cpu usage
#======================================================================
#update log:
#2013.08.23 better look
#======================================================================

LOG_FILE=sysmoni.log

log()
{
 echo `date`:$* | tee -a $LOG_FILE
}

diskuse=`df -h|grep "/dev/sda*"|awk '{print $5}'`
totalmem=`free|grep Mem|awk '{print $2}'`
re=`vmstat | egrep [0-9]`
set -- $re
memuse=$[ $totalmem - $3 - $4 - $5 - $6 ]
((memuse=memuse*100/totalmem))
memuse="${memuse}%"
cpuuse=$[ 100 - ${15} ]
cpuuse="${cpuuse}%"
log "============================================"
printf "disk usage:\t%s\n" "$diskuse" | tee -a $LOG_FILE
printf "memory usage:\t%s\n" "$memuse" | tee -a $LOG_FILE
printf "cpu usage:\t%s\n" "$cpuuse" | tee -a $LOG_FILE
