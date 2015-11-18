urrently support parameter:
#  -s ping packet size
#  -w ping timeout

usage()
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

#default parameter value
ping_size=56
ping_time=10

while getopts ":s:w:" o; do
    case "${o}" in
        s)
            ping_size=${OPTARG}
            ;;
        w)
            ping_time=${OPTARG}
            ;;
        *)
            echo "Invalid parameter. Exit"; usage; exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            ;;
    esac
    shift
done

# lanuch ping and get the ping's pid
#ping -c $ping_num -s $ping_size -w $ping_time localhost > /dev/null &
ping localhost > /dev/null &
p=$!
echo $p
sleep 3
kill $p

#echo `pidof ping`
pgrep ping
