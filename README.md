This is my personal dotfiles repository.


## Installation

```sh
cd ~  && git clone https://github.com/mle86/dotfiles .dotfiles/  && .dotfiles/install.sh
```

Run *[install.sh](install.sh)* to start the installation process.
Every installation step asks for manual confirmation
and every prompt default is 'no',
so it's safe to run the installation script and hit Enter a few times
just to see what it would do.

If you just want to copy the `bin/` scripts
to `/usr/local/bin/`,
run *[root-install.sh](root-install.sh)*.
It will ask about every bin/ script file,
always defaulting to 'no'.

*root-install.sh* will also install some of my other GitHub projects
by cloning them into `/usr/local/src`
and running `make && make install` on them.


## [bin/](bin/)

This is my `~/bin/` directory.
It contains small shell and Perl scripts.

* **[ds](bin/ds):**  
	This is a prettier variant of "*du -sh * | sort*".
	All it does is list the current directory's contents, summarize their sizes, and sort by size (smallest first).
	Also, the K/M/G/T suffixes will be colored differently,
	indentation will line up nicely,
	directories will be colored blue in the output,
	and backup files (\*~, \*.bak, \*.bkup, \*.swp) will be colored dark grey.
	Really useful to get an overview about which directories are hogging the hard disk space now.  
	Syntax: `ds [DIRECTORY=.]`

* **[fn](bin/fn):**  
	This is an abbreviation for "*find . (-name $1 -or -name $2 -or …)*".
	It can also handle additional *find* options (after a single comma).  
	Syntax: `fn [-i] PATTERN... [, FINDOPTS...]`  
	The *-i* option causes *find* to use the *-iname* option (instead of *-name*) for all pattern arguments,
	i.e. it makes the process case-insensitive.

* **[g](bin/g):**  
	An abbreviation for "*grep --line-number --with-filename --ignore-case --color=always*".
	Also, it allows for simple entry of multiple grep patterns.
	Since it is just a *grep* wrapper, it will read *stdin* if no *FILENAME*s are given (or if one of them is `-`).  
	Syntax:
	* `g [GREPOPTION...] PATTERN      [FILENAME...]` (This will search for the *PATTERN* in the *FILENAME*s, or in *stdin*.)
	* `g [GREPOPTION...] PATTERN... , [FILENAME...]` (This will search for any of the *PATTERN*s in the *FILENAME*s, or in *stdin*.)

* **[git-color-annotate](bin/git-color-annotate):**  
	This is a *git-annotate* variant which has colorized output.  
	If *stdout* is a tty, this script will launch the *less* pager.
	Syntax:
	* `git color-annotate [ANNOTATE-OPTIONS] filename`  
		Works like *git-annotate*, but has colorized output.
		This mode is chosen if there are any cmdline arguments,
		which are all passed to a real *git-annotate* child process.
	* `git color-annotate < input`  
		Works as colorizing filter for existing *git-annotate* output.
		This mode is chosen if there are no cmdline arguments
		and if *stdin* is a file or a pipe (but not a tty).

* **[keep-n-files](bin/keep-n-files):**  
	This will remove the oldest files in *DIR* so that only *N* files remain.
	Alternatively, it can take a list of *FILENAME*s, in which case it will delete the oldest of them until only *N* files remain.
	If there's less than *N* files present, nothing will be deleted.  
	Syntax:
	* `keep-n-files [-n] N DIR`
	* `keep-n-files [-n] N FILENAME...`

