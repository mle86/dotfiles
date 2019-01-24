#!/bin/sh
set -e
. $(dirname "$0")/shfn.sh

################################################################################

ask_symlink ".gitconfig" "gitconfig"
ask_symlink ".inputrc" "inputrc"
ask_symlink ".bash_aliases" "bash_aliases.sh"
ask_symlink ".rest_fn.sh" "rest_fn.sh"
ask_symlink ".templates" "templates/"

while true; do
	ask "Welcher Prompt soll als $(hi ~/.prompt) installiert werden? $(pc g)itprompt.sh / $(pc b)lueprompt.sh / kei$(pc n)er [g/b/N]"  'n'
	if   is G;  then install_symlink ".prompt" "prompt/gitprompt.sh"  ; break
	elif is B;  then install_symlink ".prompt" "prompt/blueprompt.sh" ; break
	elif is_no; then break ; fi
done

ask_symlink ".vimrc" "vim/vimrc"
if is_yes; then
	echo "\$ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && vim +PluginInstall +qall"
fi

while true; do
	ask "Sollen die Vim-Farben nach $(hi .vim/colors) gesymlinkt werden? [y/N/$(pc l)ist]" 'n'
	if is_yes; then
		mkdir -p $HOME/.vim/colors/
		find $HERE/vim/colors/ -type f -print0  | z xargs -0r  ln -vsft $HOME/.vim/colors/ --
		break
	elif is L;  then ls -1Alh $HERE/vim/colors/
	elif is_no; then break; fi
done

ask "Desktop-Defaults (dconf) einspielen? [y/N]" 'n'
if is_yes; then
	$HERE/dconf/dconf.pl $HERE/dconf/*.conf
fi

ask "Desktop-Defaults (ini/rc) einspielen? [y/N]" 'n'
if is_yes; then
	$HERE/cfg/confpatch.pl -b -i $HOME/.config/SpeedCrunch/SpeedCrunch.conf $HERE/cfg/speedcrunch.patch.ini
	$HERE/cfg/confpatch.pl -b -i $HOME/.config/vlc/vlcrc                    $HERE/cfg/vlcrc.patch.ini
fi

ask_symlink "bin/git-color-annotate"
if is_yes; then
	ask "Git-Aliases $(hi ann) und $(hi annot) für color-annotate anlegen? [Y/n]"  'y' 1
	if is_yes; then
		git config -f $HOME/.gitconfig-extra alias.ann   color-annotate
		git config -f $HOME/.gitconfig-extra alias.annot color-annotate
	fi
fi

# now ask about every bin/ script:
for file in $(binfiles); do
	[ "$file" = "git-color-annotate" ] && continue  # already handled

	ask_symlink "bin/$file"
done

echo ""

