#!/bin/bash
#Check the device OS/Kernel/CPU/Mem/MsgQue...
#===========================================================
#TODO:
#===========================================================
#update log:
#2013.08.23 better look
#===========================================================

LOG=syscheck.log
log()
{
#    echo `date`:$* | tee -a ${LOG}
    echo $* | tee -a ${LOG}
}

log "`date`"
log "========Check device basic information begin========"

if [ -f /etc/SuSE-release ]
then
    LINUX_TYPE=SUSE
elif [ -f /etc/redhat-release ]
then
    LINUX_TYPE=REDHAT
elif [ -f /etc/centos-release ]
then
    LINUX_TYPE=CENTOS
else
    LINUX_TYPE=UNKNOW
fi

#/proc/sys/kernel/ostype       - get OS type
#/proc/sys/kernel/osrelease    - get kernel version
#/proc/sys/kernel/version      - get OS revision

# OS
log " Kernel info: `uname -a`"
log " OS info: `lsb_release -a`"
log " OS bits: `getconf LONG_BIT`"

# CPU
log " Logic CPU number = physical CPU number x CPU cores per CPU chip x Hyper-Thread number"
log " CPU info: `cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c`"
log " CPU chip number: `cat /proc/cpuinfo  | grep "physical id" | sort| uniq |wc -l`"
log " CPU physical cores: `cat /proc/cpuinfo  | grep "core id" | sort| uniq |wc -l`"
log " CPU physical cores: `cat /proc/cpuinfo |grep "cores"|uniq`"
log " CPU logic cores: `cat /proc/cpuinfo |grep "processor"|wc -l` "
log " Detailed CPU info: `lscpu`"

log " Kernel.msg para: msgmax-`sysctl -n kernel.msgmax` msgmnb-`sysctl -n kernel.msgmnb` msgmni-`sysctl -n kernel.msgmni`"
log " Socket.wmem buffer: wmem_max `cat /proc/sys/net/core/wmem_max` wmem_default `cat /proc/sys/net/core/wmem_default`"
log " Library setting:`echo $LD_LIBRARY_PATH`"
log " Up time: "`awk '{printf("%d Day:%02d Hour:%02d Min:%02d Sec",($1/60/60/24),($1/60/60%24),($1/60%60),($1%60))}' /proc/uptime`
log "========Check device basic information end========"
