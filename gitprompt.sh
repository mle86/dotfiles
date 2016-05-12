#!/bin/sh


###  Prompt:  ####################################################

if [ "$USER" != "root" ]; then
	PROMPT_COMMAND=_setprompt
fi

_setprompt () {
	local errstate="$?"

	local symbol_color='\[[1;38;5;226m\]'
	local symbol_err_color='\[[1;38;5;208m\]'
	local info_color='\[[0;38;5;226m\]'
#	local user_color='\[[0;38;5;256m\]'
#	local host_color='\[[0;37m\]'
	local cwd_color='\[[1;37m\]'
	local sgr0='\[[0m\]'

	local local_commits=
	local remote_commits=
	local changes=
	local local_commits_color=$info_color
	local remote_commits_color='\[[0;38;5;160m\]'
	local changes_color='\[[0;38;5;121m\]'

	local branch_color=$info_color
	local branch=$(git rev-parse  --abbrev-ref HEAD  2>/dev/null)

	branch=$(_shorten_git_branch "${branch}")

	if [ -n "$branch" ]; then
		changes=$(git status  --porcelain  --untracked-files=no  2>/dev/null)
		changes=${changes:+"$changes_color*"}
		changes=${changes:-" "}

		branch="$branch_color$branch"
		read -r _remote_ahead _local_ahead < <(git rev-list  --count  --left-right @{u}...  2>/dev/null)
		[ -n "$_local_ahead" ]  && [ "$_local_ahead"  -gt 0 ] && local_commits="$local_commits_color$_local_ahead "
		[ -n "$_remote_ahead" ] && [ "$_remote_ahead" -gt 0 ] && remote_commits="$remote_commits_color$_remote_ahead "
	fi

	local prefix_color=$symbol_color
	local suffix_color=$symbol_color
	[ "$errstate" -ne 0 -a "$errstate" -ne 130 ] && \
		suffix_color=$symbol_err_color
		# last command returned something else than zero or 130 (killed by SIGINT)

	local prefix="$prefix_color❮ "
	local suffix="$suffix_color❯ "

	PS1="$prefix$branch$changes$remote_commits$local_commits$cwd_color\\w$suffix$sgr0"

	# show current path in terminal headline:
	case "$TERM" in
	xterm*|rxvt*)
		# print term title info directly on terminal, does not count towards prompot length, cannot use \w:
#		echo -n "]0;:" ; pwd ; echo -ne "\a"

		# or include term title info in prompt output, needs \[ escaping for prompt length, can use \w:
		PS1="\[]0;\u@\h:\w\a\]$PS1"
	;;
	esac
}

_shorten_git_branch () {
	case "$1" in
		master)
			echo "mst"
			;;
		revision-*)
			echo "r-${1#*-}"
			;;
		feature-*)
			echo "f-${1#*-}"
			;;
		*)
			echo "$1"
			;;
	esac
}

