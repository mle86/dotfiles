#!/bin/sh

###  Einstellungen:  #############################################

LS_OPTIONS="-h --color=auto -F"

alias grep='grep --color=auto'
alias ls='ls $LS_OPTIONS'

export EDITOR='vim'
export LESS='-R'


###  Abkürzungen:  ###############################################

alias c99='gcc -O -std=c99 -Wall -Wextra -pedantic'
alias c89='gcc -O -std=c89 -Wall -Wextra -pedantic'
alias c='c99'

alias gs='git status'
alias gb='git branch -avv'
alias ga='git add -p'
alias gd='git diff --diff-algorithm=minimal'
alias gdc='git diff --diff-algorithm=minimal --cached'

alias myip='curl https://ip.eul.cc/'

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


###  Farben:  ####################################################

# man-Farben
export LESS_TERMCAP_so='[48;5;220;30m'    # begin standout-mode - info box, search results
export LESS_TERMCAP_se='[0m'           # end standout-mode
export LESS_TERMCAP_md='[1;38;2;244;255;210m'

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

set_ls_colors () {
	local archive='38;5;203'
	local picture='01;35'
	local audio='00;36'
	local video='38;5;049'
	local info='38;5;221'
	local backup='38;5;242'

	LS_COLORS="rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32"

	_set_ls_color () {
		local color="$1"
		shift

		while [ -n "$1" ]; do
			LS_COLORS="${LS_COLORS}:*${1}=${color}"
			shift
		done
	}

	_set_ls_color $archive .tar .tgz .tbz .tbz2 .bz .bz2 .txz .xz .7z .gz .z .Z .zip .rar
	_set_ls_color $archive .arj .taz .lzh .lzma .tlz .dz .lz .tz .jar .ace .cpio .rz
	_set_ls_color $archive .zoo .deb .rpm
	_set_ls_color $picture .jpg .jpeg .gif .bmp .pbm .pgm .ppm .tga .xbm .xpm .tif .tiff .png .svg .svgz .mng .pcx
	_set_ls_color $video .mov .mpg .mpeg .m2v .mkv .ogm .mp4 .m4v .mp4v .vob .qt .nuv .wmv .asf .rm .rmvb
	_set_ls_color $video .flc .avi .fli .flv .gl .dl .xcf .xwd .yuv .cgm .emf .axv .anx .ogv .ogx
	_set_ls_color $audio .aac .au .flac .mid .midi .mka .mp3 .mpc .ogg .ra .wav .axa .oga .spx .xspf
	_set_ls_color $info README README.md TODO INFO AUTHOR INSTALL CHANGELOG
	_set_ls_color $backup .bkup .bak ~ .swp

	unset -f _set_ls_color
}
set_ls_colors ; unset -f set_ls_colors


###  Includes:  ##################################################

[ -r ~/.prompt ] && . ~/.prompt
[ -r ~/.extra ] && . ~/.extra


###  Ende  #######################################################
return 0
