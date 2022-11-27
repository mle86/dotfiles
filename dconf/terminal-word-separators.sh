#!/bin/sh

# Changes Gnome Terminal's word recognition which is used when doubleclicking a word.
# The default recognizes too many characters as "word characters" regularly leading to too-wide selections.
# This setting forces the terminal to only recognize digits, letters, and the non_word_separators;
# everything else is considered a non-word char and therefore an auto-selection boundary.
# 
# Based on https://github.com/ab/ubuntu-wart-removal/blob/master/gnome-terminal-word-separators.sh

non_word_separators='-,.?%&#_+@~/'


list_gnome_terminal_profiles () { dconf list '/org/gnome/terminal/legacy/profiles:/' | grep '^:' ; }

find_gnome_terminal_default_profile () {
	local profiles="$(list_gnome_terminal_profiles)"
	local n_profiles="$(printf '%s\n' "$profiles" | wc -l)"

	if [ "$n_profiles" -ne 1 ]; then
		echo "cannot auto-select default gnome terminal profile, got $n_profiles profiles"  >&2
		if [ "$n_profiles" -gt 0 ]; then
			local IFS='
'
			printf '  (%s)\n' $profiles  >&2
		fi
		return 1
	fi

	printf '%s\n' "${profiles%"/"}"
}


profile="$(find_gnome_terminal_default_profile)" || exit 1

dconf write \
	"/org/gnome/terminal/legacy/profiles:/$profile/word-char-exceptions" \
	"@ms \"$non_word_separators\""

