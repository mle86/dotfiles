#!/bin/sh
# These functions allow easy string comparisons of their argument or the $ANSWER envvar.
# They are used in conjunction with the `ask' function (which writes to $ANSWER).
# They are boolean test functions which never produce any output, just a true or false return status.

# is_yes [input=$ANSWER]
#  Checks if the input looks like an explicit "yes" answer.
#  Accepted values are "y", "Y", "j", "J", and "yes".
is_yes () {
	local input="${1:-"$ANSWER"}"
	[ "$input" = 'y' ] || [ "$input" = 'Y' ] || [ "$input" = 'yes' ] || [ "$input" = 'j' ] || [ "$input" = 'J' ]
}

# is_no [input=$ANSWER]
#  Checks if the input looks like an explicit "no" answer.
#  Accepted values are "n", "N", and "no".
is_no () {
	local input="${1:-"$ANSWER"}"
	[ "$input" = 'n' ] || [ "$input" = 'N' ] || [ "$input" = 'no' ]
}

# is word [input=$ANSWER]
#  Checks if the input equals a word, regardless of its case.
#  The $word argument should be in upper-case, because is() will uppercase the input for a case-insensitive check.
#  For a case-sensitive check, use iscase().
is () {
	local word="$1"
	local input="${2:-"$ANSWER"}"
	[ "$input" = "$word" ] && return

	# No exact match.
	# Assume $word is all uppercase, convert $input to uppercase too and compare again:
	input="$(printf '%s\n' "$input" | tr '[:lower:]' '[:upper:]')"
       	[ "$input" = "$word" ]
}

# iscase word [input=$ANSWER]
#  Checks if the input exactly equals a word.
#  This is the case-sensitive version of is().
iscase () {
	local word="$1"
	local input="${2:-"$ANSWER"}"
	[ "$input" = "$word" ]
}

# is_absolute_path [filename=$ANSWER]
#  Determines whether its argument starts with a slash (i.e. looks like an absolute path).
is_absolute_path () {
	local input="${1:-"$ANSWER"}"
	[ "/${1#/}" = "$1" ]
}

# is_digits [word=$ANSWER]...
#  Returns true if all arguments are digits-only, false otherwise.
is_digits () {
	[ $# -gt 0 ] || set -- "$ANSWER"

	# join all input words together,
	# replace linebreaks with 'x' (not a digit, so grep can catch those too),
	# grep for any non-digit,
	# invert search result:
	local IFS=  # join $* without spaces in between words
	printf '%s' "$*" | paste -sdx | grep -qv '[^0-9]'
}

