#!/bin/sh
# Just tired of set the proxy, modify the vim tab width, install necessary
# packages, configure the vnc or samba...
# Let the script to do all the boring things automatically


install_software()
{
    echo "Install the basic softwares......"
    #for CentOS/RedHat
    #TODO check the individal package is intalled or not
    #TODO handle the exception, such as repo not reachable
    yum install -y zip net-tools  wget openssl-devel kernel-devel gcc vim tmux vnc-server "Development Tools"
    yum groupinstall -y "Desktop" "Desktop Platform" "X Window System" "Fonts"
    #TODO also support ubuntu/apt-get
    echo "Install the basic softwares done."

}

set_proxy()
{
    echo "Set the proxy for wget and yum......"
    #TODO check if yum.conf exist
    echo 'proxy=http://192.168.255.130:655' >> /etc/yum.conf
    echo 'proxy=https://192.168.255.130:655' >> /etc/yum.conf

    touch ~/.wgetrc
    printf '
http_proxy = http://192.168.255.130:655
ftp_proxy = http://192.168.255.130:655
use_proxy = on
wait = 15' > ~/.wgetrc
    echo "Set the proxy for wget and yum done."
}

#TODO is it better to download from github?
change_vim_cfg()
{
    echo "Change vim configuration......"
    #TODO check if file exist first
    touch ~/.vimrc
    printf '
set tabstop=4
set sw=4
set et
set number
' > ~/.vimrc
    echo "Change vim configuration done."
}

#change_vim_cfg
