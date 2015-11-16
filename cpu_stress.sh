#!/bin/sh
#Make the CPU stress test, to reach the 100% CPU usage.
#Tested under bash. Other shell may not work as expected.
#TODO: 
#Configure the run time
#echo the worker id, so no need to get it by ps | grep      
#provide approach to stop the worker

#Start 4 endless loops, each of them do just null instruction.
#for i in 1 2 3 4; do while : ; do : ; done & done

if [ $# -ne 1 ]
then
    echo "Usage sh $0 <cpu_num>"
    exit 1
fi

cpus=$1

for ((i=0; i<cpus; i++)); do while : ; do : ; done & done

