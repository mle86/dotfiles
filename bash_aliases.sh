#!/bin/sh
# vim: syntax=sh

###  Einstellungen:  #############################################

LS_OPTIONS="$LS_OPTIONS -F"


###  Abkürzungen:  ###############################################

alias c99='gcc -O -std=c99 -Wall -Wextra -pedantic'
alias c89='gcc -O -std=c89 -Wall -Wextra -pedantic'
alias c='c99'

alias gs='git status'
alias gb='git branch -a'
alias ga='git add -p'
alias gd='git diff --diff-algorithm=minimal'
alias gdc='git diff --diff-algorithm=minimal --cached'

tf () {
	local file="${1:-/var/log/syslog}"
	[ -n "$1" ] && shift
	tail -n0 -f "$@" "$file"
}

lastpow () {
	local file="${1:-/var/log/auth.log}"
	[ -n "$1" ] && shift
	zgrep \
		-e 'New seat seat0.'		\
		-e 'System is powering down.'	\
		-e 'Lid opened.'		\
		-e 'Lid closed.'		\
		-a "$@" "$file"
}

todo () {
	# Syntax:  todo [TARGET=.]...
	# Greps all files in the current directory for 'TODO'.
	# Greps all files in different directories instead if there are any arguments.
	# Also greps all plain files which are given as arguments.

	local grepopt='--color=always -i -n'
	local grepre='\bTODOs\?\b'

	local target1="${1:-"."}"
	[ -n "$1" ] && shift

	find "$target1" "$@" -maxdepth 1 -type f -print0	| \
	  xargs -0r grep $grepopt -- "$grepre"			| \
	    less -FRX
}

sdl () {
	svn diff "$@" | less -R --quit-if-one-screen
}

grepf () {
	if [ -z "$2" ]; then
		echo "Syntax:" >&2
		echo " grepf FILEPATTERN [GREP-OPTIONS...] GREP-PATTERNS..." >&2
		return 1
	fi

	filepattern="${1:-"*"}"
	shift
	find -type f -name "$filepattern" -print0 | xargs -0r g "$@" , 
}

beanstalk () {
	rlwrap nc -v -C ${1:-localhost} ${2:-11300}
}

# mle 2016-01-05   'docker exec' shortcut:
dx () {
	if [ -z "$1" ]; then
		echo "usage: dx CONTAINERNAME [COMMAND=$SHELL]"  >&2
		echo ""  >&2
		docker ps  >&2
		return 9
	fi

	local oldifs="$IFS"
	IFS="	"

	local container="$1"
	shift

	# This will print an error and exit if the container is not found:
	docker inspect "$container" >/dev/null || return

	local command="${@:-"$SHELL"}"
	local showcommand=$(echo $command)  # remove tabs

	echo "[1mEntering docker container '$container' with command '$showcommand':[0m"  >&2

	docker exec -t -i "$container" $command
	IFS="$oldifs"
}


###  ls-Farben:  #################################################

_set_ls_colors () {
	local archive='38;5;203'
	local picture='01;35'
	local audio='00;36'
	local video='38;5;049'
	local info='38;5;221'
	local backup='38;5;242'

	LS_COLORS="rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=$archive:*.tgz=$archive:*.arj=$archive:*.taz=$archive:*.lzh=$archive:*.lzma=$archive:*.tlz=$archive:*.txz=$archive:*.zip=$archive:*.z=$archive:*.Z=$archive:*.dz=$archive:*.gz=$archive:*.lz=$archive:*.xz=$archive:*.bz2=$archive:*.bz=$archive:*.tbz=$archive:*.tbz2=$archive:*.tz=$archive:*.deb=$archive:*.rpm=$archive:*.jar=$archive:*.rar=$archive:*.ace=$archive:*.zoo=$archive:*.cpio=$archive:*.7z=$archive:*.rz=$archive:*.jpg=$picture:*.jpeg=$picture:*.gif=$picture:*.bmp=$picture:*.pbm=$picture:*.pgm=$picture:*.ppm=$picture:*.tga=$picture:*.xbm=$picture:*.xpm=$picture:*.tif=$picture:*.tiff=$picture:*.png=$picture:*.svg=$picture:*.svgz=$picture:*.mng=$picture:*.pcx=$picture:*.mov=$video:*.mpg=$video:*.mpeg=$video:*.m2v=$video:*.mkv=$video:*.ogm=$video:*.mp4=$video:*.m4v=$video:*.mp4v=$video:*.vob=$video:*.qt=$video:*.nuv=$video:*.wmv=$video:*.asf=$video:*.rm=$video:*.rmvb=$video:*.flc=$video:*.avi=$video:*.fli=$video:*.flv=$video:*.gl=$video:*.dl=$video:*.xcf=$video:*.xwd=$video:*.yuv=$video:*.cgm=$video:*.emf=$video:*.axv=$video:*.anx=$video:*.ogv=$video:*.ogx=$video:*.aac=$audio:*.au=$audio:*.flac=$audio:*.mid=$audio:*.midi=$audio:*.mka=$audio:*.mp3=$audio:*.mpc=$audio:*.ogg=$audio:*.ra=$audio:*.wav=$audio:*.axa=$audio:*.oga=$audio:*.spx=$audio:*.xspf=$audio:*README=$info:*README.md=$info:*TODO=$info:*INFO=$info:*AUTHOR=$info:*INSTALL=$info:*CHANGELOG=$info:*.bkup=$backup:*.bak=$backup:*~=$backup:*.swp=$backup"
}
_set_ls_colors ; unset -f _set_ls_colors


###  man-Farben:  ################################################

export LESS_TERMCAP_so='[48;5;220;30m'    # begin standout-mode - info box, search results
export LESS_TERMCAP_se='[0m'           # end standout-mode
export LESS_TERMCAP_md='[1;38;2;244;255;210m'


###  gcc-Farben:  ################################################

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
