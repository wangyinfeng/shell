#!/bin/sh
#Find string in specify files
#Improvement:
# 1. Ignore comments

if [ -z "$1" ]
then
    echo "Input the string need to search"
    exit 1
fi
echo "Find [$1] in $PWD ..."
echo 
#find . -name "*.c" -o -name "*.h*" | xargs grep -r "$1" | grep -v "grep"
find . \( -path */lib/bcmsdk_4.2.4 -o -path '*/lib/bcmsdk_5.2.*' -o -path '*/lib/bcmsdk_5.3.*' -o -path '*/lib/bcmsdk_5.4.*' -o -path '*/lib/bcmsdk_5.5.*' -o -path '*/lib/bcmsdk_5.6.*' -o -path '*/lib/bcmsdk5.5.*' -o -path */lib/bcmsdk_5.7.0 -o -path */*/lib/bcmsdk_4.2.4 -o -path '*/*/lib/bcmsdk_5.2.*' -o -path '*/*/lib/bcmsdk_5.3.*' -o -path '*/*/lib/bcmsdk_5.4.*' -o -path '*/*/lib/bcmsdk_5.5.*' -o -path '*/*/lib/bcmsdk_5.6.*' -o -path '*/*/lib/bcmsdk5.5.*' -o -path */*/lib/bcmsdk_5.7.0 \) -prune -o \( -name "*.c" -o -name "*.h*" -o -name "*.clive" \) | xargs grep -sn "$1" | awk '{ print } END { print "\nMatch number:\t " NR }'
#find . -name "*.c" -o -name "*.h*" | xargs grep -sn "$1"
# -s silent Not show error message 
# -n line-number Show match line number

echo
