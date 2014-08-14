#!/bin/sh
# Date: 2014/08/14
# Description: Find the PID by name, and kill it
#
# Update:
# TODO:
#
TARGET='drs-api'

#The simplest way maybe use pkill
pkill $TARGET

#kill $(ps aux| grep $TARGET | awk '{print $2}')


