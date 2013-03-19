#!/bin/bash -e
infected_host_db="$HOME/.infected"
mkdir -p $infected_host_db

if [ "x$1" == "--force" -o "$1" == "-f" ] ; then
    force=true
    shift
else
    force=false
fi

function doIt(){
    host=$1
    echo "Updating host: $host"
	rsync -v -e ssh --exclude ".git*" --exclude ".DS_Store" --exclude "bootstrap.sh" --exclude "README.md" --exclude "__old" --exclude ".bashrc" --exclude ".extra" --exclude "init" --exclude ".osx" -a . $USER@$host:~
    /usr/bin/ssh $USER@$host '[ -e ~/.bashrc ] && mv -n ~/.bashrc ~/.bashrc_old'
    rsync -v .bashrc $USER@$host:~
}

function require_push() {
    host=$1
    host_db="$infected_host_db/$host"
    touch "$host_db"
    
    if ! host $host > /dev/null ; then
        echo "Invalid host: $host"
        exit 2
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
        doIt $host
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
    pushToHost $i
done

