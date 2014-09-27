#!/bin/bash

hosts=($@)

echo ${hosts[@]} | tr ' ' '\n' > /tmp/add_auth_hosts

ssh_key_file="$HOME/.ssh/id_rsa.pub"
if [ -e ${ssh_key_file} ] ; then
    ssh_key=$(cat ${ssh_key_file})
    auth_key_file="~/.ssh/authorized_keys"

    pssh -A -i -h /tmp/add_auth_hosts "mkdir -p ~/.ssh; touch ${auth_key_file} ; ! grep -q $(echo ${ssh_key} | awk '{print $2}') ${auth_key_file} && echo ${ssh_key} >> ${auth_key_file} ; echo 'Done configuring auth keys'"
fi
