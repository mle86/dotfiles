#!/bin/sh
set -e

HERE="$(dirname -- "$(readlink -f -- "$0")")"

ansi_good='[1;32m'
ansi_dark='[0;38;5;240m'
ansi_warning='[1;38;5;208m'
ansi_prompt_symbol='[1;33m'
ansi_prompt_symbol2="$ansi_dark[1m"
ansi_highlight='[1m'
ansi_reset='[0m'
ansi_promptchar='[1;4m'

warn () { echo "$ansi_warning ""$@""$ansi_reset" >&2; }
good () { echo "$ansi_good ""$@""$ansi_reset" ; }

z () { echo -n "$ansi_dark ($(findcmd "$@")) " ; "$@" ; echo -n "$ansi_reset" ; }
findcmd () {
	while [ $# -gt 0 ]; do case "$1" in
		echo|mv|ln|cp|rm)  echo "$1" ; return ;;
		*)  shift ;;
	esac done
	echo "?"
}

is_yes () { [ "$ANSWER" = 'y' -o "$ANSWER" = 'Y' -o "$ANSWER" = 'yes' -o "$ANSWER" = 'j' -o "$ANSWER" = 'J' ]; }
is_no  () { [ "$ANSWER" = 'n' -o "$ANSWER" = 'N' -o "$ANSWER" = 'no' ]; }
is     () { [ "$ANSWER" = "$1" -o "$ANSWER" = "$(echo -n "$1" | tr '[:upper:]' '[:lower:]')" ]; }
is_absolute_path () { [ "/${1#/}" = "$1" ]; }

ask () {
	# ask PROMPT [DEFAULT [LEVEL]]
	ANSWER=
	local prompt="$1"
	local default="$2"
	local level="${3:-0}"

	if [ "$level" -lt 1 ]; then
		local ps="${ansi_prompt_symbol}•${ansi_reset}"
		echo ""
		echo -n "$ps "
	elif [ "$level" -lt 2 ]; then
		local ps="${ansi_prompt_symbol2}•${ansi_reset}"
		echo -n " $ps "
	fi

	read -p "${prompt} ${ansi_prompt_symbol}>${ansi_reset} " ANSWER
	[ -z "$ANSWER" ] && ANSWER=$default
	true
}

ask_symlink () {
	local sysFilename="$1"
	local pkgFilename="$2"
	local default="${3:-n}"

	is_absolute_path "$sysFilename"  && local showSysFilename="$sysFilename"  || local showSysFilename="~/$sysFilename"

	[ "$default" = "y" ] && local options='[Y/n]' || local options='[y/N]'

	ask "Symlink $ansi_highlight$showSysFilename$ansi_reset → $pkgFilename? $options" "$default"

	is_yes && install_symlink "$sysFilename" "$pkgFilename"  || true
}

install_symlink () {
	local sysFilename="$1"
	local pkgFilename="$HERE/$2"

	is_absolute_path "$sysFilename"  || sysFilename="$HOME/$sysFilename"

	if [ -e "$sysFilename" ] || [ -L "$sysFilename" ]; then
		if resolve_existing_symlink_target "$sysFilename" "$pkgFilename"; then
			# remove existing target, but make a backup
			z mv -vf -- "$sysFilename" "${sysFilename}.orig"
		else
			# don't overwrite
			true ; return
		fi
	fi

	z ln -sv -- "$pkgFilename" "$sysFilename"
}

resolve_existing_symlink_target () {
	local sysFilename="$1"
	local pkgFilename="$2"

	if [ -L "$sysFilename" ] && [ "$(readlink -f -- "$sysFilename")" = "$(readlink -f -- "$pkgFilename")" ]; then
		good "$sysFilename ist bereits ein Symlink auf $pkgFilename!"
		false ; return  # nothing to do here
	elif [ -L "$sysFilename" ] && [ ! -e "$sysFilename" ]; then
		warn "$sysFilename existiert schon! (ist ein DEFEKTER Symlink auf $(readlink -f -- "$sysFilename"))"
	elif [ -L "$sysFilename" ]; then
		warn "$sysFilename existiert schon! (ist ein Symlink auf $(readlink -f -- "$sysFilename"))"
	elif diff -q "$sysFilename" "$pkgFilename"; then
		good "$sysFilename existiert schon, ist aber identisch zu $pkgFilename!"
	elif [ -d "$sysFilename" ]; then
		warn "$sysFilename existiert schon, ist ein Verzeichnis!"
	else
		warn "$sysFilename existiert schon!"
	fi

	while true; do
		ask \
"${ansi_promptchar}s${ansi_reset}how original / "\
"${ansi_promptchar}d${ansi_reset}iff / "\
"${ansi_promptchar}y${ansi_reset}es, replace! / "\
"${ansi_promptchar}n${ansi_reset}o, skip "\
"[s/d/y/N]"  'n' 1
		case "$ANSWER" in
			s|S) showfile "$sysFilename" ;;
			d|D) showdiff "$sysFilename" "$pkgFilename" ;;
			y|Y|j|J|yes) true; return ;;
			n|N)         false; return ;;
		esac
	done
}

showfile () {
	local filename="$1"
	if [ -f "$filename" ] && [ ! -s "$filename" ]; then
		good "Originaldatei $filename ist leer!"
	else
		echo " Zeige Originaldatei $ansi_highlight$filename$ansi_reset:"
		echo " "
		cat -- "$filename"  || true
		echo " "
	fi
}

showdiff () {
	local origFilename="$1"
	local newFilename="$2"
	local diffcmd='diff'
	command -V colordiff >/dev/null && diffcmd='colordiff'

	local diffResult="$( $diffcmd -- "$origFilename" "$newFilename"  || true )"
	if [ -n "$diffResult" ]; then
		echo " Zeige Diff zwischen $origFilename und $newFilename:"
		echo " "
		echo -n "$diffResult"
		echo " "
	else
		echo " ${ansi_good}Dateien sind identisch!${ansi_reset}"
	fi
}

################################################################################

ask_symlink ".gitconfig" "gitconfig"
ask_symlink ".inputrc" "inputrc"
ask_symlink ".bash_aliases" "bash_aliases.sh"

while true; do
	ask "Welcher Prompt soll als ${ansi_highlight}~/.prompt${ansi_reset} installiert werden? "\
"${ansi_promptchar}g${ansi_reset}itprompt.sh / "\
"${ansi_promptchar}b${ansi_reset}lueprompt.sh / "\
"kei${ansi_promptchar}n${ansi_reset}er "\
"[g/b/N]" 'n'
	case "$ANSWER" in
		g|G)	install_symlink ".prompt" "prompt/gitprompt.sh"  ; break ;;
		b|B)	install_symlink ".prompt" "prompt/blueprompt.sh" ; break ;;
		n|N)	break ;;
	esac
done

ask_symlink ".vimrc" "vim/vimrc"

while true; do
	ask "Sollen die Vim-Farben nach ${ansi_highlight}.vim/colors${ansi_reset} gesymlinkt werden? [y/N/${ansi_promptchar}l${ansi_reset}ist]" 'n'
	if is_yes; then
		mkdir -p $HOME/.vim/colors/
		find $HERE/vim/colors/ -type f -print0  | z xargs -0r  ln -vsft $HOME/.vim/colors/ --
		break
	elif is_no; then
		break
	elif is L; then
		ls -1Alh $HERE/vim/colors/
	fi
done

echo ""

