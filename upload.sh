# upload image from buildserver to local ftp/tftp server
# TODO: detect errors, such as file delete fail, login fail
# file write fail...

#!/bin/bash
HOST1='9.111.81.251'
HOST2='9.111.70.244'
USER1='qa'
PASSWD1='qa'
USER2='ftpuser'
PASSWD2='ftpuser'
FILE=$1

echo "Going to delete ${FILE}, and then upload..."

ftp -v -n $HOST2 <<END_SCRIPT
quote USER $USER2
quote PASS $PASSWD2
cd /tftpboot
binary
delete ${FILE}
put ${FILE}
bye
END_SCRIPT
echo
echo "Upload file ${FILE} to $HOST1"
