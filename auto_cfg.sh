#!/bin/sh
# Just tired of set the proxy, modify the vim tab width, install necessary
# packages, configure the vnc or samba...
# Let the script to do all the boring things automatically

file_exist()
{
    if [ -z $1 ]
    then
        echo "No file parameter!"
        return -1
    else
        if [ -f $1 ]
        then
            return 0
        else
            return 1
        fi
    fi
}

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

#is it better to download from github? - let's assume the host has no internet access
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
colorscheme koehler
' > ~/.vimrc
    echo "Change vim configuration done."
}

change_bash_cfg()
{
    echo "Change bash configutation......"
    echo "alias ..='cd ..'" >> ~/.bashrc
    echo "alias ll='ls -l'" >> ~/.bashrc
    echo "Change bash configuration done."
}

change_iptables()
{
    echo "Change iptables configutation......"
    echo "Change iptables configuration done."
}

disable_selinux()
{
    SELINUX_CFG=/etc/selinux/config
    echo "Disable selinux......"
    file_exist $SELINUX_CFG
    if [ $? -ne 0 ]
    then
        echo "The configure file $SELINUX_CFG not exist. quit."
        exit 1
    fi

    enable="cat $SELINUX_CFG"
    if [[ $enable == *"enforcing"* ]]
        sed -i 's/^SELINUX=[^ ]*/SELINUX=disabled/' $SELINUX_CFG
    then
        echo "Selinux not enabled, nothing done"
    fi
    echo "Disable selinux done"
}
#change_vim_cfg
