#!/bin/sh
# Run command repeatly, with specified interval
# Usage: check the interface package process status
#        check the ovs flow hit/missed/lost statistics

if [ $# -ne 2 ]
then
    printf "Usage:\n"
    printf "\t$0 <\"command\"> <\"interval\">\n"
    exit 1
fi

command=( "$1" )
interval=$2
while true
do
    printf "\n"
    # The way to run command in script
    ${command[@]}
    sleep $interval
done

