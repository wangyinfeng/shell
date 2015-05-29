#!/usr/bin/expect -f
#not use the bash interprete the script, but use the expect.
#cann't run with sh the_file, just chmod it and run it directly.

set r_host root@158.85.212.9
set r_pwd TjqxD5tl

spawn ssh "$r_host"
#set timeout 30
expect "Password:"
send "$r_pwd\r"

interact
