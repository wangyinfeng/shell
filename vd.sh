#!/bin/bash
# bash script used to diff code with vimdiff
# usage: vd <file>
#   if <file> with version number=0, vimdiff the current change with the latest checkin.
#   if <file> with version number!=0, vimdiff the change between version_number and version_number-1
#   if <file> with no valid version number, exit
#==================================================================================
#update log:
#2013.08.23 better look
#==================================================================================

if [ -z "$1" ]
then
    echo "Input the string need to diff"
    exit 1
fi

#STR=/vobs/webos/src/bert/ts/mp/cmd/boot_cli.c@@/main/r_cheetah_1.0.0.0_int/m_cheetah_bss_main1.0.0.0_int/m_cheetah_6.x.0.0_int/submit_cheetah_77182/101
CUR_STR=$1
cur_ver=${CUR_STR##*/}
#echo $cur_ver

if [[ $cur_ver =~ ^[0-9]+$ ]]
then
    if [ "$cur_ver" == "0" ]    # diff current with baseline
    then
        OLD_STR=${CUR_STR}
        CUR_STR=`echo $1 | cut -d "@" -f1`
    else                        # diff between baseline
        old_ver=$[$cur_ver-1]
        BASE=${CUR_STR%/*}
        OLD_STR=${BASE}/${old_ver}
    fi
else
    echo "No version number provided. Exit!"
    exit 1
fi

echo $CUR_STR
echo $OLD_STR

vimdiff $CUR_STR $OLD_STR
