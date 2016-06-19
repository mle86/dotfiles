## [ansi.sh](ansi.sh)

Functions for colored output.

* `warn message…`  
	Prints the message to *stderr*, but in the *$ansi_warning* color.

* `good message…`  
	Prints the message, but in the *$ansi_good* color.

* `dark message…`  
	Prints the message, but in the *$ansi_dark* color.

* `hi message…`  
	Prints its arguments, but prefixed with the "bold" ansi sequence.
	It will end its output with [SGR 22](https://en.wikipedia.org/wiki/ANSI_escape_code#graphics) instead of *$ansi_reset*,
	so it can be used inline in possibly-colored strings.

* `ul message…`  
	Prints its arguments, but prefixed with the "underlined" ansi sequence.
	It will end its output with [SGR 24](https://en.wikipedia.org/wiki/ANSI_escape_code#graphics) instead of *$ansi_reset*,
	so it can be used inline in possibly-colored strings.

* `UL message…`  
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

* `ask prompt [default [preset]]`  
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
	Several test functions in [is.sh](is.sh) will use this variable as their input.


## [fail.sh](fail.sh)

* `err errorMessage…`  
	Prints the errorMessage on *stderr*.

* `fail [exitStatus=1] errorMessage`  
	Prints the errorMessage on *stderr* (using the *err()* function),
	then exits the script with *exitStatus*.


## [is.sh](is.sh)

These functions allow easy string comparisons of their argument or the *$ANSWER* envvar.
They are used in conjunction with the *ask()* function (which writes to *$ANSWER*).
They are boolean test functions which never produce any output, just a true or false return status.

* `is_yes [input=$ANSWER]`  
	Checks if the input looks like an explicit "yes" answer.
	Accepted values are `y`, `Y`, `j`, `J`, and `yes`.

* `is_no [input=$ANSWER]`  
	Checks if the input looks like an explicit "no" answer.
	Accepted values are `n`, `N`, and `no`.

* `is word [input=$ANSWER]`  
	Checks if the input equals a word, regardless of its case.
	The *$word* argument should be in upper-case, because *is()* will uppercase the input for a case-insensitive check.
	For a case-sensitive check, use *iscase()*.

* `iscase word [input=$ANSWER]`  
	Checks if the input exactly equals a word.
	This is the case-sensitive version of *is()*.

* `is_absolute_path [filename=$ANSWER]`  
 	Determines whether its argument starts with a slash (i.e. looks like an absolute path).

* `is_digits [word=$ANSWER]…`  
	Returns true if all arguments are digits-only, false otherwise.
