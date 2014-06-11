#!/bin/sh
# Date: 2014/06/11
# Description: Check the unnecessary servers and stop them.
#
# Update:
# TODO: 
# - Check the unnecessary kernel module, and not load them when boot up.
#   - unnecessary kernel module can be removed by edit the file
#     /etc/modprobe.d/blacklist.conf
#    use lsmod to check the current loaded module, and if the 'Used by' is
#    0, means no one is currently using that module, the module may be able
#    to remove.
#

declare -a services=('iscsid' 
                     'iscsi'
                     'fcoe' 
#                     'fcoe-target' 
                     'auditd' #linux auditing system
                     'bluetooth'
                     'avahi-daemon' #mDNS/DNS-SD daemon
                     'cups' #common unix printing system service
                     'mdmonitor' #software RAID monitoring and management service
                     'abrtd' #automatic bug report tool
                     'abrt-oops'
                     'abrt-ccpp'
                     'acpid' #power management
                     'postfix' #mail transfer agent
                     'nfslock')
function service_stop() 
{
    echo "check the service [$*] status"
    service $* status 1>/dev/null
    if [ $? -eq 0 ]
    then
        echo "service [$*] is running, stop it"
        chkconfig $* off
        service $* stop
    else
        echo "service [$*] already stopped"
    fi
}

if [ $UID -ne 0 ]
then
    echo "Must run by root"
    exit 1
fi

for i in ${services[@]}
do
    service_stop $i
done
echo
echo "The remain runnig services are:"
chkconfig --list | grep '3:on'

:<<'COMMENT'
echo "Check and turn off unnecessary services, for level 3 user by default"
chkconfig --list | grep '3:on'

chkconfig iscsid off
chkconfig iscsi off
chkconfig fcoe off
chkconfig fcoe-target off
chkconfig bluetooth off
# The Avahi mDNS/DNS-SD daemon implementing Apple's ZeroConf architecture
chkconfig avahi-daemon  off
# Common unix printing system service
chkconfig cups off
# software RAID monitoring and management service.
chkconfig mdmonitor off
# automatic bug report tool
chkconfig abrt-oops off
chkconfig abrt-ccpp off
chkconfig abrtd off
# power control
chkconfig acpid off
# mail transfer agent
chkconfig postfix off

chkconfig --list | grep '3:on'
COMMENT
