#!/bin/bash
# TODO  -o/-w should be mandatory parameter
#       echo ping result to caller
#       upload file to server
#       parameter to tcpdump
#       dump file saved dir should comes from caller parameter
#       enbale debug module, if debug echo...

#sh pid.sh -w 10 -n eth1,eth3 -d "/tmp" -o 10.27.248.3

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
    -p      Protocol type.
    -a      Source port number.
    -b      Destination port number.
    -n      NIC list to capture.
    -o      The ping target IP address.
    -d      Dump file save directory.
EOF
}

NORMAL_TIMEOUT=1
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

    run_time=0

    declare -a pid_to_kill=()
    declare -a nic_list=()

    #tcpdump parameters
    #DUMP_FILE_SIZE_LIMIT=2000000000
    DUMP_FILE_SIZE_LIMIT=6000
    DUMP_DIR="/tmp"

    MAX_DISK_USAGE=90
}

check_disk_space()
{
    current_usage=$(df -k /tmp | tail -1 | awk '{print $4}' | tr -d "%")
    if [ $current_usage -ge $MAX_DISK_USAGE ]
    then
        echo "No more free disk space!"
        stop_all $ERROR_DISK_FULL
    fi
}

start_dump()
{
    # -C file_size, unit is MB
    #tcpdump -i $NIC $PROTO -w a.pcap -C 1 -W 1 -w $DUMP_FILE > /dev/null &
    if [ ${#nic_list[@]} -le 0 ]
    then
        stop_all $ERROR_INVALID_PARA
    fi

    for nic in ${nic_list[@]}
    do
        DUMP_FILE="$DUMP_DIR/tcpdump_`hostname`-$nic-`date +%Y%m%d%H%M%S`.pcap"
        if [ -f $DUMP_FILE ]
        then
            rm -f $DUMP_FILE
        fi
        touch $DUMP_FILE

        tcpdump -i $nic $protocol -w $DUMP_FILE > /dev/null &
        pid_to_kill+=($!)
    done
}

start_ping()
{
    #ping -i 0.1 -s $ping_size -w $ping_time $ping_target> /dev/null &
    ping -s $ping_size -w $ping_time $ping_target > /dev/null &
    pid_to_kill+=($!)
}

#echo `pidof ping`
#pgrep ping

# upload the $DUMP_FILE to the specified ftp server
upload_dump()
{
    echo "uploading files"
}

stop_all()
{
    error_code=$1
#    kill $ping_pid > /dev/null
    if [ "${#pid_to_kill[@]}" -gt 0 ]
    then
        for p in ${pid_to_kill[@]}
        do
            echo "going to kill pid $p"
            kill $p > /dev/null
        done
    fi
    
    upload_dump
    exit $error_code
}

parameter_init

while getopts ":s:w:c:p:a:b:d:n:o:" OPT; do
    case "$OPT" in
        s)
            ping_size=${OPTARG}
            ;;
        w)
            ping_time=${OPTARG}
            ;;
        c)
            capture_num=${OPTARG}
            ;;
        p)
            protocol=${OPTARG}
            ;;
        a)
            src_port=${OPTARG}
            ;;
        b)
            dst_port=${OPTARG}
            ;;
        d)
            DUMP_DIR=${OPTARG}
            ;;
        n)
            NIC_STR=${OPTARG}
            ;;
        o)
            ping_target=${OPTARG}
            ;;
        *)
            usage; exit $ERROR_INVALID_PARA
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            ;;
    esac
    #shift
done

oIFS=$IFS
IFS=', '
# The NIC name got by parameter -n eth0,eth1
# "eth0,eth1"
read -ra nic_list <<< "$NIC_STR"
IFS=$oIFS

for i in ${nic_list[@])}
do
   echo $i 
done

# Start tcpdump before ping
start_dump
start_ping

while :
do
    check_disk_space

    DUMP_FILE_SIZE=$(stat -c%s "$DUMP_FILE")
    if [ $DUMP_FILE_SIZE -gt $DUMP_FILE_SIZE_LIMIT ]
    then
        stop_all $ERROR_DUMP_FILE_TOO_LARGE
    else
        ((rum_time++))
        if [ $rum_time -gt $ping_time ]
        then
            stop_all $NORMAL_TIMEOUT
        else
            sleep 1
        fi
    fi
done

upload_dump
exit 0
