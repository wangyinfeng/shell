#!/bin/sh
# upload image from buildserver to local ftp/tftp server
# TODO: 
#   - detect errors, such as file delete fail, login fail
#     file write fail...
#   - support upload multi files
#==================================================================
# update log :
#   - 2013.08.15 provide interactive mode for service choise
#==================================================================


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
DIR3=''

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
        read opt
        case $opt in
            1) HOST=$HOST1; USER=$USER1; PASSWD=$PASSWD1; DIR=$DIR1; echo "Upload file to $HOST1"; break;;
            2) HOST=$HOST2; USER=$USER2; PASSWD=$PASSWD2; DIR=$DIR2; echo "Upload file to $HOST2"; break;;
            3) HOST=$HOST3; USER=$USER3; PASSWD=$PASSWD3; DIR=$DIR3; echo "Upload file to $HOST3"; break;;
            *) echo "$opt is not a valid option";
               echo "Press [entry] key to continue...";
               read entrykey;;
        esac
    done
fi

FILE=$1
if [ -z "$1" ]
then
    echo "Use default filename $DEFAULT_FILE "
    FILE=$DEFAULT_FILE
fi

echo 
echo "Going to delete ${FILE}, and then upload..."
echo

ftp -v -n $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
cd $DIR
binary
delete ${FILE}
put ${FILE}
bye
END_SCRIPT
echo
echo "Upload file ${FILE} to $HOST"
