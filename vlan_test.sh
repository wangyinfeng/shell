#!/bin/sh
# use vconfig to configure add sub vlan interface, then use ping -f to send 
# package to do the test
# Try it with python!

DEV=eth2
MIN_VLAN=1000
MAX_VLAN=1000

add_vlan_interface()
{
    for ((i=$MIN_VLAN;i<$MAX_VLAN;i++))
    do
        vconfig add $DEV $i
        ifconfig $DEV.$i 3.3.3.210 netmask 255.0.0.0 up
    done
    ifconfig | grep eth2\\. | wc -l
}

rem_vlan_interface()
{
    for ((i=$MIN_VLAN;i<$MAX_VLAN;i++))
    do
        ifconfig $DEV.$i down
        vconfig rem $DEV.$i
    done
    ifconfig | grep eth2\\. | wc -l
}

do_test()
{
    while true
    do
        for ((i=$MIN_VLAN;i<$MAX_VLAN;i++))
        do
            ping -c 100 -f 3.3.3.103 -I $DEV.$i
        done
    done
}

if [ -z $1 ]
then
    echo "$0 add/do/rem to add vlan interface, send ping package and remove vlan interface"
    exit 1
else
    if [ $1 == 'add' ]
    then
        add_vlan_interface
    elif [ $1 == 'do' ]
    then
        do_test
    elif [ $1 == 'rem' ]
    then
        rem_vlan_interface
    else
        echo "unknow action!"
        exit 2
    fi
fi
