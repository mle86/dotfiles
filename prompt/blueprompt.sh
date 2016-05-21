#!/bin/sh

###  Blauer Prompt:  #############################################

if [ "$BASH" ]; then
	[ "$EUID" -eq 0 ] \
		&& PS1="\[[1;37m\]\u\[[0m\]@\h:\[[1m\]\w\[[1;31m\]#\[[0m\] " \
		|| PS1="\[[1;37m\]\u\[[0m\]@\h:\[[1m\]\w\[[1;34m\]$\[[0m\] "

	case "$TERM" in
	xterm*|rxvt*)
		# show \u@\h:\w in terminal window title:
		PS1="\[]0;\u@\h:\w\a\]$PS1" ;;
	esac

else
	[ "`id -u`" -eq 0 ] \
		&& PS1='$PWD# ' \
		|| PS1='$PWD\$ '
fi

export PS1
unset PROMPT_COMMAND

