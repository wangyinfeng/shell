#!/bin/bash
#==================================================
# FILE: auto_dump.sh
# Version: 1.0
# CREATED: 2015/11/30   wangyinfeng(15061252)
# UPDATE: 2015/12/02    wangyinfeng(15061252)
# DESCRIPTION: script for network traffic analysis
# PARAMETER: 
#    -h      Help info.
#    -s      Ping packet size, in byte.
#    -w      Capture timeout, in seconds. Mandatory.
#    -c      Capture packet number. 
#    -n      NIC list to capture. Mandatory.
#    -f      Dump filter sting. Mandatory.
#    -o      The ping target IP address. Mandatory.
#    -d      Dump file save directory. Mandatory.
#--------------------------------------------------
#set -e 
#Exit immediately if a simple command exits with a non-zero status
#set -xv

trap 'stop_upload_clean_exit $NORMAL_TERMINATE' TERM INT KILL

# TODO
#       more check... the tcpdump start success?

# ping and tcpdump are child process of the task script, terminate the script will 
# terminate all child process also. Then use trap to do cleanup jobs.

#caller do
#sh x.sh -w 10 -n eth1,eth3 -c 100 -s 1000 -f "icmp or tcp and ( host 10.27.248.252 or host 10.27.248.3 ) and ( port 55854 or port 5903 )" -d "/tmp" -o 10.27.248.3
#I do
#ping -s 1000 -w 10 10.27.248.3
#tcpdump -i eth1 -c 100 icmp or tcp and (host 10.27.248.252 or host 10.27.248.3) and (port 55854 or port 5903) -w /tmp/file.pcap
#tcpdump -i eth3 -c 100 icmp or tcp and (host 10.27.248.252 or host 10.27.248.3) and (port 55854 or port 5903) -w /tmp/file.pcap

#Require all parameters are lowcase!
#When caller want to stop the task, send SIGTERM, eg. kill -s 15 <PID>

#DEBUG=true
DEBUG=false
debug_echo(){
  [[ "$DEBUG" == true ]] && builtin echo $@
}

usage()
{
cat << EOF
usage: $0 options

This script run the ping command and do tcpdump.

OPTIONS:
    -h      Help info.
    -s      Ping packet size, in byte.
    -w      Capture timeout, in seconds. Mandatory.
    -c      Capture packet number. 
    -n      NIC list to capture. Mandatory.
    -f      Dump filter sting. Mandatory.
    -o      The ping target IP address. Mandatory.
    -d      Dump file save directory. Mandatory.
EOF
}

EXIT_OK=0
NORMAL_TIMEOUT=0                # Task done due to time out
NORMAL_TERMINATE=0               # Task be terminated
ERROR_INVALID_PARA=101          # Task exit due to invalid parameter
ERROR_DISK_FULL=102             # Task exit due to not enough free disk space
ERROR_DUMP_FILE_TOO_LARGE=103   # Task exit due to dump file larger than 2GB
ERROR_UPLOAD_FILE=110           # Error happened when upload dump files

parameter_init()
{
    my_pid=$$
    #my_ppid=$PPID
    my_ppid=`ps -o ppid $my_pid | grep -v PPID`
    my_name=`basename $0`

    #default ping parameters' value
    ping_size=56
    ping_time=10
    protocol=icmp
    ping_target=localhost
    # set capture_num large enough
    #capture_num=31250000
    capture_num=100000000

    # mandatory parameters
    time_para_exist=false
    dir_para_exist=false
    dst_para_exist=false
    nic_para_exist=false

    run_time=0
    dump_file_total_size=0
    dump_file_upload_result=0

    declare -a pid_to_kill=()
    declare -a nic_list=()
    declare -a dump_file_list=()

    #tcpdump parameters
    #Limit the dump file total size
    #DUMP_FILE_SIZE_LIMIT=2000000000
    DUMP_FILE_SIZE_LIMIT=600000000
    DUMP_DIR="/tmp"

    MAX_DISK_USAGE=90

    # FTP parameters
    DUMP_FILE_SERVER=10.19.251.27
    DUMP_FILE_SERVER_USER="test"
    DUMP_FILE_SERVER_PASS="test"
    DUMP_FILE_DIR="/tcpdump"
}

