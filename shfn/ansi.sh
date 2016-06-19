#!/bin/sh
# Functions for colored output.

ansi_good='[1;32m'  # green, bold
ansi_dark='[0;38;5;240m'  # dark grey
ansi_warning='[1;38;5;208m'  # orange, bold
ansi_reset='[0m'


# warn message
#  Prints the message to stderr, but in the $ansi_warning color.
warn () { echo "$ansi_warning""$@""$ansi_reset" >&2; }

# good message
#  Prints the message, but in the $ansi_good color.
good () { echo "$ansi_good""$@""$ansi_reset" ; }

# dark message
#  Prints the message, but in the $ansi_dark color.
dark () { echo "$ansi_dark""$@""$ansi_reset" ; }

# hi message...
#  Prints its arguments, but prefixed with the "bold" ansi sequence.
#  It will end its output with SGR 22 instead of $ansi_reset,
#  so it can be used inline in possibly-colored strings.
hi () {
	local ansi_highlight='[1m'
	local ansi_reset='[22m'  # SGR 22 "Neither bold nor faint"
	echo "$ansi_highlight""$@""$ansi_reset"
}

# ul message...
#  Prints its arguments, but prefixed with the "underlined" ansi sequence.
#  It will end its output with SGR 24 instead of $ansi_reset,
#  so it can be used inline in possibly-colored strings.
ul () {
	local ansi_underline='[4m'
	local ansi_reset='[24m'  # SGR 24 "Underline: None"
	echo "$ansi_underline""$@""$ansi_reset"
}

# UL message...
#  Prints its arguments, but prefixed with the "underlined" and "bold" ansi sequences.
#  This is a combination of hi() and ul().
UL () {
	ul "$(hi "$@")"
}

