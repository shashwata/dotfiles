#!/bin/bash -e
infected_host_db="$HOME/.infected"
mkdir -p $infected_host_db

if [ "x$1" == "x--force" -o "x$1" == "x-f" ] ; then
    echo "Forcing updates"
    force=true
    shift
else
    force=false
fi

function doIt(){
    host=$1
    ssh_key_file="$HOME/.ssh/id_rsa.pub"
    echo "Updating host: $host"
    if [ -e ${ssh_key_file} ] ; then
        ssh_key=$(cat ${ssh_key_file})
        auth_key_file="~/.ssh/authorized_keys"
        /usr/bin/ssh $USER@$host "mkdir -p ~/.ssh; touch ${auth_key_file} ; ! grep -q $(echo ${ssh_key} | awk '{print $2}') ${auth_key_file} && echo ${ssh_key} >> ${auth_key_file} ; echo 'Done configuring auth keys'"
    fi
    /usr/bin/ssh $USER@$host '[ -e ~/.bashrc ] && mv -n ~/.bashrc ~/.bashrc_old'
    rsync -v -e ssh --exclude "bin" --exclude ".git*" --exclude ".DS_Store" --exclude "bootstrap.sh" --exclude "README.md" --exclude "__old" --exclude ".extra" --exclude "init" --exclude ".osx" --exclude "infect.sh" --exclude ".brew" -a . $USER@$host:~
}

function validHostPing() {
    host=$1
    ping -o -t 2 -q -Q $host &> /dev/null && echo 1
}

function validHostHostCheck() {
    host=$1
    host $host &> /dev/null && echo 1
}

function require_push() {
    host=$1
    host_db="$infected_host_db/$host"
    touch "$host_db"
    
    if [ "x$(validHostPing $host)" != "x1" ] ; then
        echo "Invalid host: $host"
        return 2
    fi

    host_version=$(cat $host_db)
    curr_version=$(git log -n 1 --format=%H )
    
    if [ "x$host_version" != "x$curr_version" ] ; then
        doIt $host
        echo $curr_version > "$host_db"
    else
        echo "$host is already at the latest"
    fi
}

function pushToHost() {
    if [ $force == true ] ; then
        doIt $1
    else
        require_push $1
    fi
}

if [ "x$1" == "x" ] ; then
    echo "Please specify one or more host names to infect, '*' to sync all hosts under $infected_host_db"
    exit 1
fi
if [ "$1" == "*" ] ; then
    hosts=($(ls $infected_host_db))
else
    hosts=($@)
fi

echo Updating following hosts: ${hosts[@]}
read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

cd "$(dirname "${BASH_SOURCE}")"

for i in "${hosts[@]}" ; do
    pushToHost $i || ( echo "retrying host: $i"; pushToHost $i ) || echo "Unable to update host: $i"
done

