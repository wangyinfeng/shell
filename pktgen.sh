#!/bin/bash
# https://www.kernel.org/doc/Documentation/networking/pktgen.txt

#set -x

function pgset()
{
    local result

    echo $1 > ${PGDEV}

    result=$(cat $PGDEV | fgrep "Result: OK:")
    if [ "$result" = "" ]; then
        cat $PGDEV | fgrep "Result:"
    fi
}


##################### Script configuration ######################
N="$1"                          # number of TX kthreads minus one
if [ -z "$1" ]; then
    N=0
fi
NCPUS="23"                      # number of CPUs on your machine minus one
IF="enp7s0f0"                   # network interface to test
#DST_IP="10.10.10.107"           # destination IP address
DST_MIN_IP="10.10.10.201"        # destination IP address begin
DST_MAX_IP="10.10.10.201"        # destination IP address end
DST_MAC="fa:16:3e:29:90:78"     # destination MAC address
# how to send packet to specified destination? IP address not include above will also receive the packet
#DST_MAC="00:00:00:00:00:00"     # as broadcast
DS_MAC_COUNT="3"
PKT_SIZE="60"                   # packet size
PKT_COUNT="10000000"            # number of packets to send
CLONE_SKB="10000"               # how many times a sk_buff is recycled


# Load pktgen kernel module
modprobe pktgen


# Clean the configuration for all the CPU-kthread (from 0 to ${NCPUS})
IDX=$(seq 0 1 ${NCPUS})
for cpu in ${IDX}; do
    PGDEV="/proc/net/pktgen/kpktgend_${cpu}"
    echo "Removing all devices (${cpu})"
    pgset "rem_device_all"
done

IDX=$(seq 0 1 ${N})
for cpu in ${IDX}; do
    # kthread-device configuration
    PGDEV="/proc/net/pktgen/kpktgend_${cpu}"
    echo "Configuring $PGDEV"
    echo "Adding ${IF}@${cpu}"
    pgset "add_device ${IF}@${cpu}"

    # Packets/mode configuration
    PGDEV="/proc/net/pktgen/${IF}@${cpu}"
    echo "Configuring $PGDEV"
    pgset "count ${PKT_COUNT}"
    pgset "clone_skb ${CLONE_SKB}"
    pgset "pkt_size ${PKT_SIZE}"
    pgset "delay 0"
#    pgset "dst $DST_IP"
    pgset "dst_min $DST_MIN_IP"
    pgset "dst_max $DST_MAX_IP"
    pgset "dst_mac $DST_MAC"
#    pgset "dst_mac_count $DST_MAC_COUNT"
    pgset "flag QUEUE_MAP_CPU"

    echo ""
done


# Run
PGDEV="/proc/net/pktgen/pgctrl"
echo "Running... Ctrl-C to stop"
pgset "start"
echo "Done."

# Show results
NUMS=""
for cpu in ${IDX}; do
    TMP=$(cat /proc/net/pktgen/${IF}@${cpu} | grep -o "[0-9]\+pps" | grep -o "[0-9]\+")
    echo "$cpu $TMP"
    NUMS="${NUMS} ${TMP}"
done

echo "Total TX rate: $(echo $NUMS | tr ' ' '+' | bc) pps"
