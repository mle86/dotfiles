#!/bin/sh


# err errorMessage...
#  Prints the errorMessage on stderr.
err () {
	echo "$@" >&2
}

# fail [exitStatus=1] errorMessage
#  Prints the errorMessage on stderr (using the err() function),
#  then exits the script with exitStatus.
fail () {
	local exitStatus=1
	if [ -n "$2" ]; then
		exitStatus="$1"
		shift
	fi

	err "$@"
	exit "$exitStatus"
}

