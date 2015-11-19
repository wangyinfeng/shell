#!/bin/bash

#Currently support parameter:
#  -s ping packet size
#  -w ping timeout

pin_usage()
{
cat << EOF
usage: $0 options

This script run the ping command.

OPTIONS:
   -h      Help info.
   -s      Specifies the number of data bytes to be sent.
   -w      Specify a timeout, in seconds.
EOF
}

parameter_init()
{
    #default ping parameters' value
    ping_size=56
    ping_time=10
    ping_target=localhost

    #tcpdump parameters
    #DUMP_FILE_SIZE_LIMIT=2000000000
    DUMP_FILE_SIZE_LIMIT=6000
    #NIC=eth0
    NIC=any
    PROTO=
    DUMP_FILE="/tmp/tcpdump_`hostname`-$NIC-`date +%Y%m%d%H%M%S`.pcap"
}

parameter_init

while getopts ":s:w:o:" OPT; do
    case "$OPT" in
        s)
            ping_size=${OPTARG}
            ;;
        w)
            ping_time=${OPTARG}
            ;;
        o)
            ping_target=${OPTARG}
            ;;
        *)
            echo "Invalid parameter. Exit"; ping_usage; exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            ;;
    esac
#    shift
done


# Start tcpdump before ping
# -C file_size, unit is MB
#tcpdump -i $NIC $PROTO -w a.pcap -C 1 -W 1 -w $DUMP_FILE > /dev/null &
touch $DUMP_FILE
tcpdump -i $NIC $PROTO -w $DUMP_FILE > /dev/null &
dump_pid=$!
echo "tcpdump pid $dump_pid"

# lanuch ping and get the ping's pid
ping -s $ping_size -w $ping_time $ping_target> /dev/null &
ping_pid=$!
echo "ping pid $ping_pid"

#echo `pidof ping`
#pgrep ping

# upload the $DUMP_FILE to the specified ftp server
upload_dump()
{
    :
}

stop_all()
{
    kill $ping_pid > /dev/null
    kill $dump_pid > /dev/null
    
    upload_dump
    exit 101
}

while :
do
    DUMP_FILE_SIZE=$(stat -c%s "$DUMP_FILE")
    if [ $DUMP_FILE_SIZE -gt $DUMP_FILE_SIZE_LIMIT ]
    then
        stop_all
    else
        sleep 1
    fi
done

#sleep $ping_time
#kill $dump_pid
exit 0
