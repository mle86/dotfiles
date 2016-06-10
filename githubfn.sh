#!/bin/sh

GH_API_URL='https://api.github.com/repos'
GH_CO_URL='https://github.com'

# gh_is_semver string
#  Checks if the input string looks like a semantic version string.
#  A "v" prefix is allowed.
gh_is_semver () { /bin/echo "$1" | grep -q '^v\?[[:digit:]]\+\(\.[[:digit:]]\+\)\+\(-[\w\.]\+\)\?$'; }

# gh_is_semver_range string
#   Checks if the input string looks like a semantic range string,
#   e.g. "~v2.33.0".
gh_is_semver_range () { [ "$1" = "~${1#~}" ] && gh_is_semver "${1#~}"; }

# gh_resolve_semver_range package versionRange
#  Can only resolve ranges like '~major.minor' (will resolve to major.MAX)
#  or '~major.minor.patch' (will resolve to major.minor.MAX).
gh_resolve_semver_range () {
	local package="$1"
	local range="$2"

	if [ "$range" != "~${range#~}" ]; then
		echo "Invalid semver range for $package: '$range'"  >&2
		return 1
	fi

	local minver="${range#~}"  # cut "~" prefix
	minver="${minver#v}"  # cut optional "v" prefix
	minver="$(/bin/echo "$minver" | sed 's/\.[0-9]*$//')"  # remove last dot and number

	local tag="$(gh_tags "$package" | grep "^v${minver}\\(\\.\\|$\\)" | sort -r | head -n1)"
	if [ -z "$tag" ]; then
		echo "No suitable version found for $package@$range"  >&2
		return 42
	fi

	echo "$tag"
}

# gh_resolve_release package [release=latest]
#  Resolves a GitHub release name and prints the associated tag name.
#  Usually, release names and tag names are equal,
#  so this is mainly useful to resolve the "latest" special release.
gh_resolve_release () {
	local package="$1"
	local release="${2:-latest}"

	local apiResult="$(curl -s "$GH_API_URL/$package/releases/$release")"
	local tag="$(/bin/echo "$apiResult" | grep '"tag_name"' | cut -d'"' -f4)"
	if [ -z "$tag" ]; then
		local error="$(/bin/echo "$apiResult" | grep '"message"' | cut -d'"' -f4)"
		echo "Package $package@$release: ${error:-unexpected api result}"  >&2
		return 40
	elif ! gh_is_semver "$tag"; then
		echo "Package $package@$release refers to invalid tag: $tag"  >&2
		return 41
	else
		/bin/echo "$tag"
		return 0
	fi
}

# gh_alternate_semver version
#  Prints the other way to write the version number:
#  - if format MAJOR.MINOR.0,  remove the .0 suffix.
#  - if format MAJOR.MINOR,  add a .0 suffix.
#  - else return false.
gh_alternate_semver () {
	local ver="$1"
	if /bin/echo "$ver" | grep -q '^v[[:digit:]]\+\.[[:digit:]]\+$'; then
		echo "${ver}.0"
	elif /bin/echo "$ver" | grep -q '^v[[:digit:]]\+\.[[:digit:]]\+\.0$'; then
		echo "${ver%.0}"
	else
		false
	fi
}

# gh_tags package
#  Prints a list of all tags available for one package.
gh_tags () {
	local package="$1"
	curl -s "$GH_API_URL/$package/tags" | jq -r '.[].name'
}

# gh_setver [commit=UPSTREAM-HEAD [directory=.]]
#  Switches the worktree and index to a different commit.
#  Should not be used with commits from a different branch.
#  By default, it switches to the branch's upstream tracking branch tip.
gh_setver () {
	local commit="$1"
	local dir="${2:-.}"
	[ -n "$1" ] || local commit="@{u}"
	( cd -- "$dir" && git reset --hard "$commit" -- )
}

# gh_install package [release=latest [targetDir=./REPONAME]]
#  Clones a package into targetDir.
#  The release argument can be one of:
#  - a semver tag name, with optional "v" prefix, e.g. "v1.4.0".
#  - a semver ~range, with optional "v" prefix, e.g. "~v1.4.2",
#    which will resolve to the highest v1.4.* version but not to v1.5.* or higher.
#  - a github release name, in case they are different from the tag names.
#  - the special release name "latest", which will resolve to the newest release.
#  The release will be checked out with "git reset --hard",
#  so it has to be on the default branch, or weird things will happen.
#  If successful, it'll print the new repo directory on stdout.
#  All other output goes to stderr.
gh_install () {
	local package="$1"
	local release="${2:-latest}"
	local targetDir="${3:-"./$(basename -- "$package")"}"

	if gh_is_semver "$release"; then
		# is a tag name -- no resolving necessary,
		# but add the "v" prefix if missing:
		[ "$release" = "v${release#v}" ] || release="v$release"
	elif gh_is_semver_range "$release"; then
		# is a version range -- try to resolve it:
		release="$(gh_resolve_semver_range "$package" "$release")"
	elif [ "$release" = "master" ]; then
		: # is a branch name -- no resolving necessary
	else
		release="$(gh_resolve_release "$package" "$release")"
	fi

	git clone -q "$GH_CO_URL/$package" "$targetDir"  >&2
	echo "Checked out $package into ${targetDir}."  >&2
	cd "$targetDir"

	if ! gh_setver "$release" >&2; then
		# could not check out target version

		# if possible, try again with alternative version number:
		if release="$(gh_alternate_semver "$release")"; then
			gh_setver "$release" >&2
		fi
	fi

	echo "$targetDir"
}

# ask_github package [release=latest [defaultAnswer=n]]
#  Asks whether a package should be cloned from GitHub into /usr/local/src/REPONAME
#  and installed using 'make && make install'.
#  For the release argument, see gh_install().
#  The default release is 'latest', referring to the newest GitHub release tag.
ask_github () {
	local package="$1"
	local release="${2:-latest}"
	local defaultAnswer="${3:-n}"

	[ "$defaultAnswer" = "y" ] && local options='[Y/n]' || local options='[y/N]'

	ask "Installiere von GitHub $(hi $package) ($release) ? $options" "$defaultAnswer"
	if is_yes; then (
		cd /usr/local/src/

		local dir="$(gh_install "$package" "$release")"
		cd -- "$dir"

		make
		make install
	); fi
	true
}

