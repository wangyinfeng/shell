#!/bin/bash
set -e
# need 'expect' package
yum install -y expect

# hostname for each node.
# MUST be identical with the out put of `hostname`
node=(c-0001 c-0002 c-0003)
# username to be interconnected
username=root
password=1qaz@wsx

node_num=${#node[*]}
local_host_name=`hostname`
suffix=".novalocal"
local_host_name=${local_host_name%"$suffix"}

if [ "$username" = "root" ];then
    homedir=root
else
    homedir=home/$username
fi

if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh/
fi

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    echo "Execute ssh-keygen --[done]"
fi

if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
    echo "Create ~/.ssh/authorized_keys --[done]"
fi

if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
    echo "StrictHostKeyChecking no" > ~/.ssh/config
    echo "StrictHostKeyChecking no --[done]"
    chmod 644 ~/.ssh/config
fi

# Copy 1st node's pub key to others first
auto_ssh_copy_id() {
    expect -c "set timeout -1;
        spawn ssh-copy-id $1;
        expect {
            *(yes/no)* {send -- yes\r;exp_continue;}
            *assword:* {send -- $2\r;exp_continue;}
            eof        {exit 0;}
        }";
}

ssh_copy_id_to_all() {
    for((i=0; i<node_num; i++))
    do
        auto_ssh_copy_id ${node[i]} $password
    done
}
ssh_copy_id_to_all


for((i=0; i<node_num; i++))
do
    if [[ ${node[i]} = $local_host_name ]];then
        continue
    fi
    echo "Generate key for ${node[i]}"
    ssh $username@${node[i]} 'rm -f ~/.ssh/id_rsa*; echo -e "\n\n" | ssh-keygen -t rsa -f ~/.ssh/id_rsa'
done

# Get pub key from other nodes
for((i=0; i<node_num; i++))
do
    if [[ ${node[i]} = $local_host_name ]];then
        cp /$homedir/.ssh/id_rsa.pub /$homedir/.ssh/${node[i]}.key
        continue
    fi
    scp ${node[i]}:/$homedir/.ssh/id_rsa.pub /$homedir/.ssh/${node[i]}.key
    echo "get pub key from ${node[i]} ... $?"
done

# Append key to authorized_keys...
for((i=0; i<node_num; i++))
do
    #reomve old keys before append new
    sed -i "/${node[i]}/d" /$homedir/.ssh/authorized_keys
    cat /$homedir/.ssh/${node[i]}.key >> /$homedir/.ssh/authorized_keys
    echo "append ${node[i]}.key ..."
done

let subloop=node_num-1
echo "starting send complete authorized_keys to ${node[0]}~${node[subloop]}"
for((i=0; i<node_num; i++))
do
    if [[ ${node[i]} = $local_host_name ]];then
        echo "${node[i]} is myself"
        continue
    fi
    scp /$homedir/.ssh/authorized_keys ${node[i]}:/$homedir/.ssh/authorized_keys
    scp /$homedir/.ssh/config ${node[i]}:/$homedir/.ssh/config
    echo "send to ${node[i]} finished...$? "
done

# delete intermediate files
rm -rf /$homedir/.ssh/*.key
echo "all configuration finished..."
set +e