hack_to_terminate()
{
    # check the ppid exist or not, if ppid was terminated...
    ps -p $my_ppid  &> /dev/null
    # ppid not exist
    if [ $? -ne 0 ]
    then
        if [ $my_ppid -gt 1 ]
        then
            stop_upload_clean_exit $NORMAL_TERMINATE
        fi
    #else ppid exist, continue running...
    fi
}

save_my_pid()
{
    pid_file="$DUMP_DIR/$my_name.pid"
    if [ ! -f $pid_file ]
    then
        touch $pid_file
    fi
    echo $my_pid > $pid_file
}

check_disk_space()
{
    current_usage=$(df -k $DUMP_DIR | grep -v ^File | grep -o '[^ ]*%' | tr -d "%")
    if [ $current_usage -ge $MAX_DISK_USAGE ]
    then
        debug_echo "No more free disk space! Current usage $current_usage" >&2
        stop_upload_clean_exit $ERROR_DISK_FULL
    fi
}

get_dump_file_totoal_size()
{
    dump_file_total_size=0
    if [ "${#dump_file_list[@]}" -gt 0 ]
    then
        for f in ${dump_file_list[@]}
        do
            dump_file_size=$(stat -c%s "$f")
            ((dump_file_total_size += dump_file_size))
        done
    fi
    debug_echo "Total dump file size: $dump_file_total_size"
}

start_dump()
{
    # -C file_size, unit is MB
    #tcpdump -i $NIC $PROTO -w a.pcap -C 1 -W 1 -w $dump_file > /dev/null &
    if [ "${#nic_list[@]}" -le 0 ]
    then
        debug_echo "No NIC is provided!" >&2
        stop_upload_clean_exit $ERROR_INVALID_PARA
    fi

    for nic in ${nic_list[@]}
    do
        dump_file="$DUMP_DIR/tcpdump_`hostname`-$nic-`date +%Y%m%d%H%M%S`.pcap"
        if [ -f $dump_file ]
        then
            rm -f $dump_file
        fi
        touch $dump_file
        dump_file_list+=($dump_file)

        debug_echo "Start tcpdump for NIC: $nic"
        tcpdump -i $nic -c $capture_num $DUMP_FILTER_STR -w $dump_file &> /dev/null &
        pid_to_kill+=($!)
    done
}

start_ping()
{
    debug_echo "Start ping"
    #Save ping result to a file, the caller read it when task done
    ping_result="$DUMP_DIR/ping_result"
    if [ -f $ping_result ]
    then
        echo > $ping_result
    else
        touch $ping_result
    fi
    #ping -s $ping_size -w $ping_time $ping_target >> $ping_result &
    # PCP will capture the stdout & stderr, user can check the ping result in the log
    ping -s $ping_size -w $ping_time $ping_target &
    pid_to_kill+=($!)
}

# upload the dump file to the specified ftp server by curl
curl_upload_dump()
{
    if [ "${#dump_file_list[@]}" -gt 0 ]
    then
        for f in ${dump_file_list[@]}
        do
            debug_echo "uploading file $f"
            DUMP_DST_FILE=`basename $f`
            curl -T $f -s ftp://${DUMP_FILE_SERVER_USER}:${DUMP_FILE_SERVER_PASS}@${DUMP_FILE_SERVER}${DUMP_FILE_DIR}/${DUMP_DST_FILE}
            # need to verify upload success or fail?
            dump_file_upload_result=$?
        done
    else
        debug_echo "No dump files saved." >&2
    fi
}

# upload the dump file to the specified ftp server by ftp
ftp_upload_dump()
{
    if [ "${#dump_file_list[@]}" -gt 0 ]
    then
        for f in ${dump_file_list[@]}
        do
            debug_echo "uploading file $f"
            DUMP_DST_FILE=`basename $f`
# upload all files by once is more efficient
ftp -v -n $DUMP_FILE_SERVER <<END_SCRIPT
quote USER $DUMP_FILE_SERVER_USER
quote PASS $DUMP_FILE_SERVER_PASS
cd $DUMP_FILE_DIR
binary
put ${f} ${DUMP_DST_FILE}
bye
END_SCRIPT
        done
    else
        debug_echo "No dump files saved."
    fi
}

