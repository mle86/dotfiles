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
