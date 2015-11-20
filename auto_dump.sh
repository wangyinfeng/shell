#!/bin/bash
#set -e 
#Exit immediately if a simple command exits with a non-zero status
#set -xv

trap 'stop_upload_clean_exit $ERROR_TERMINATE' TERM INT

# TODO  -o/-w should be mandatory parameter
#       echo ping result to caller
#       upload file to server

# ping and tcpdump are child process of the task script, terminate the script will 
# terminate all child process also. Then use trap to do cleanup jobs.

#tcpdump for ping
#caller do 
#sh x.sh -s 100 -w 10 -n eth0,eth1 -f "icmp" -d "/tmp" -o 10.27.248.3
#I do
#ping -s 100 -w 10 10.27.248.3
#tcpdump -i eth0 icmp -w /tmp/file.pcap
#tcpdump -i eth1 icmp -w /tmp/file.pcap

#tcpdump for other
#caller do
#sh x.sh -w 10 -n eth1,eth3 -c 100 -f "tcp and ( host 10.27.248.252 or host 10.27.248.3 ) and ( port 55854 or port 5903 )" -d "/tmp" -o 10.27.248.3
#I do
#ping -s DEFAULT -w 10 10.27.248.3
#tcpdump -i eth1 -c 100 tcp and (host 10.27.248.252 or host 10.27.248.3) and (port 55854 or port 5903) -w /tmp/file.pcap
#tcpdump -i eth3 -c 100 tcp and (host 10.27.248.252 or host 10.27.248.3) and (port 55854 or port 5903) -w /tmp/file.pcap

#When caller want to stop the task, send SIGTERM

DEBUG=true
#DEBUG=false
echo(){
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
    -w      Capture timeout, in seconds.
    -c      Capture packet number.
    -n      NIC list to capture.
    -f      Dump filter sting.
    -o      The ping target IP address.
    -d      Dump file save directory.
EOF
}

EXIT_OK=0
NORMAL_TIMEOUT=1
ERROR_TERMINATE=100
ERROR_INVALID_PARA=101
ERROR_DISK_FULL=102
ERROR_DUMP_FILE_TOO_LARGE=103

parameter_init()
{
    #default ping parameters' value
    ping_size=56
    ping_time=10
    protocol=icmp
    ping_target=localhost
    # set capture_num large enough
    #capture_num=31250000
    capture_num=100000000

    time_para_exist=false
    dir_para_exist=false
    dst_para_exist=false
    nic_para_exist=false

    run_time=0
    dump_file_total_size=0

    declare -a pid_to_kill=()
    declare -a nic_list=()
    declare -a dump_file_list=()

    #tcpdump parameters
    #Limit the dump file total size
    #DUMP_FILE_SIZE_LIMIT=2000000000
    DUMP_FILE_SIZE_LIMIT=60000
    DUMP_DIR="/tmp"

    MAX_DISK_USAGE=90
}

check_disk_space()
{
    current_usage=$(df -k /tmp | tail -1 | awk '{print $4}' | tr -d "%")
    if [ $current_usage -ge $MAX_DISK_USAGE ]
    then
        echo "No more free disk space!"
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
    echo "Total dump file size: $dump_file_total_size"
}

start_dump()
{
    # -C file_size, unit is MB
    #tcpdump -i $NIC $PROTO -w a.pcap -C 1 -W 1 -w $dump_file > /dev/null &
    if [ ${#nic_list[@]} -le 0 ]
    then
        echo "No NIC is provided!"
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

        echo "Start tcpdump for NIC: $nic"
        tcpdump -i $nic -c $capture_num $DUMP_FILTER_STR -w $dump_file &> /dev/null &
        pid_to_kill+=($!)
    done
}

start_ping()
{
    #ping -i 0.1 -s $ping_size -w $ping_time $ping_target> /dev/null &
    echo "Start ping"
    ping -s $ping_size -w $ping_time $ping_target &> /dev/null &
    pid_to_kill+=($!)
}

# upload the dump file to the specified ftp server
upload_dump()
{
    if [ "${#dump_file_list[@]}" -gt 0 ]
    then
        for f in ${dump_file_list[@]}
        do
            echo "uploading file $f"
            cp $f /tmp/abc/
        done
    else
        echo "No dump files saved."
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
                echo "Remove dump file $f"
                rm -f $f
            fi
        done
    fi
}

stop_upload_clean_exit()
{
    error_code=$1

    # kill all child processes
    if [ "${#pid_to_kill[@]}" -gt 0 ]
    then
        for p in ${pid_to_kill[@]}
        do
            echo "going to kill pid $p"
            kill $p &> /dev/null
            # TODO need verify
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
    upload_dump
    # remove all temp files
    #remove_dump

    # then exit
    exit $error_code
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
            usage; echo "Unknown option: -$OPTARG" >&2; exit $ERROR_INVALID_PARA
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            ;;
    esac
done

oIFS=$IFS
IFS=', '
# The NIC name got by parameter -n eth0,eth1
# "eth0,eth1"
read -ra nic_list <<< "$NIC_STR"
IFS=$oIFS

#for i in ${nic_list[@])}
#do
#   echo $i 
#done

# Start tcpdump before ping
start_dump
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
            #date
            sleep 1
        fi
    fi
done

upload_dump
exit 0

