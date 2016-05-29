#!/bin/sh
set -e
. $(dirname "$0")/shfn.sh

if [ "`id -u`" != 0 ]; then
	warn "You are not root!"
	exit 1
fi

bindest=/usr/local/bin
[ -d "$bindest" ] || mkdir -p -- "$bindest"

################################################################################

for file in $(binfiles); do
	ask_copy "$bindest/$file" "bin/$file"
done

echo ""

