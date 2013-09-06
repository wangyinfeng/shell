#!/bin/sh
#Find string in specify files
#============================================================================
#TODO:
# 1. Ignore comments
#============================================================================
#update log:
# 2013.08.23 better look
# 2013.09.06 provide exact match, case sensitivity option
#============================================================================

precious=""             #default no
case_sensitivity="y"    #default yes
grep_para=""            #default blank
while getopts :hwi OPTION
do
    case "$OPTION" in
      h) echo "Find the string in specified .c/.h/.clive file in local directory"; 
         echo "     gp -h          get help info";
         echo "     gp STRING      find file with default option(no case sensitivity, no esact match)";
         echo "     gp -w STRING   exact math";
         echo "     gp -i STRING   no case sensitivity";
         exit 1;;  
      w) percious="y" ; shift; break;;  
      i) case_sensitivity="n"; shift; break;;
      *|?) echo "Invalid parameter"; exit 1;;
    esac
done

if [ "$precious" == "y" ]
then
    grep_para="-w"
elif [ "$case_sensitivity" == "n" ]
then
    grep_para="-i"
fi

if [ -z "$1" ]
then
    echo "Input the string need to search"
    exit 1
fi

echo "Find [$1] in $PWD ..."
echo 
#find . -name "*.c" -o -name "*.h*" | xargs grep -r "$1" | grep -v "grep"
find . \( -path */lib/bcmsdk_4.2.4 -o -path '*/lib/bcmsdk_5.2.*' -o -path '*/lib/bcmsdk_5.3.*' -o -path '*/lib/bcmsdk_5.4.*' -o -path '*/lib/bcmsdk_5.5.*' -o -path '*/lib/bcmsdk_5.6.*' -o -path '*/lib/bcmsdk5.5.*' -o -path '*/lib/bcmsdk_5.7.*' -o -path */*/lib/bcmsdk_4.2.4 -o -path '*/*/lib/bcmsdk_5.2.*' -o -path '*/*/lib/bcmsdk_5.3.*' -o -path '*/*/lib/bcmsdk_5.4.*' -o -path '*/*/lib/bcmsdk_5.5.*' -o -path '*/*/lib/bcmsdk_5.6.*' -o -path '*/*/lib/bcmsdk5.5.*' -o -path */*/lib/bcmsdk_5.7.0 \) -prune -o \( -name "*.c" -o -name "*.h*" -o -name "*.clive" \) | xargs grep -sn $grep_para "$1" | awk '{ print } END { print "\nMatch number:\t " NR }'
#find . -name "*.c" -o -name "*.h*" | xargs grep -sn "$1"
# -s silent Not show error message 
# -n line-number Show match line number

echo
