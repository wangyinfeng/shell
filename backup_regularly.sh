#!/bin/sh
#backup source file automatically with crontab when files size be changed.
#=========================================================================
#TODO:
#   - compare the zip file size not precise, better to get the REAL changed
#     info.
#=========================================================================
#update log:
#2013.08.23   - copy
#=========================================================================

cd ~/source
rm -rf *_backup.zip
zip -r `date +%Y%m%d%H%M%S`_backup.zip code/

current_size=`ls -l *_backup.zip | awk '{print $5}'`
last_size=`cat ~/last_size`
#echo "current $current_size"
#echo "last $last_size"

if [ $current_size -ne $last_size ]
then
cp *_backup.zip ~/
fi
echo $current_size > ~/last_size