* **[nocmt](bin/nocmt):**  
	A simple *grep* abbreviation to filter shell scripts and similar files:
	It will remove all empty lines, all whitespace-only lines,
	and all lines whose first non-whitespace symbol is a hash (*#*).
	Like grep, it can take one or multiple filenames, or it'll simply read *stdin*.  
	Syntax: `nocmt [FILENAME...]`

* **[params](bin/params):**  
	This might be useful to debug other shell scripts which do a lot of argument processing or are involved with `$IFS` magic.
	It will simply show a numbered list of its command line arguments,
	one line each,
	all of them enclosed in colored square brackets to avoid spacing ambiguity.  
	Syntax: `params [ARGUMENT...]`

* **[reify](bin/reify):**  
	This Perl script converts symlinks to actual files by copying their link destination.
	Symlinked directories will be copied recursively.  
	Syntax: `reify [-dqv] FILENAME...`  
	* *-d*, *--flat*: Directories won't be copied recursively,
			but filled with symlinks to the original directories' contents.
	* *-q*, *--quiet*: Ignore non-symlink files,
			don't report mode/ownership problems.
	* *-v*, *--verbose*: Report every copied file.

* **[rest](bin/rest):**  
	A tiny *curl* wrapper for REST API tests.
	Also see the *rest_auth* and *rest_header* aliases in [rest_fn.sh](rest_fn.sh).  
	Has colored output
	(HTTP headers: dark grey;
	 HTTP status: 2xx green, 4xx red, 5xx purple, 3xx/1xx yellow, else red bg).
	Only the response body goes to *stdout*,
	everything else (error messages or HTTP status and headers) goes to *stderr*,
	so the response body can be redirected or piped to, say, `jq .`
	without any syntax issues.  
	Syntax:
	* `rest [-OPTIONS...] METHOD URL [JSONDATA]`
	* `rest [-OPTIONS...] METHOD URL @JSONDATAFILENAME`

* **[ts](bin/ts):**  
	Prints the current UNIX timestamp.  
	This only reason for this not to be a one-line shell alias
	is that it can be run with *watch*.


## Some of the less-boring aliases and functions in [.bash_aliases](bash_aliases.sh)

* **keep:** `IGNOREEOF=99`  
	This causes the bash shell to ignore Ctrl-D logouts.
* **c99:** `gcc -O -std=c99 -Wall -Wextra -pedantic`
* **ga:** `git add -p`
* **gd:** `git diff --diff-algorithm=minimal`
* **gdc:** `git diff --diff-algorithm=minimal --cached`

* **tf:**
	A *tail -n0 -f* abbreviation.  
	Syntax: `tf [LOGFILE=/var/log/syslog]...`

* **todo:**
	Greps all files in the current directory for "TODO".
	Greps in other directories instead if there are any directory arguments.
	Also greps all plain files which are given as arguments.  
	Syntax: `todo [TARGET=.]...`

* **grepf:**
	A combination of *find -name* and *grep*.
	Uses the *[~/bin/g](bin/g)* script.  
	Syntax: `grepf FILEPATTERN [GREPOPTIONS...] GREPPATTERNS...`  
	Example: `grepf '*.php' '<? '` to find all usages of the obsolete short opening tag.

* **dx:**
	A *docker exec* shortcut.  
	(Without any arguments, it lists the currently-running containers (`docker ps`).)  
	Syntax: `dx CONTAINERNAME [COMMAND=$SHELL]`

* **T:**
	Creates a new file from a template in *[~/.templates/](templates/)*, then opens it with vim.  
	Existing files will simply be opened, not overwritten.  
	Syntax: `T [FILENAME=test.sh]`


## The REST API toolkit aliases in [.rest\_fn.sh](rest_fn.sh)

* **rest\_auth:**
	Sets HTTP Basic Auth data for [rest](bin/rest) calls.
	Writes to the *$MY_REST_AUTH_DATA* env var
	(which is not exactly well-hidden),
	so it will last until the current shell is closed.  
	Syntax:
	* `rest_auth USERNAME:PASSWORD` (to set)
	* `rest_auth` (to view)
	* `rest_auth -` (to clear)

* **rest\_header:**
	Sets HTTP Basic Auth data for [rest](bin/rest) calls.
	Operates on the *$MY_REST_HEADER_$n*
	and *$MY_REST_HEADER_VALUE_$n*
	env vars,
	so the effect will last until the current shell is closed.  
	Syntax:
	* `rest_header HEADERNAME HEADERVALUE` (to set/overwrite one header)
	* `rest_header HEADERNAME` (to clear one header)
	* `rest_header` (to view all set headers)


## [shfn/](shfn/)

This directory contains shell functions I use in this and some other projects.
They are collected here so I don't lose/forget them.
Most projects will still use them through copy&paste, though,
because including this whole repo as a submodule just for one or two shell functions would be excessive.

The directory contains its own [README file](shfn/README.md).

