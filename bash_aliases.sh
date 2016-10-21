#!/bin/sh

###  Einstellungen:  #############################################

# Source all system profile scripts if this a non-login first-level shell, e.g. if this is an xterm.
[ $SHLVL -eq 1 ] && ! shopt -q login_shell 2>/dev/null && . /etc/profile

umask 002

LS_OPTIONS="-h --color=auto -F"

alias grep='grep --color=auto'
alias ls='ls $LS_OPTIONS'

export EDITOR='vim'
export LESS='-R -i'

unset IGNOREEOF

if [ "$TERM" = "xterm" ]; then
	export TERM="xterm-256color"
fi

export PATH="$PATH:$HOME/bin"

export IBUS_ENABLE_SYNC_MODE=1
  # needed for ibus <1.5.11 to fix this problem: https://youtrack.jetbrains.com/issue/IDEA-78860


###  Abkürzungen:  ###############################################

alias l='ls $LS_OPTIONS -l'
alias la='ls $LS_OPTIONS -la'

mkcd () {
	mkdir -p -- "$@" && command cd -- "$1"
}

cd () {
	local ansi_warning='[1;38;5;208m' ansi_reset='[0m'
	if [ -n "$1" ] && [ -f "$1" ]; then
		# if the argument is a file, go to its directory
		command    cd -- "$(dirname -- "$1")"
		history -s cd -- "$(dirname -- "$1")"
		echo "${ansi_warning}cd: Assumed $(dirname -- "$1")/ instead of $1${ansi_reset}" >&2

	elif [ ! -e "$1" ] && [ -d "$(dirname -- "$1")" ] && [ "${1%/l}/l" = "$1" ]; then
		# argument ends with "/l", does not exist, but the parent directory exists...
		# yep, I missed Enter between "cd" and "l" again.
		command    cd -- "$(dirname -- "$1")"
		history -s cd -- "$(dirname -- "$1")"
		l
		echo "${ansi_warning}cd: Assumed $(dirname -- "$1")/ instead of $1${ansi_reset}" >&2

	else
		# regular cd
		command cd "$@"
	fi
}

alias '..'='command cd ..'
alias '...'='command cd ../..'
alias -- '-'='command cd - >/dev/null'

alias shlvl='echo $SHLVL'
alias keep='IGNOREEOF=99'

alias c99='gcc -O -std=c99 -Wall -Wextra -pedantic'
alias c89='gcc -O -std=c89 -Wall -Wextra -pedantic'
alias c='c99'

alias gs='git status'
alias gb='git branch -avv'
alias ga='git add -p'
alias gd='git diff --diff-algorithm=minimal'
alias gdc='git diff --diff-algorithm=minimal --cached'
alias gco='git checkout'

myip () {
	( ip addr show dev eth0 ; ip addr show dev wlan0 ) | \
		grep -e 'inet ' -e 'inet6' |\
		grep -P '(?<!brd) [0-9a-f]+[:\.][0-9a-f:\.]+'
	curl https://ip.eul.cc/
}

typo_alias () {
	local wrong="$1"
	local correct="$2"
	eval "$wrong () { history -s \"$correct\" \"\$@\" ; \"$correct\" \"\$@\" ; }"
}
typo_alias cmhod chmod
typo_alias ivm   vim

tf () {
	[ -n "$1" ] || set -- '/var/log/syslog'
	tail -n0 -f "$@"
}

lastpow () {
	[ -n "$1" ] || set -- '/var/log/auth.log'
	zgrep \
		-e 'New seat seat0.'		\
		-e 'System is powering down.'	\
		-e 'Lid opened.'		\
		-e 'Lid closed.'		\
		-a "$@"
}

todo () {
	# Syntax:  todo [TARGET=.]...
	# Greps all files in the current directory for 'TODO'.
	# Greps in other directories instead if there are any directory arguments.
	# Also greps all plain files which are given as arguments.

	local grepopt='--color=always -i -n'
	local grepre='\bTODOs\?\b'

	[ -n "$1" ] || set -- '.'

	find "$@" -maxdepth 1 -type f -print0	| \
	  xargs -0r grep $grepopt -- "$grepre"			| \
	    less -FRX
}

sdl () {
	svn diff "$@" | less -R --quit-if-one-screen
}

grepf () {
	if [ -z "$2" ]; then
		echo "Syntax:" >&2
		echo " grepf FILEPATTERN [GREPOPTIONS...] GREPPATTERNS..." >&2
		return 1
	fi

	local filepattern="${1:-"*"}"
	shift

	find -type f -name "$filepattern" -print0 | xargs -0r g "$@" , 
}

beanstalk () {
	rlwrap nc -v -C ${1:-localhost} ${2:-11300}
}

# mle 2016-01-05   'docker exec' shortcut:
dx () {
	if [ -z "$1" ] || [ "$1" = "-a" ]; then
		echo "usage: dx CONTAINERNAME [COMMAND=$SHELL]"  >&2
		echo ""  >&2
		docker ps $1  >&2
		return 9
	fi

	local container="$1"
	shift

	# This will print an error and exit if the container is not found:
	docker inspect "$container" >/dev/null || return

	[ -n "$1" ] || set -- "$SHELL"

	echo "[1mEntering docker container '$container' with command '$@':[0m"  >&2

	docker exec -t -i "$container" "$@"
}

# T [filename=test.sh]
#  Creates a new file from a template in ~/.templates/, then opens it with vim.
#  Existing files will simply be opened, not overwritten.
T () {
	local default_name='test'
	local default_extension='.sh'
	local filename="${1:-"$default_name$default_extension"}"
	local goline=2
	local vimcmd=

	# Short cut: .sh gets expanded to test.sh
	echo "$filename" | grep -q '^\.[[:alnum:]]\+$' && filename="$default_name$filename"

	history -s vim -- "$filename"

	if [ -e "$filename" ]; then
		echo "File $filename already exists!"  >&2
		# Don't overwrite it!
		# Just open it.
		vim -- "$filename"
		return
	fi

	local extension="${filename##*.}"
	local template="$HOME/.templates/template.$extension"
	local vimscript="$HOME/.templates/${extension}.vim"

	local cmd_vimscript=
	[ -f "$vimscript" ] && cmd_vimscript="-S $vimscript"  # make sure none of these filenames contains a space

	if [ -f "$template" ]; then
		# :1r pastes the file _below_ the current line.
		# That means the empty default line is still at the top of the buffer afterwards.
		# :0d deletes it.
		# After that, +$goline moves the cursor.
		# Additional template-specific vim commands are read from $vimscript (if it exists).

		vim -c ":1r $template" -c ':0d _' +$goline $cmd_vimscript -- "$filename"
	else
		vim $cmd_vimscript -- "$filename"
	fi
	local vimstatus=$?

	case "$filename" in
		*.sh|*.pl)  chmod --quiet +x -- "$filename" || true ;;
	esac
	return $vimstatus
}

# https://gist.github.com/mwhite/6887990#gistcomment-1870225
alias gcl='git checkout @{-1}'



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
