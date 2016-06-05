#!/bin/sh
# mle 2013-06
set -e
PROGNAME=$(basename -- "$0")

# g pattern filename...
# g pattern... , filename...

SEPARATOR=','
PATTERNOPT='-e'
options="-nHi	--color=always"
filenames=
patterns=

if [ -z "$1" ]; then
	echo "Syntax:" >&2
	echo " $PROGNAME [OPTION...] PATTERN      [FILENAME...]" >&2
	echo " $PROGNAME [OPTION...] PATTERN... $SEPARATOR [FILENAME...]" >&2
	exit 1
fi

export IFS="	
"  # tab only

while [ ! -z "$1" ]; do
	if [ "-${1#"-"}" = "$1" ]; then
		# it's an option:
		options="$options	$1"
	elif [ "$1" = "$SEPARATOR" ]; then
		# those were multiple patterns.
		# only filenames follow:
		for p in $filenames; do
			patterns="$patterns	$PATTERNOPT	$p"
		done
		filenames=
		shift
		break
	elif [ -z "$patterns" ]; then
		patterns="$PATTERNOPT	$1"
	else
		filenames="$filenames	$1"
	fi
	shift
done

exec grep $options $patterns $filenames "$@"

