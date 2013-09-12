#!/bin/bash
#Package the src and move to ftp dir
#===================================================================
#TODO:
#
#===================================================================
#update log:
#2013.09.03	better look
#===================================================================

echo "Going to package webos src file...."
cd /vobs/webos/src/
zip -1 -r src.zip bert/ lib/ common/ ge/ libcommon/ ts/ -x "bert/lib/bcmsdk_4.*" "bert/lib/bcmsdk_6.*" "bert/lib/bcmsdk_5.2.*" "bert/lib/bcmsdk_5.3.*" "bert/lib/bcmsdk_5.4.*" "bert/lib/bcmsdk_5.5.*" "bert/lib/bcmsdk_5.6.*" "bert/lib/bcmsdk_5.7.*" "bert/lib/bcmsdk5.*" "bert/lib/bcmsdk_5.10.*"  "bert/ts/doc" "ts/doc" "bert/lib/vxworks" "bert/lib/focalpoint_*"
mv src.zip /tftpboot/temp/leo/
