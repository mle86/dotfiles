#!/bin/sh

HERE="$(dirname -- "$(readlink -f -- "$0")")"

. $HERE/shfn/is.sh
. $HERE/shfn/ansi.sh

binfiles () { ls -1 bin/ ; }

ansi_prompt_symbol='[1;33m'  # yellow
ansi_prompt_symbol2="$ansi_dark[1m"  # dark grey

# pc word...
#  Shortcut for prompt character highlighting (bold + underlined).
pc () { UL "$@" ; }

# z command [arguments...]
#  Runs the command as if there had been no 'z' prefix at all,
#  but prints the $ansi_dark sequence first and the $ansi_reset sequence afterwards.
#  Effectively, it runs the command, but turns its output "dark".
z () { printf "$ansi_dark (%s) " "$(findcmd "$@")" ; "$@" ; printf "$ansi_reset" ; }

# findcmd command [arguments...]
#  Tries to determine the actual command.
#  If there's an echo/mv/ln/cp/rm somewhere in "command arguments...",
#  it's printed; if not, $command (the first argument) is printed.
#  This is used in conjunction with z() to obtain the command name,
#  where we don't want to simply print "xargs" for a xargs command line.
findcmd () {
	local first="$1"
	while [ $# -gt 0 ]; do case "$1" in
		echo|mv|ln|cp|rm|patch)  printf '%s\n' "$1" ; return ;;
		git)                     printf '%s\n' "$1 $2" ; return ;;
		*)  shift ;;
	esac done
	echo "$first"
}

# ask PROMPT [DEFAULT [LEVEL]]
#  Shows a prompt and waits for user input.
#  The user input is saved in $ANSWER.
#  If the user input was empty, $ANSWER is set to the DEFAULT argument instead.
#  If LEVEL==0, ask() will print an empty line first ("first-level question");
#  if LEVEL==1, ask() will only indent the prompt with one space ("second-level question").
ask () {
	ANSWER=
	local prompt="$1"
	local default="$2"
	local level="${3:-0}"

	if [ "$level" -lt 1 ]; then
		local ps="${ansi_prompt_symbol}•${ansi_reset}"
		printf '\n%s ' "$ps"
	elif [ "$level" -lt 2 ]; then
		local ps="${ansi_prompt_symbol2}•${ansi_reset}"
		printf ' %s ' "$ps"
	fi

	if ! read -p "${prompt} ${ansi_prompt_symbol}>${ansi_reset} " ANSWER; then
		# eof
		echo ""
		return 1
	fi

	[ -z "$ANSWER" ] && ANSWER=$default
	true
}

# ask_symlink sysFilename [pkgFilename=sysFilename [defaultAnswer=n]]
#  Asks whether a symlink (sysFilename, absolute or $HOME-relative) should be created,
#  pointing to a file in the package directory (pkgFilename, relative path only).
#  See install_symlink() for the link creation and conflict resolution details.
#  defaultAnswer must be "y" or "n".
ask_symlink () {
	local sysFilename="$1"
	local pkgFilename="${2:-$sysFilename}"
	local defaultAnswer="${3:-n}"

	is_absolute_path "$sysFilename"  && local showSysFilename="$sysFilename"  || local showSysFilename="~/$sysFilename"

	[ "$defaultAnswer" = "y" ] && local options='[Y/n]' || local options='[y/N]'

	ask "Symlink $(hi $showSysFilename) → $pkgFilename? $options" "$defaultAnswer"

	is_yes && install_symlink "$sysFilename" "$pkgFilename"  || true
}

# ask_copy sysFilename [pkgFilename=sysFilename [defaultAnswer=n]]
#  Asks whether a file in the repo (pkgFilename, relative path only)
#  should be copied to its sysFilename location (absolute path only).
#  See install_copy() for the copying and conflict resolution details.
#  defaultAnswer must by "y" or "n".
ask_copy () {
	local sysFilename="$1"
	local pkgFilename="${2:-$sysFilename}"
	local defaultAnswer="${3:-n}"

	[ "$defaultAnswer" = "y" ] && local options='[Y/n]' || local options='[y/N]'

	ask "Installiere $(hi $sysFilename) ← $pkgFilename? $options" "$defaultAnswer"

	is_yes && install_copy "$sysFilename" "$pkgFilename"  || true
}

# ask_patch patchFilename [explanation [defaultAnswer=n]]
#  Asks whether a patch (patchFilename, package-relative path only) should be applied.
#  See apply_patch().
#  defaultAnswer must by "y" or "n".
ask_patch () {
	local patchFilename="$1"
	local explanation="${2:+"($2) "}"
	local defaultAnswer="${3:-n}"

	[ "$defaultAnswer" = "y" ] && local options='[Y/n]' || local options='[y/N]'

	ask "Patch $(hi $patchFilename)? $explanation$options" "$defaultAnswer"

	is_yes && apply_patch "$patchFilename"  || true
}

