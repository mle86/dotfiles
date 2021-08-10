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

export HISTSIZE=8000


###  Abkürzungen:  ###############################################

alias l='ls $LS_OPTIONS -l'
alias la='ls $LS_OPTIONS -la'

mkcd () {
	local ansi_warning='[1;38;5;208m' ansi_reset='[0m'
	if [ -d "$1" ]; then
		echo "${ansi_warning}mkcd: Already exists: $1" >&2
		# ok continue
	elif [ -e "$1" ]; then
		echo "${ansi_warning}mkcd: Already exists but is not a directory: $1" >&2
		return 1
	fi
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

L () {
	local lineno="$1" ; shift
	[ "$#" -eq 0 ] && set -- '-'
	while [ $# -gt 0 ]; do
		tail -n "+$lineno" -- "$1" | head -n 1
		shift
	done
}

alias '..'='command cd ..'
alias '...'='command cd ../..'
alias -- '-'='command cd - >/dev/null'
alias d='cd ~/Desktop/'
alias n='cd ~/Downloads/'

alias shlvl='echo $SHLVL'
alias keep='IGNOREEOF=99'

alias iws='sudo iwlist scan'

alias c99='gcc -O -std=c99 -Wall -Wextra -pedantic'
alias c89='gcc -O -std=c89 -Wall -Wextra -pedantic'

alias gs='git status'
alias gb='git branch -avv'
alias ga='git add -p'
alias gd='git diff --diff-algorithm=minimal --find-renames'
alias gdc='git diff --diff-algorithm=minimal --find-renames --cached'
alias grc='git rebase --continue'
alias gra='git rebase --autostash'

gco () {
	# reverse gitprompt's branch name shortening:
	local _a=0 args=
	while [ $# -gt 0 ]; do
		local v="$1" ; shift
		if   [ "f-${v#f-}" = "$v" ]; then v="feature-${v#f-}"
		elif [ "r-${v#r-}" = "$v" ]; then v="release-${v#r-}"
		elif [ "H-${v#H-}" = "$v" ]; then v="hotfix-${v#H-}"
		elif [ "f/${v#f/}" = "$v" ]; then v="feature/${v#f/}"
		elif [ "r/${v#r/}" = "$v" ]; then v="release/${v#r/}"
		elif [ "H/${v#H/}" = "$v" ]; then v="hotfix/${v#H/}"
		elif [ "dev"       = "$v" ]; then v="develop"
		elif [ "mst"       = "$v" ]; then v="master"
		fi
		eval "local a${_a}=\"\$v\""
		args="$args \"\$a${_a}\""
		_a=$((_a + 1))
	done
	eval git checkout $args
}

gci () {
	if [ $# -gt 0 ]; then
		local args="$*"
		local suffix=
		local br='
'
		while true; do
			local lastword="$(printf '%s' "$args" | awk 'NF{ print $NF }')"
			[[ "$lastword" =~ ^[t#]\ ?[0-9]+$ ]] || break

			args="${args%"$lastword"*}"
			lastword="${lastword#[t#]}"
			lastword="${lastword#" "}"
			[ -n "$suffix" ] && lastword="$lastword, "
			printf "SFX[%s] LW[%s]\n" "$suffix" "$lastword"
			suffix="#$lastword$suffix"
		done
		case "$suffix" in
			'')	;;
			*","*)	set -- "${args}${br}${br}tickets ${suffix}" ;;
			*)	set -- "${args}${br}${br}ticket ${suffix}" ;;
		esac
	fi
	git commit --edit --message="$*"
}

gss () {
	local index="${1:-0}"
	if [ "$index" = "-" ]; then
		git stash list
	else
		git show -v "stash@{$index}" --
	fi
}

myip () {
	local dev= devs='eth0 wlan0 enp2s0f0 enp5s0 wlp3s0'
	( for dev in $devs; do ip addr show dev $dev 2>/dev/null; done ) | \
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
typo_alias tuig  tig
typo_alias compoesr composer
typo_alias compsoer composer
unset -f typo_alias

tf () {
	[ -n "$1" ] || set -- '/var/log/syslog'
	tail -n10 -f "$@"
}

tfx () {
	tf "$@" | hx
}

_get_project_container_name () {
	case "$1" in
		micro-*)	echo "$1" ;;
		*)
			echo "project root is not a known container name: $1"  >&2
			return 1
			;;
	esac
}

DX () {
	# find git project root, it should be in a suitably-named dir:
	local root= dir= container=
	root="$(git rev-parse --show-toplevel)" || return
	dir="$(basename -- "$root")"
	container="$(_get_project_container_name "$dir")"
	dx "$container" "$@"
}

DL () {
	# find git project root, it should be in a suitably-named dir:
	local root= dir= container=
	root="$(git rev-parse --show-toplevel)" || return
	dir="$(basename -- "$root")"
	container="$(_get_project_container_name "$dir")"
	docker logs --tail=30 --follow "$container" "$@" | hx
}

lastpow () {
	[ -n "$1" ] || set -- '/var/log/auth.log'
	local line= brk='
'
	local color_on='[1;32m' color_off='[1;31m'
	local color_open='[38;2;169;205;134m' color_close='[38;2;222;135;135m' c0='[0m'
	zgrep \
		-e 'New seat seat0.'		\
		-e 'System is powering down.'	\
		-e 'Lid opened.'		\
		-e 'Lid closed.'		\
		-a "$@" | \
	while read -r line; do
		! [ -t 1 ] && printf '%s\n' "$line" && continue
		local prefix= suffix=
		case "$line" in
			*"New seat"*)      prefix="$color_on" ; suffix="$c0" ;;
			*"powering down"*) prefix="$color_off" ; suffix="$c0$brk" ;;
			*"Lid opened"*)    prefix="$color_open" ; suffix="$c0" ;;
			*"Lid closed"*)    prefix="$color_close" ; suffix="$c0" ;;
		esac
		printf '%s%s%s\n' "$prefix" "$line" "$suffix"
	done
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
		docker ps $1
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

