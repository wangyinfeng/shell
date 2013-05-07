#Download image from FTP server1 and upload to FTP server2
#!/bin/bash
HOST1='9.43.102.108'
HOST2='9.111.70.244'
USER1='yfwang'
PASSWD1='blade123'
USER2='ftpuser'
PASSWD2='ftpuser'
FILE=$1

ftp -v -n $HOST1 <<END_SCRIPT
quote USER $USER1
quote PASS $PASSWD1
cd temp/leo
binary
get ${FILE}
bye
END_SCRIPT
echo
echo "Download file ${FILE} from $HOST1"
echo

ftp -v -n $HOST2 <<END_SCRIPT
quote USER $USER2
quote PASS $PASSWD2
cd /tftpboot
binary
put ${FILE}
bye
END_SCRIPT
echo
echo "Upload file ${FILE} to $HOST2"
echo