remove_dump()
{
    if [ "${#dump_file_list[@]}" -gt 0 ]
    then
        for f in ${dump_file_list[@]}
        do
            if [ -f $f ]
            then
                debug_echo "Remove dump file $f"
                rm -f $f
            fi
        done
    fi
}

stop_upload_clean_exit()
{
    error_code=$1

    echo "======Task done======"
    # kill all child processes
    if [ "${#pid_to_kill[@]}" -gt 0 ]
    then
        for p in ${pid_to_kill[@]}
        do
            echo "going to kill pid $p"
            kill $p &> /dev/null
            # double check the child process, make sure exit
            if ! ps -p $p &> /dev/null 
            then
                kill -9 $p &> /dev/null
            fi
        done
    fi
    
    # delay to wait dump file write back to disk
    sleep 1

    # upload saved files
    #ftp_upload_dump
    curl_upload_dump
    # remove all temp files
    remove_dump

    # then exit
    exit $error_code
}

mandatory_para_check()
{
    [ "$time_para_exist" == "false" ] && debug_echo "dump time -w parameter is mandatory" && exit $ERROR_INVALID_PARA
    [ "$dir_para_exist" == "false" ] && debug_echo "dump dir -d parameter is mandatory" && exit $ERROR_INVALID_PARA
    [ "$nic_para_exist" == "false" ] && debug_echo "NIC device -n parameter is mandatory" && exit $ERROR_INVALID_PARA
    [ "$dst_para_exist" == "false" ] && debug_echo "target address -o parameter is mandatory" && exit $ERROR_INVALID_PARA

}

parameter_init

while getopts ":s:w:c:n:d:f:o:h" OPT; do
    case "$OPT" in
        h)
            usage
            exit $EXIT_OK
            ;;
        s)
            ping_size=${OPTARG}
            ;;
        w)
            ping_time=${OPTARG}
            time_para_exist=true
            ;;
        c)
            capture_num=${OPTARG}
            ;;
        d)
            DUMP_DIR=${OPTARG}
            dir_para_exist=true
            ;;
        n)
            NIC_STR=${OPTARG}
            nic_para_exist=true
            ;;
        f)
            DUMP_FILTER_STR=${OPTARG}
            ;;
        o)
            ping_target=${OPTARG}
            dst_para_exist=true
            ;;
        \?|*) 
            usage; debug_echo "Unknown option: -$OPTARG" >&2; exit $ERROR_INVALID_PARA
            ;;
        :)
            debug_echo "Option -$OPTARG requires an argument." >&2
            ;;
    esac
done

mandatory_para_check

oIFS=$IFS
IFS=', '
# The NIC name got by parameter -n eth0,eth1
# save NIC device to the list
read -ra nic_list <<< "$NIC_STR"
IFS=$oIFS

# Salt is able to return the script pid, no need to save to file.
#save_my_pid
# Start tcpdump before ping
start_dump
# if ping test or specify protocol is icmp or all, do ping
#if [[ $DUMP_FILTER_STR =~ icmp ]] || [[ $DUMP_FILTER_STR =~ all ]] 
#then
#    start_ping
#fi
#start ping anyway
start_ping

while :
do
    check_disk_space

    get_dump_file_totoal_size

    if [ $dump_file_total_size -gt $DUMP_FILE_SIZE_LIMIT ]
    then
        stop_upload_clean_exit $ERROR_DUMP_FILE_TOO_LARGE
    else
        ((rum_time++))
        if [ $rum_time -gt $ping_time ]
        then
            stop_upload_clean_exit $NORMAL_TIMEOUT
        else
            sleep 1
            # Because PCP send kill is killing the salt itself, instead of 
            # kill the task which was called by the salt, so monitor the
            # salt process, if the father process exit, suicide itself.

            # salt fix the issue
            # hack_to_terminate
        fi
    fi
done

# Should never come here!
#ftp_upload_dump
curl_upload_dump
remove_dump
exit $EXIT_OK

