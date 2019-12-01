#!/bin/sh
set -e
. $(dirname "$0")/shfn.sh

################################################################################

ask_symlink ".gitconfig" "gitconfig"
ask_symlink ".inputrc" "inputrc"
ask_symlink ".bash_aliases" "bash_aliases.sh"
ask_symlink ".rest_fn.sh" "rest_fn.sh"
ask_symlink ".templates" "templates/"

dfl_promptcolor=
ask_promptcolor=

while true; do
	ask "Welcher Prompt soll als $(hi ~/.prompt) installiert werden? $(pc g)itprompt.sh / $(pc s)impleprompt.sh / kei$(pc n)er [g/s/N]"  'n'
	if is_no; then
		break
	elif is G; then
		install_symlink ".prompt" "prompt/gitprompt.sh"
		dfl_promptcolor='5190'
		ask_promptcolor='[1m${color}❮[0m ${color}mst[0;38;5;121m*${color}${colno}[0m [1m~/[1m${color}❯[0m'
		break
	elif is S; then
		install_symlink ".prompt" "prompt/simpleprompt.sh"
		dfl_promptcolor='34'
		ask_promptcolor='[1m${colno}[0m@host:[1m~[1m${color}\$[0m'
		break
	fi
done

if [ -n "$ask_promptcolor" ]; then
	echo "[1;36m ------------------------------------------------------------------------------ [0m"
	for i in $(seq 31  37); do showcolordemo 7 $i            "[${i}m"      "$ask_promptcolor  "; done
	for i in $(seq  1 254); do showcolordemo 7 $((5000 + i)) "[38;5;${i}m" "$ask_promptcolor  "; done
	echo ""
	echo "[1;36m ------------------------------------------------------------------------------ [0m"
	echo ""

	while true; do
		ask "Welche Prompt-Farbe soll verwendet werden? [$dfl_promptcolor]" "$dfl_promptcolor"
		if [ -n "$ANSWER" ] && [ "$ANSWER" -ge 31 ] 2>/dev/null && [ "$ANSWER" -le 37 ]; then
			store_prompt_color "[${ANSWER}m"
			break
		elif [ -n "$ANSWER" ] && [ "$ANSWER" -ge 5001 ] 2>/dev/null && [ "$ANSWER" -le 5254 ]; then
			store_prompt_color "[38;5;$((ANSWER - 5000))m"
			break
		fi
	done
fi

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
	git -C $HERE/ submodule update --init cfg/confpatch/
	$HERE/cfg/confpatch.pl -b -i $HOME/.config/SpeedCrunch/SpeedCrunch.ini $HERE/cfg/speedcrunch.patch.ini
	$HERE/cfg/confpatch.pl -b -i $HOME/.config/vlc/vlcrc                   $HERE/cfg/vlcrc.patch.ini
fi

ask_symlink "bin/git-color-annotate"
if is_yes; then
	ask "Git-Aliases $(hi ann) und $(hi annot) für color-annotate anlegen? [Y/n]"  'y' 1
	if is_yes; then
		git config -f $HOME/.gitconfig-extra alias.ann   color-annotate
		git config -f $HOME/.gitconfig-extra alias.annot color-annotate
	fi
fi

ask "$(hi diff-so-fancy) als git-Pager installieren? [y/N]" 'n'
if is_yes; then
	if ! grep -q 'pager = diff-so-fancy' "$HOME/.gitconfig-extra"; then
		( cat ; echo ) >> "$HOME/.gitconfig-extra" <<-EOT
			[core]
			pager = diff-so-fancy | less --tabs=4 -R
		EOT
	fi
	if ! [ -f "$HOME/bin/diff-so-fancy" ]; then
		mkdir -vp -- "$HOME/bin/"
		wget 'https://github.com/so-fancy/diff-so-fancy/blob/master/third_party/build_fatpack/diff-so-fancy' -O "$HOME/bin/diff-so-fancy"
		chmod +x "$HOME/bin/diff-so-fancy"
	fi
fi

# now ask about every bin/ script:
for file in $(binfiles); do
	[ "$file" = "git-color-annotate" ] && continue  # already handled

	ask_symlink "bin/$file"
done

echo ""

