#!/bin/bash

if [ $# -eq 1 -a -n "$1" ]; then
	LXSESSION=$1
else
# default session
	LXSESSION=/usr/bin/startlxde
fi

[ -f /etc/profile ] && . /etc/profile
[ -f ~/.profile ] && . ~/.profile

[ -f ~/.xinitrc ] && . ~/.xinitrc


exec -l bash -c "$LXSESSION"

