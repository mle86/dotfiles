This is my `~/bin/` directory.
It contains small shell and Perl scripts.

* **ds:**
	This is a glorified variant of "*du -sh * | sort --human-numeric-sort*".
	All it does is list the current directory's contents, summarize their sizes, and sort by size (smallest first).
	Also, the K/M/G/T suffixes are will be colored differently,
	indentation will line up nicely,
	directories will be colored blue in the output,
	and backup files (\*~, \*.bak, \*.bkup, \*.swp) will be colored dark grey.
	Really useful to get an overview which directories are hogging the hard disk space now.
	\
	Syntax: `ds [DIRECTORY=.]`

* **fn:**
	This is an abbreviation for "*find . (-name $1 -or -name $2 -or …)*".
	It can also handle additional *find* options (after a single comma).
	\
	Syntax: `fn [-i] PATTERN... [, FINDOPTS...]`
	\
	The *-i* option causes *find* to use the *-iname* option (instead of *-name*) for all pattern arguments,
	i.e. it makes the process case-insensitive.

* **g:**
	An abbreviation for "*grep --line-number --with-filename --ignore-case --color=always*".
	Also, it allows for simple entry of multiple grep patterns.
	Since it is just a *grep* wrapper, it will match *stdin* if no *FILENAME*s are given (or if one of them is *-*).
	\
	Syntax:
	* `g [GREPOPTION...] PATTERN      [FILENAME...]` (This will search for the *PATTERN* in the *FILENAME*s, or in *stdin*.)
	* `g [GREPOPTION...] PATTERN... , [FILENAME...]` (This will search for any of the *PATTERN*s in the *FILENAME*s, or in *stdin*.)

* **keep-n-files:**
	This will remove the oldest files in *DIR* so that only *N* files remain.
	Alternatively, it can take a list of *FILENAME*s, in which case it will delete the oldest of them until only *N* files remain.
	If there's less than *N* files present, nothing will be deleted.
	\
	Syntax:
	* `keep-n-files [-n] N DIR`
	* `keep-n-files [-n] N FILENAME...`

* **nocmt:**
	A simple *grep* abbreviation to filter shell scripts and similar files:
	It will remove all empty lines, all whitespace-only lines,
	and all lines whose first non-whitespace symbol is a hash (*#*).
	Like grep, it can take one or multiple filenames, or it'll simply filter *stdin*.
	\
	Syntax: `nocmt [FILENAME...]`

* **params:**
	This might be useful to debug other shell scripts which do a lot of argument processing or are involved with `$IFS` magic.
	It will simply show a numbered list of its command line arguments,
	one line each,
	all of them enclosed in colored square brackets to avoid spacing ambiguity.
	\
	Syntax: `params [ARGUMENT...]`

* **reify:**
	This Perl script converts symlinks to actual files by copying their link destination.
	Symlinked directories will be copied recursively.
	\
	Syntax: `reify [-dqv] FILENAME...`
	* *-d*, *--flat*: Directories won't be copied recursively,
			but filled with symlinks to the original directories' contents.
	* *-q*, *--quiet*: Ignore non-symlink files,
			don't report mode/ownership problems.
	* *-v*, *--verbose*: Report every copied file.

* **u:**
	This is a "*id $(getent passwd $1)*" wrapper:
	It takes a User ID argument
	and looks up the account's username.
	\
	Syntax: `u [-n] UID`
	\
	The *-n* option causes *u* just to print the username
	instead of calling the *id* program with it.

