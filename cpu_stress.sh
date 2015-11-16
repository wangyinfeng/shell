#!/bin/sh
#Make the CPU stress test, to reach the 100% CPU usage.
#Tested under bash. Other shell may not work as expected.
#http://superuser.com/questions/443406/how-can-i-produce-high-cpu-load-on-a-linux-server
#TODO: 
#Configure the run time
#echo the worker id, so no need to get it by ps | grep      
#provide approach to stop the worker

#The reference source provide a script to support above TODOs, but the parameter seems not work.
# Usage: lc [number_of_cpus_to_load [number_of_seconds] ]
#
: << 'COMMENT'
lc() {
    (
    pids=""
    cpus=${1:-1}
    seconds=${2:-60}
    echo loading $cpus CPUs for $seconds seconds
    trap 'for p in $pids; do kill $p; done' 0
    for ((i=0;i<cpus;i++)); do while : ; do : ; done & pids="$pids $!"; done
    sleep $seconds
    )
}
COMMENT
#Start 4 endless loops, each of them do just null instruction.
#for i in 1 2 3 4; do while : ; do : ; done & done

if [ $# -ne 1 ]
then
    echo "Usage sh $0 <cpu_num>"
    exit 1
fi

cpus=$1

for ((i=0; i<cpus; i++)); do while : ; do : ; done & done

