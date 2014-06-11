#!/bin/sh
# Date: 2014/06/11
# Description: Check the unnecessary servers and stop them.
#
# Update:
# TODO: 
# - some smater way to turn off service and stop them, use $name
# - Turn off the service only if it's running.
# - Check the unnecessary kernel module, and not load them when boot up.
#
echo "Check and turn off unnecessary services, for level 3 user by default"
chkconfig --list | grep '3:on'
echo "Current running services: m"

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
echo "Stopped n services"
