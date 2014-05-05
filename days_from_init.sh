#!/bin/bash
# Calucate the days since baby born. Have implemented by C but it's terriable
# to compile the file to get the result. So it's better to implement it by
# script. 

# Solution 1 from google:
# -d, --date=STRING         display time described by STRING, not `now'
# %s   seconds since 1970-01-01 00:00:00 UTC
INIT_DAY="2014/2/6"
date_in_seconds_init=`date -d "$INIT_DAY" "+%s"`
date_in_seconds_now=`date "+%s"`
diff=$(($date_in_seconds_now-$date_in_seconds_init))
days=$(($diff/(60*60*24)))

echo "Angel has came for $days days."

