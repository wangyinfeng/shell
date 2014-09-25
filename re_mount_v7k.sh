#!/bin/sh
if [ -d /var/ftp/store/software ]
then
        echo "The remote disk has already been mounted!"
        exit
else
        iscsiadm -m node --targetname  "iqn.1986-03.com.ibm:2145.scsa-wuxi-v7ku2.node2" --portal "9.111.74.156" --login
        mount /dev/sda1 /mnt
        mount --bind /mnt/store /var/ftp/store
fi
