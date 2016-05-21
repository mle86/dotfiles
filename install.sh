#!/bin/sh
set -e
. $(dirname "$0")/shfn.sh

################################################################################

ask_symlink ".gitconfig" "gitconfig"
ask_symlink ".inputrc" "inputrc"
ask_symlink ".bash_aliases" "bash_aliases.sh"

while true; do
	ask "Welcher Prompt soll als ${ansi_highlight}~/.prompt${ansi_reset} installiert werden? "\
"${ansi_promptchar}g${ansi_reset}itprompt.sh / "\
"${ansi_promptchar}b${ansi_reset}lueprompt.sh / "\
"kei${ansi_promptchar}n${ansi_reset}er "\
"[g/b/N]" 'n'
	case "$ANSWER" in
		g|G)	install_symlink ".prompt" "prompt/gitprompt.sh"  ; break ;;
		b|B)	install_symlink ".prompt" "prompt/blueprompt.sh" ; break ;;
		n|N)	break ;;
	esac
done

ask_symlink ".vimrc" "vim/vimrc"

while true; do
	ask "Sollen die Vim-Farben nach ${ansi_highlight}.vim/colors${ansi_reset} gesymlinkt werden? [y/N/${ansi_promptchar}l${ansi_reset}ist]" 'n'
	if is_yes; then
		mkdir -p $HOME/.vim/colors/
		find $HERE/vim/colors/ -type f -print0  | z xargs -0r  ln -vsft $HOME/.vim/colors/ --
		break
	elif is_no; then
		break
	elif is L; then
		ls -1Alh $HERE/vim/colors/
	fi
done

echo ""

