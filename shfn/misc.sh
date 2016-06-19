#!/bin/sh

# remove_trailing_slashes string
#  Removes any trailing slashes in the string, if there are any,
#  and prints the result.
remove_trailing_slashes () {
	echo "$1" | sed 's:/*$::'
}

# indent [level=2]
#  Prints its stdin input.
#  Every line will be prefixed with $level leading spaces.
#  (If $level is not a number, it will be used as the indentation string.)
#  This function needs the is_digits() test function from is.sh.
indent () {
	local level="${1:-2}"
	if is_digits "$level"; then
		# $indent x space
		level="$(printf "%${level}s")"
	fi

	local line=
	while read -r line; do
		echo "$level$line"
	done
}

# suffix word...
#   Prints its stdin input.
#   The function arguments will be appended to every line (with spaces in between).
#   No extra space will be printed between the line end and the function's first argument.
suffix () {
	local IFS=' '
	local line=
	while read -r line; do
		echo "$line""$*"
	done
}

# replace filename [fileMode] < content
#  Overwrites a file with new content.
#  The process is atomic because the function will write stdin to a temporary file in the same directory first,
#  then rename the temporary file to the target name with "mv -f".
#  If fileMode is set, the file's mode will be set to that value using chmod(1).
#  If fileMode is not set and the file already existed, its mode won't be changed.
#  If fileMode is not set and the file did not already exist, its mode will be set to 0666-umask.
replace () {
	local destfile="$1"
	local fileMode="$2"

	local destdir="$(dirname -- "$destfile")"
	local destname="$(basename -- "$destfile")"

	local tmpfile="$(mktemp --suffix="$destname" --tmpdir="$destdir")"
	cat >"$tmpfile"

	if [ -n "$fileMode" ]; then
		# set file mode to explicit value:
		chmod -- "$fileMode" "$destfile"
	elif [ -f "$destfile" ]; then
		# file existed before replace(), set mode to earlier value:
		chmod --reference="$destfile" -- "$tmpfile"
	else
		# no mode specified and file is new -- set mode to 0666-umask:
		chmod -- '=rw' "$tmpfile"
	fi

	mv -f -- "$tmpfile" "$destfile"  # atomic!
}

