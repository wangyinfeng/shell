#!/bin/sh
# upload image from buildserver to local ftp/tftp server
# TODO: detect errors, such as file delete fail, login fail
# file write fail...

HOST1='9.111.81.251'
HOST2='9.111.70.244'
USER1='qa'
PASSWD1='qa'
USER2='ftpuser'
PASSWD2='ftpuser'
FILE=$1

echo 
echo "Going to delete ${FILE}, and then upload..."
echo

ftp -v -n $HOST1 <<END_SCRIPT
quote USER $USER1
quote PASS $PASSWD1
cd abc
binary
delete ${FILE}
put ${FILE}
bye
END_SCRIPT
echo
echo "Upload file ${FILE} to $HOST1"