o () {
	[ $# -lt 1 ] && set -- "."
	while [ $# -gt 0 ]; do
		xdg-open "$1" 2>/dev/null &
		shift
	done
}

# pg [-GREPOPTION...] [--] [TERM...]
#  Calls `ps -ef' and filters its output,
#  showing only lines that contain one of the TERMs.
#  Without arguments, it's just a `ps -ef' shortcut.
pg () {
	local grepopts=
	local g=0
	local pscmd="ps -ef"

	if [ $# -eq 0 ]; then
		$pscmd
		return
	fi

	while [ $# -gt 0 ]; do
		if [ "$1" = "--" ]; then
			shift
			break
		elif [ "-${1#-}" != "$1" ]; then
			break
		else
			eval "local _grepopt_$g=\"\$1\""
			grepopts="$grepopts \"\$_grepopt_$g\""
			g=$((g + 1))
			shift
		fi
	done

	while [ $# -gt 0 ]; do
		eval "local _grepopt_$g=\"\$1\""
		grepopts="$grepopts -e \"\$_grepopt_$g\""
		g=$((g + 1))
		shift
	done

	$pscmd | eval "grep $grepopts"
}

# nx [COMMAND [ARGS...]]
#  Executes one command, then sends a visible notification.
#  Useful for wait for the completion of a long-running background task.
#  Without a COMMAND argument, it sends a notification immediately,
#  depending on the previous $? value.
nx () {
	local status=$?

	if [ $# -gt 0 ]; then
		status=0
		( "$@" ) || status=$?
	fi

	if [ $status -eq 0 ]; then
		notify-send --icon info "Command finished." "$*"
	else
		notify-send --icon important "Command failed!  (status $status)" "$*"
	fi

	return $status
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
	_set_ls_color $picture .jpg .jpeg .gif .bmp .pbm .pgm .ppm .tga .xbm .xpm .tif .tiff .png .svg .svgz .mng .pcx .webp
	_set_ls_color $video .mov .mpg .mpeg .m2v .mkv .ogm .mp4 .m4v .mp4v .vob .qt .nuv .wmv .asf .rm .rmvb
	_set_ls_color $video .flc .avi .fli .flv .gl .dl .xcf .xwd .yuv .cgm .emf .axv .anx .ogv .ogx .webm
	_set_ls_color $audio .aac .au .flac .mid .midi .mka .mp3 .mpc .ogg .ra .wav .axa .oga .spx .xspf
	_set_ls_color $info README README.md TODO TODO.md INFO AUTHOR INSTALL CHANGELOG CHANGELOG.md
	_set_ls_color $backup .bkup .bak '~' .swp

	unset -f _set_ls_color
}
set_ls_colors ; unset -f set_ls_colors


###  Includes:  ##################################################

[ -r ~/.promptcolor ] && . ~/.promptcolor
[ -r ~/.prompt ] && . ~/.prompt
[ -r ~/.extra ] && . ~/.extra
[ -r ~/.rest_fn.sh ] && . ~/.rest_fn.sh


###  Ende  #######################################################
return 0
