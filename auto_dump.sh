#!/bin/bash
#==============================================================================
# FILE: auto_dump.sh
# Version: 1.2
# CREATED: 2015/11/30 	wangyinfeng(15061252) - init
# UPDATE: 2015/12/04 	wangyinfeng(15061252) - correct the ftp server address
# UPDATE: 2015/12/22 	wangyinfeng(15061252) - take the ftp info as parameters
#                                             - check the ftp server avaliable
#                                             - check the saved directory exist
#                                             - check the curl upload file result
#                                             - check required software avaliable
#                                             - echo proper log to stdout and stderr
#                                             - clean code
# TODO
#	more check... the tcpdump start success?
#------------------------------------------------------------------------------
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
#    -a      The limitation of single dump file size.
#    -b      The ftp server address info
#------------------------------------------------------------------------------

#set -e 
#Exit immediately if a simple command exits with a non-zero status
#set -xv

trap 'stop_upload_clean_exit $NORMAL_TERMINATE' TERM INT KILL
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

error_echo(){
  builtin echo $@ >&2
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
    -a      The limitation of single dump file size.
    -b      The ftp server address info
EOF
}

EXIT_OK=0
NORMAL_TIMEOUT=0                # Task done due to time out
NORMAL_TERMINATE=0              # Task be terminated
ERROR_INVALID_PARA=101          # Task exit due to invalid parameter
ERROR_DISK_FULL=102             # Task exit due to not enough free disk space
ERROR_DUMP_FILE_TOO_LARGE=103   # Task exit due to dump file larger than 2GB
ERROR_UPLOAD_FILE=110           # Error happened when upload dump files
ERROR_FTP_NOT_AVALIABLE=111     # FTP server not avaliable
ERROR_DIR_NOT_EXIST=112         # The target directory not exist
ERROR_SW_NOT_AVALIABLE=113      # The required software not avaliable

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

    # tcpdump parameters
    # set capture_num large enough
    capture_num=100000000
    # Limit the dump file total size - 2GB default
    DUMP_FILE_SIZE_LIMIT=2000000000
    DUMP_DIR="/tmp"
    # The max disk usage - 90% default
    MAX_DISK_USAGE=90

    # FTP parameters
    #DUMP_FILE_SERVER=10.19.251.27
    #DUMP_FILE_SERVER_USER="test"
    #DUMP_FILE_SERVER_PASS="test"
    #DUMP_FILE_DIR="/tcpdump"

    DUMP_FILE_SERVER=192.168.2.104
    DUMP_FILE_SERVER_USER="ftpuser"
    DUMP_FILE_SERVER_PASS="0x2ja1O7"
    DUMP_FILE_DIR="/dump"
    
    # user specified ftp server address
    new_ftp_address=""
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

# Check the validation about required software
check_software_avaliable()
{
    # Check OS
    os=`uname`
    if [[ "$os" != *"inux" ]]
    then
        error_echo "Operation System is $os, not supported!"
        exit ERROR_SW_NOT_AVALIABLE
    fi

    # Check tcpdump
    if ! type tcpdump &> /dev/null
    then
        error_echo "tcpdump not avaliable!" 
        exit ERROR_SW_NOT_AVALIABLE
    fi

    # Check curl
    if ! type curl &> /dev/null
    then
        error_echo "curl not avaliable!" 
        exit ERROR_SW_NOT_AVALIABLE
    fi
}

check_disk_space()
{
    current_usage=$(df -k $DUMP_DIR | grep -v ^File | grep -o '[^ ]*%' | tr -d "%")
    if [ $current_usage -ge $MAX_DISK_USAGE ]
    then
        error_echo "No more free disk space! Current usage $current_usage"
        stop_upload_clean_exit $ERROR_DISK_FULL
    fi
}

