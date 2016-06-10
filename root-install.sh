#!/bin/sh
set -e
. $(dirname "$0")/shfn.sh
. $(dirname "$0")/githubfn.sh

if [ "`id -u`" != 0 ]; then
	warn "You are not root!"
	exit 1
fi

bindest=/usr/local/bin
[ -d "$bindest" ] || mkdir -p -- "$bindest"

################################################################################

ask_github "mle86/clerr"
ask_github "mle86/gl"
ask_github "mle86/walk"

for file in $(binfiles); do
	ask_copy "$bindest/$file" "bin/$file"
done

echo ""

