# dotfiles/shfn/

This directory contains shell functions I use in this and some other projects.


## [ansi.sh](ansi.sh)

Functions for colored output.

* <code><b>warn</b> message…</code>  
	Prints the message to *stderr*, but in the *$ansi_warning* color.

* <code><b>good</b> message…</code>  
	Prints the message, but in the *$ansi_good* color.

* <code><b>dark</b> message…</code>  
	Prints the message, but in the *$ansi_dark* color.

* <code><b>hi</b> message…</code>  
	Prints its arguments, but prefixed with the "bold" ansi sequence.
	It will end its output with [SGR 22](https://en.wikipedia.org/wiki/ANSI_escape_code#graphics) instead of *$ansi_reset*,
	so it can be used inline in possibly-colored strings.

* <code><b>ul</b> message…</code>  
	Prints its arguments, but prefixed with the "underlined" ansi sequence.
	It will end its output with [SGR 24](https://en.wikipedia.org/wiki/ANSI_escape_code#graphics) instead of *$ansi_reset*,
	so it can be used inline in possibly-colored strings.

* <code><b>UL</b> message…</code>  
	Prints its arguments, but prefixed with the "underlined" and "bold" ansi sequences.
	This is a combination of *hi()* and *ul()*.

* `$ansi_warning`
	The ANSI sequence for orange, bold text.
	*warn()* uses this.
* `$ansi_good`
	The ANSI sequence for green, bold text.
	*good()* uses this.
* `$ansi_dark`
	The ANSI sequence for dark-grey text.
	*dark()* uses this.
* `$ansi_reset`
	The ANSI sequence which resets all output attributes ([SGR 0](https://en.wikipedia.org/wiki/ANSI_escape_code#graphics)).


## [ask.sh](ask.sh)

* <code><b>ask</b> prompt [default [preset]]</code>  
	Shows a *prompt* to the user and waits for input.
	The user input is saved in the *$ANSWER* envvar.
	
	If the user input is empty because the user simply pressed Enter,
	*$ANSWER* will be set to *default* instead.
	If there is an EOF condition (because the user hit Ctrl-D),
	the function will print a newline and return with an error status.
	
	If *preset* is set, the function will _not_ wait for user input,
	but set *$ANSWER* to *preset* and continue immediately.
	(*preset* can also be set to "default", in which case *$ANSWER*
	 will be set to *default* immediately.)  
	This might be interesting for scripts which support both a
	user-input mode and an "automated" mode.
	
	Returns false (1) if there was an EOF condition,
	true otherwise.

* `$ANSWER`  
	Where *ask()* will store the user input.
	Several test functions in [is.sh](#issh) will use this variable as their input.


## [fail.sh](fail.sh)

* <code><b>err</b> errorMessage…</code>  
	Prints the errorMessage on *stderr*.

* <code><b>fail</b> [exitStatus=1] errorMessage</code>  
	Prints the errorMessage on *stderr* (using the *err()* function),
	then exits the script with *exitStatus*.


## [is.sh](is.sh)

These functions allow easy string comparisons of their argument or the *$ANSWER* envvar.
They are used in conjunction with the *[ask](#asksh)()* function (which writes to *$ANSWER*).  
They are boolean test functions which never produce any output, just a true or false return status.

* <code><b>is_yes</b> [input=$ANSWER]</code>  
	Checks if the input looks like an explicit "yes" answer.
	Accepted values are `y`, `Y`, `j`, `J`, and `yes`.

* <code><b>is_no</b> [input=$ANSWER]</code>  
	Checks if the input looks like an explicit "no" answer.
	Accepted values are `n`, `N`, and `no`.

* <code><b>is</b> word [input=$ANSWER]</code>  
	Checks if the input equals a word, regardless of its case.
	The *$word* argument should be in upper-case, because *is()* will uppercase the input for a case-insensitive check.
	For a case-sensitive check, use *iscase()*.

* <code><b>iscase</b> word [input=$ANSWER]</code>  
	Checks if the input exactly equals a word.
	This is the case-sensitive version of *is()*.

* <code><b>is_absolute_path</b> [filename=$ANSWER]</code>  
 	Determines whether its argument starts with a slash (i.e. looks like an absolute path).

* <code><b>is_digits</b> [word=$ANSWER]…</code>  
	Returns true if all arguments are digits-only, false otherwise.


## [misc.sh](misc.sh)

* <code><b>remove_trailing_slashes</b> string</code>  
	Removes any trailing slashes in the string, if there are any,
	and prints the result.

* <code><b>indent</b> [level=2]</code>  
	Prints its stdin input.
	Every line will be prefixed with *level* leading spaces.
	(If *level* is not a number, it will be used as the indentation string.)  
	This function needs the *is_digits()* test function from [is.sh](#issh).

* <code><b>suffix</b> word…</code>  
	Prints its stdin input.
	The function arguments will be appended to every line (with spaces in between).
	No extra space will be printed between the line end and the function's first argument.

* <code><b>replace</b> filename [fileMode] < content</code>  
	Overwrites a file with new content.
	The process is atomic because the function will write stdin to a temporary file in the same directory first,
	then rename the temporary file to the target name with `mv -f`.  
	If *fileMode* is set, the file's mode will be set to that value using *chmod(1)*.  
	If *fileMode* is not set and the file already existed, its mode won't be changed.  
	If *fileMode* is not set and the file did not already exist, its mode will be set to *0666 - umask*.

* <code><b>define</b> [-t] varname < input</code>  
	Assigns its *stdin* input to a variable.
	Similar to the *read* builtin, but it does not care about newlines.
	This is useful to assign a heredoc to a variable.  
	If trailing newlines should be preserved, use the *-t* option.
	Without that option, _all_ trailing newline characters will be removed,
	similar to `$(...)` assignments.
	Note that the *-t* option will still remove _one_ trailing newline character (if present).  
	Returns true if *stdin* was readable, false otherwise (in this case, *$varname* is not changed).