check_ftp_server_avaliable()
{
    if [ "$new_ftp_address" != "" ]
    then
        curl $new_ftp_address/ &> /dev/null
    else
        curl ftp://${DUMP_FILE_SERVER_USER}:${DUMP_FILE_SERVER_PASS}@${DUMP_FILE_SERVER}${DUMP_FILE_DIR}/ &> /dev/null
    fi
    result=$?
    if [ $result -ne 0 ]
    then
        error_echo "CURL access FTP server failed! Error code $result."
        exit $ERROR_FTP_NOT_AVALIABLE
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
    if [ "${#nic_list[@]}" -le 0 ]
    then
        error_echo "No NIC is provided!"
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
        # start process on background always return 0?
        result=$?
        if [ $result -ne 0 ]
        then
            error_echo "Start tcpdump on interface $nic failed!"
        fi
        pid_to_kill+=($!)
    done
}

start_ping()
{
    debug_echo "Start ping"
:<<COMMENT
    #Save ping result to a file, the caller read it when task done
    ping_result="$DUMP_DIR/ping_result"
    if [ -f $ping_result ]
    then
        echo > $ping_result
    else
        touch $ping_result
    fi
    #ping -s $ping_size -w $ping_time $ping_target >> $ping_result &
COMMENT
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
            if [ "$new_ftp_address" != "" ]
            then
                curl -T $f -s $new_ftp_address/${DUMP_DST_FILE}
            else
                curl -T $f -s ftp://${DUMP_FILE_SERVER_USER}:${DUMP_FILE_SERVER_PASS}@${DUMP_FILE_SERVER}${DUMP_FILE_DIR}/${DUMP_DST_FILE}
            fi

            result=$?
            if [ $result -ne 0 ]
            then
                error_echo "CURL upload file failed! Error code $result." 
            else
                [ "$new_ftp_address" != "" ] && echo "FILE:$new_ftp_address/${DUMP_DST_FILE}" || echo "FILE:ftp://${DUMP_FILE_SERVER_USER}:${DUMP_FILE_SERVER_PASS}@${DUMP_FILE_SERVER}${DUMP_FILE_DIR}/${DUMP_DST_FILE}"
            fi
        done
    else
        error_echo "No dump files saved."
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
        error_echo "No dump files saved."
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

    echo "===========Task done============"
    # kill all child processes
    if [ "${#pid_to_kill[@]}" -gt 0 ]
    then
        for p in ${pid_to_kill[@]}
        do
            debug_echo "going to kill pid $p"
            kill $p &> /dev/null
            # double check the child process, make sure exit
            ps -p $p &> /dev/null
            result=$?
            if [ $result -eq 0 ]
            then
                kill -9 $p &> /dev/null
                # give kill some time to done it's job
                sleep 0.1
                # if not able to kill the process, log the result to let user know
                ps -p $p &> /dev/null
                result=$?
                [ $result -eq 0 ] && error_echo "Terminate process $p failed!!!"
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
    [ "$time_para_exist" == "false" ] && error_echo "dump time -w parameter is mandatory" && exit $ERROR_INVALID_PARA
    [ "$dir_para_exist" == "false" ] && error_echo "dump dir -d parameter is mandatory" && exit $ERROR_INVALID_PARA
    [ "$nic_para_exist" == "false" ] && error_echo "NIC device -n parameter is mandatory" && exit $ERROR_INVALID_PARA
    [ "$dst_para_exist" == "false" ] && error_echo "target address -o parameter is mandatory" && exit $ERROR_INVALID_PARA

    # check file saved directory exist or not
    if [ ! -d $DUMP_DIR ]
    then
        error_echo "The target directory $DUMP_DIR not exist!"
        exit $ERROR_DIR_NOT_EXIST
    fi
}

check_software_avaliable
parameter_init

while getopts ":s:w:c:n:d:f:o:a:b:h" OPT; do
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
        a)
            dump_file_size_in_mb=${OPTARG}
            ((DUMP_FILE_SIZE_LIMIT=dump_file_size_in_mb*1000000))
            ;;
        b)
            new_ftp_address=${OPTARG}
            ;;
        \?|*) 
            usage; error_echo "Unknown option: -$OPTARG"; exit $ERROR_INVALID_PARA
            ;;
        :)
            error_echo "Option -$OPTARG requires an argument."; exit $ERROR_INVALID_PARA
            ;;
    esac
done

mandatory_para_check
check_ftp_server_avaliable

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
exit $EXIT_OK

