#!/bin/sh

ANSWER=

ask_promptprefix="[1m"  # bold
ask_promptsuffix="[1;33m > [0m"  # bold yellow symbol, then reset


# ask PROMPT [DEFAULT [PRESET]]
#  Shows a PROMPT to the user and waits for input.
#  The user input is saved in the $ANSWER envvar.
#  
#  If the user input is empty because the user simply pressed Enter,
#  $ANSWER will be set to DEFAULT instead.
#  If there is an EOF condition (because the user hit Ctrl-D),
#  the function will print a newline and return with a failure status (1).
#  
#  If PRESET is set, the function will _not_ wait for user input,
#  but set $ANSWER to PRESET and continue immediately.
#  (PRESET can also be set to "default", in which case $ANSWER
#   will be set to DEFAULT immediately.)
#  This might be interesting for scripts which support both a
#  user-input mode and an "automated" mode.
#  
#  Returns an error (1) if there was an EOF condition,
#  true otherwise.
ask () {
	local prompt="$1"
	local default="$2"
	local preset="$3"

	printf '%s%s%s' "$ask_promptprefix" "$prompt" "$ask_promptsuffix"

	if [ "$preset" = "default" ]; then
		# $preset was set to "default", use $default as the answer:
		ANSWER="$default"
		printf '%s\n' "$ANSWER"

	elif [ -n "$preset" ]; then
		# $preset was set, use that value as the answer:
		ANSWER="$preset"
		printf '%s\n' "$ANSWER"

	elif read -r ANSWER; then
		# Ok, the user hit enter.
		# $ANSWER is now set to the user's input.
		if [ -z "$ANSWER" ]; then
			# empty input, use $default instead
			ANSWER="$default"
		fi
		true

	else
		# Read failed, that means EOF (user pressed Ctrl-D).
		# Print one newline (so we don't mess up the shell prompt)
		# and return with an error status:
		echo ""
		return 1
	fi
}

