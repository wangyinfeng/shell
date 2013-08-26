#!/bin/sh
# upload image from buildserver to local ftp/tftp server
# TODO: 
#   - detect errors, such as file delete fail, login fail
#     file write fail...
#   - support upload multi files
#   - show transfer speed/percentage
#==================================================================
# update log :
#   - 2013.08.15 provide interactive mode for service choise
#   - 2013.08.23 remove the dirname for remote file
#                set echo info color
#==================================================================

#set the print font color, better look?
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2; tput bold)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1; tput bold)
function error_echo() {
    echo -e "$RED$*$NORMAL"
}
function ok_echo() {
    echo -e "$GREEN$*$NORMAL"
}
function blue_echo() {
    echo -e "$BLUE$*$NORMAL"
}

#Show usage by cat, format control better than use echo
cat << EOF
Usage: upload [filename]
    Upload the specified file to the ftp server.
EOF

# service pool
HOST1='9.111.65.61'     #Infra
USER1='ftp'
PASSWD1=''
DIR1='pub/wyf'

HOST2='9.111.70.244'    #L3
USER2='ftpuser'
PASSWD2='ftpuser'
DIR2=''

HOST3='9.111.81.251'    #QA
USER3='qa'
PASSWD3='qa'
DIR3='abc'

DEFAULT_FILE='bundle'
HOST=$HOST1
USER=$USER1
PASSWD=$PASSWD1
DIR=$DIR1

if [ -z "$HOST" ]
then
    while :
    do
        echo "Chose the ftp server you want to upload files:"
        echo "1. $HOST1"
        echo "2. $HOST2"
        echo "3. $HOST3"
        echo "q. quit"
        read opt
        case $opt in
            1) HOST=$HOST1; USER=$USER1; PASSWD=$PASSWD1; DIR=$DIR1; echo "Upload file to $HOST1"; break;;
            2) HOST=$HOST2; USER=$USER2; PASSWD=$PASSWD2; DIR=$DIR2; echo "Upload file to $HOST2"; break;;
            3) HOST=$HOST3; USER=$USER3; PASSWD=$PASSWD3; DIR=$DIR3; echo "Upload file to $HOST3"; break;;
            q) echo "Quit"; exit 1;;
            *) error_echo "$opt is not a valid option";
               echo "Press [entry] key to continue...";
               read entrykey;;
        esac
    done
fi

SRC_FILE=$1
SRC_DIR=`dirname "$SRC_FILE"`
if [ -z "$1" ]
then
    echo "Use default filename $DEFAULT_FILE "
    DST_FILE=$DEFAULT_FILE
else
    DST_FILE=`basename "$SRC_FILE"`
fi

echo 
blue_echo "Going to upload ${SRC_FILE}, delete ${DST_FILE}, and then upload..."
echo

ftp -v -n $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
cd $DIR
binary
delete ${DST_FILE}
put ${SRC_FILE} ${DST_FILE}
bye
END_SCRIPT
echo
ok_echo "Upload file ${SRC_FILE} to $HOST finished"
