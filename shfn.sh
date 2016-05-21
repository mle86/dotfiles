#!/bin/sh

HERE="$(dirname -- "$(readlink -f -- "$0")")"

ansi_good='[1;32m'
ansi_dark='[0;38;5;240m'
ansi_warning='[1;38;5;208m'
ansi_prompt_symbol='[1;33m'
ansi_prompt_symbol2="$ansi_dark[1m"
ansi_highlight='[1m'
ansi_reset='[0m'
ansi_promptchar='[1;4m'

# warn message
# Prints the message, but in the $ansi_warning color.
warn () { echo "$ansi_warning ""$@""$ansi_reset" >&2; }

# good message
# Prints the message, but in the $ansi_good color.
good () { echo "$ansi_good ""$@""$ansi_reset" ; }

# z command [arguments...]
# Runs the command as if there had been no 'z' prefix at all,
# but prints the $ansi_dark sequence first and the $ansi_reset sequence afterwards.
# Effectively, it runs the command, but turns its output "dark".
z () { echo -n "$ansi_dark ($(findcmd "$@")) " ; "$@" ; echo -n "$ansi_reset" ; }

# findcmd command [arguments...]
# Tries to determine the actual command.
# If there's an echo/mv/ln/cp/rm somewhere in "command arguments...",
# it's printed; if not, "?" is printed.
# This is used in conjunction with z() to obtain the command name,
# where we don't want to simply print "xargs" for a xargs command line.
findcmd () {
	while [ $# -gt 0 ]; do case "$1" in
		echo|mv|ln|cp|rm)  echo "$1" ; return ;;
		*)  shift ;;
	esac done
	echo "?"
}

# is_yes()
# Checks if $ANSWER looks like a yes.
is_yes () { [ "$ANSWER" = 'y' -o "$ANSWER" = 'Y' -o "$ANSWER" = 'yes' -o "$ANSWER" = 'j' -o "$ANSWER" = 'J' ]; }

# is_no()
# Checks if $ANSWER looks like a no.
is_no  () { [ "$ANSWER" = 'n' -o "$ANSWER" = 'N' -o "$ANSWER" = 'no' ]; }

# is letter
# Checks if $ANSWER is a single letter.
# The $letter argument should be in upper-case, because is() will lowercase it for a case-insensitive check.
is () { [ "$ANSWER" = "$1" -o "$ANSWER" = "$(echo -n "$1" | tr '[:upper:]' '[:lower:]')" ]; }

# is_absolute_path path|filename
# Determines whether its argument starts with a slash (i.e. looks like an absolute path).
is_absolute_path () { [ "/${1#/}" = "$1" ]; }

# ask PROMPT [DEFAULT [LEVEL]]
# Shows a prompt and waits for user input.
# The user input is saved in $ANSWER.
# If the user input was empty, $ANSWER is set to the DEFAULT argument instead.
# If LEVEL==0, ask() will print an empty line first ("first-level question");
# if LEVEL==1, ask() will only indent the prompt with one space ("second-level question").
ask () {
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

# ask_symlink sysFilename pkgFilename [defaultAnswer=n]
# Asks whether a symlink (sysFilename, absolute or $HOME-relative) should be created,
# pointing to a file in the package directory (pkgFilename, relative path only).
# See install_symlink() for the link creation and conflict resolution details.
# defaultAnswer must be "y" or "n".
ask_symlink () {
	local sysFilename="$1"
	local pkgFilename="$2"
	local defaultAnswer="${3:-n}"

	is_absolute_path "$sysFilename"  && local showSysFilename="$sysFilename"  || local showSysFilename="~/$sysFilename"

	[ "$defaultAnswer" = "y" ] && local options='[Y/n]' || local options='[y/N]'

	ask "Symlink $ansi_highlight$showSysFilename$ansi_reset → $pkgFilename? $options" "$defaultAnswer"

	is_yes && install_symlink "$sysFilename" "$pkgFilename"  || true
}

# install_symlink sysFilename pkgFilename
# Tries to create a symlink (sysFilename, absolute or $HOME-relative path)
# pointing to pkgFilename (package-relative path).
# If the symlink filename already exists, resolve_existing_symlink_target() will be called
# to ask the user how the conflict should be resolved,
# possibly skipping the symlinking.
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

# resolve_existing_symlink_target sysFilename pkgFilename
# Asks the user how a symlinking conflict should be resolved,
# assuming that the symlink name sysFilename already exists.
# Returns true if the user wants to overwrite the existing file with the symlink;
# returns false if the user wants to keep the existing sysFilename file unchanged.
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

# showfile filename
# Shows a file's contents with cat.
# Always succeeds.
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

# showdiff origFilename newFilename
# Shows the diff between two files.
# Uses colordiff if available.
# Prints a good() message if the files are identical.
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
