#!/bin/bash

host=$1
if [ "x$host" == "x" ] ; then
    echo "Please specify the host name to infect"
    exit 1
fi

cd "$(dirname "${BASH_SOURCE}")"
git pull
function doIt(){
	rsync -v -e ssh --exclude ".git*" --exclude ".DS_Store" --exclude "bootstrap.sh" --exclude "README.md" --exclude "__old" --exclude ".bashrc" --exclude ".extra" --exclude "init" --exclude ".osx" -a . $USER@$host:~
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt
	fi
fi
unset doIt
