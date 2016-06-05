#!/bin/sh
set -e
. $(dirname "$0")/shfn.sh

################################################################################

ask_symlink ".gitconfig" "gitconfig"
ask_symlink ".inputrc" "inputrc"
ask_symlink ".bash_aliases" "bash_aliases.sh"

while true; do
	ask "Welcher Prompt soll als $(hi ~/.prompt) installiert werden? $(pc g)itprompt.sh / $(pc b)lueprompt.sh / kei$(pc n)er [g/b/N]"  'n'
	if   is G;  then install_symlink ".prompt" "prompt/gitprompt.sh"  ; break
	elif is B;  then install_symlink ".prompt" "prompt/blueprompt.sh" ; break
	elif is_no; then break ; fi
done

ask_symlink ".vimrc" "vim/vimrc"

while true; do
	ask "Sollen die Vim-Farben nach $(hi .vim/colors) gesymlinkt werden? [y/N/$(pc l)ist]" 'n'
	if is_yes; then
		mkdir -p $HOME/.vim/colors/
		find $HERE/vim/colors/ -type f -print0  | z xargs -0r  ln -vsft $HOME/.vim/colors/ --
		break
	elif is L;  then ls -1Alh $HERE/vim/colors/
	elif is_no; then break; fi
done

echo ""

