#!/bin/sh

###  Git-Prompt:  ################################################

if [ "$USER" != "root" ]; then
	PROMPT_COMMAND=_setgitprompt
fi

_gitinfo () {
	local local_commits=
	local remote_commits=
	local changes=
	local rebase_commit=
	local branch=$(git rev-parse  --abbrev-ref HEAD  2>/dev/null)

	if [ "$branch" = "HEAD" ]; then
		local gitdir=$(git rev-parse  --git-dir)
		local current_commit=$(git rev-parse  --short HEAD  2>/dev/null)
		if [ -d "$gitdir/rebase-merge/" ]; then
			# it's an interactive rebase
			branch=$(git rev-parse  --abbrev-ref "$(cat -- "$gitdir/rebase-merge/head-name")")
			rebase_commit="$current_commit"
		elif [ -z "$current_commit" ]; then
			# it's a fresh repo
			branch="INIT"
		else
			# detached head
			branch=$current_commit
		fi
	fi

	if [ -n "$branch" ]; then

		if changes=$(git status  --porcelain  --untracked-files=no  2>/dev/null | sed q) && [ -n "$changes" ]; then
			changes="changes"
		elif git status  --porcelain --untracked-files=normal  2>/dev/null  | grep -q '^?? '; then
			changes="untracked"
		fi

		local _remote_ahead=
		local _local_ahead=
		local IFS=$'\t '
		read -r _remote_ahead _local_ahead < <(git rev-list  --count  --left-right @{u}...  2>/dev/null)
		[ -n "$_local_ahead"  ] && [ "$_local_ahead"  -gt 0 ] && local_commits="$_local_ahead"
		[ -n "$_remote_ahead" ] && [ "$_remote_ahead" -gt 0 ] && remote_commits="$_remote_ahead"
	fi

	echo -e "$changes:$local_commits:$remote_commits:$rebase_commit:$branch"
}

_setgitprompt () {
	local errstate="$?"

	local symbol_color='\[[1;38;5;226m\]'
	local symbol_err_color='\[[1;38;5;208m\]'
	local info_color='\[[0;38;5;226m\]'
#	local user_color='\[[0;38;5;256m\]'
#	local host_color='\[[0;37m\]'
	local cwd_color='\[[1;37m\]'
	local sgr0='\[[0m\]'

	local local_commits_color=$info_color
	local branch_color=$info_color
	local remote_commits_color='\[[0;38;5;160m\]'
	local changes_color='\[[0;38;5;121m\]'
	local untracked_color='\[[1;38;5;88m\]'
	local rebase_commit_color='\[[0;38;5;141m\]'

	local changes= local_commits= remote_commits= rebase_commit= branch=
	IFS=':' read changes local_commits remote_commits rebase_commit branch < <(_gitinfo)

	if   [ "$changes" = "changes"   ]; then changes="${changes_color}*"
	elif [ "$changes" = "untracked" ]; then changes="${untracked_color}·"
	else changes=" "; fi

	[ -n "$branch" ] && branch="$branch_color$(_shorten_git_branch "$branch")"
	[ -n "$rebase" ] && rebase=" $rebase_commit_color$rebase"
	[ -n "$remote_commits" ] && remote_commits="$remote_commits_color$remote_commits "
	[ -n "$local_commits" ] && local_commits="$local_commits_color$local_commits "

	local prefix_color="$symbol_color"
	local suffix_color="$symbol_color"
	[ "$errstate" -ne 0 -a "$errstate" -ne 130 ] && \
		suffix_color=$symbol_err_color
		# last command returned something else than zero or 130 (killed by SIGINT)

	local prefix="$prefix_color❮ "
	local suffix="$suffix_color❯ "

	PS1="$prefix$branch$rebase$changes$remote_commits$local_commits$cwd_color\\w$suffix$sgr0"

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
		master)		echo "mst" ;;
		hotfix/*)	echo "H/${1#*/}" ;;
		release/*)	echo "r/${1#*/}" ;;
		feature/*)	echo "f/${1#*/}" ;;
		hotfix-*)	echo "H-${1#*-}" ;;
		release-*)	echo "r-${1#*-}" ;;
		feature-*)	echo "f-${1#*-}" ;;
		*)		echo "$1" ;;
	esac
}

