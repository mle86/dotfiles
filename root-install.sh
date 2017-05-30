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

# This file contains sensible system-wide vim settings.
# They're supposed to be mostly non-invasive for other users.
ask_copy "/etc/vim/vimrc.local" "vim/sys-vimrc"

ask_patch "patch/gedit.desktop.patch" "standalone gedit mode"

echo ""