# apply_patch patchFilename [targetFilename]
#  Tries to apply a patch (patchFilename, package-relative path)
#  against targetFilenane (absolute path) or the patch's default target file.
#  Will not create reject files if the patch doesn't match,
#  and it will not reverse the patch.
apply_patch () {
	local patchFilename="$HERE/$1"
	local targetFile="$2"

	z patch --forward --directory=/ --reject-file=- -p0 -- $targetFile <"$patchFilename"
}

# install_symlink sysFilename pkgFilename
#  Tries to create a symlink (sysFilename, absolute or $HOME-relative path)
#  pointing to pkgFilename (package-relative path).
#  If the symlink filename already exists, resolve_existing_target() will be called
#  to ask the user how the conflict should be resolved,
#  possibly skipping the symlinking.
install_symlink () {
	local sysFilename="$1"
	local pkgFilename="$HERE/$2"

	is_absolute_path "$sysFilename"  || sysFilename="$HOME/$sysFilename"

	local sysDirectory="$(dirname -- "$sysFilename")"
	[ -d "$sysDirectory" ] || z mkdir -vp -- "$sysDirectory"

	if [ -e "$sysFilename" ] || [ -L "$sysFilename" ]; then
		if resolve_existing_target "$sysFilename" "$pkgFilename"; then
			# remove existing target, but make a backup
			z mv -vf -- "$sysFilename" "${sysFilename}.orig"
		else
			# don't overwrite
			true ; return
		fi
	fi

	z ln -sv -- "$pkgFilename" "$sysFilename"
}

# install_copy sysFilename pkgFilename
#  Tries to copy pkgFilename (package-relative path) to sysFilename (absolute path).
#  If the target filename already exists, resolve_existing_target() will be called
#  to ask the user how the conflict should be resolved,
#  possibly skipping the copying.
install_copy () {
	local sysFilename="$1"
	local pkgFilename="$HERE/$2"

	if ! is_absolute_path "$sysFilename" || [ -d "$sysFilename" ]; then
		warn "install_symlink() needs an absolute path"
		exit 9
	fi

	if [ -e "$sysFilename" ] || [ -L "$sysFilename" ]; then
		if resolve_existing_target "$sysFilename" "$pkgFilename"; then
			# remove existing target, but make a backup
			z mv -vf -- "$sysFilename" "${sysFilename}.orig"
			chmod -x "${sysFilename}.orig"
		else
			# don't overwrite
			true ; return
		fi
	fi

	z cp -v --remove-destination -- "$pkgFilename" "$sysFilename"
}

# resolve_existing_target sysFilename pkgFilename
#  Asks the user how a symlinking/copying conflict should be resolved,
#  assuming that the symlink name sysFilename already exists.
#  Returns true if the user wants to overwrite the existing file;
#  returns false if the user wants to keep the existing sysFilename file unchanged.
resolve_existing_target () {
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
		ask "$(pc s)how original / $(pc d)iff / $(pc y)es, replace! / $(pc n)o, skip [s/d/y/N]"  'n' 1
		if   is S;   then showfile "$sysFilename"
		elif is D;   then showdiff "$sysFilename" "$pkgFilename"
		elif is_yes; then true ; return
		elif is_no;  then false ; return ; fi
	done
}

# showfile filename
#  Shows a file's contents with cat.
#  Always succeeds.
showfile () {
	local filename="$1"
	if [ -f "$filename" ] && [ ! -s "$filename" ]; then
		good "Originaldatei $filename ist leer!"
	else
		printf " Zeige Originaldatei %s:\n" "$(hi "$filename")"
		echo " "
		cat -- "$filename"  || true
		echo " "
	fi
}

# showdiff origFilename newFilename
#  Shows the diff between two files.
#  Uses colordiff if available.
#  Prints a good() message if the files are identical.
showdiff () {
	local origFilename="$1"
	local newFilename="$2"
	local diffcmd='diff'
	command -V colordiff >/dev/null && diffcmd='colordiff'

	local diffResult="$( $diffcmd -- "$origFilename" "$newFilename"  || true )"
	if [ -n "$diffResult" ]; then
		printf " Zeige Diff zwischen %s und %s:\n" "$origFilename" "$newFilename"
		printf ' \n%s \n' "$diffResult"
	else
		good "Dateien sind identisch!"
	fi
}

# showcolordemo maxColumns colno color text
#  Prints the $text input, replacing any literal "$colno" with the $colno value
#  and any literal "$color" with the $color value.
#  After $maxColumns calls, a newline is printed afterwards.
#  (Be careful: the $text value will be part of an eval command.)
showcolordemo () {
	local maxColumns="$1"
	local colno="$2"
	local color="$3"
	local demo="$4"

	eval "printf '%s' \"$demo\""

	_col=$((_col + 1))
	if [ "$_col" -ge "$maxColumns" ]; then
		_col=0
		echo ""
	fi
}
_col=0

# store_prompt_color ansiColorSequence
store_prompt_color () {
	local seq="$1"
	local output="$HOME/.promptcolor"

	printf "#!/bin/sh\n\nPROMPTCOLOR='%s'\n\n" "$seq" > "$output"
}

