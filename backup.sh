#!/bin/sh
# backup current clearcase checkout file
# 2013.06.08

FILESTR="/vobs/webos/"

if [ -z "$1" ]
then
    echo "Please input target dir"
    exit
else
    dir=$1
#    echo "will copy to dir ${dir}"
fi

submit info > si.log
#ENDLINE=`cat si.log|wc -l`  #get the line number of file
#echo $ENDLINE
while read LINE
do
    MATCH=`expr match "$LINE" "$FILESTR"`
    if [ $MATCH -ne 0 ]
    then
        FILE=`echo $LINE | cut -d "@" -f1`
        cp $FILE ${dir}
        printf "copy %s\t\t\t\t\t to\t %s\n" "${FILE}" "${dir}"
    fi
done < si.log
