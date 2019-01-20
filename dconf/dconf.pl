#!/usr/bin/perl -w
use IPC::System::Simple qw(systemx);

# syntax: dconf.pl [-n|--dry-run] [INPUTFILES=-]...

die "dconf not found"  if (0 != system "command -v dconf >/dev/null");

our $errors = 0;
our $dry_run = 0;
if (defined $ARGV[0] && ($ARGV[0] eq '-n' || $ARGV[0] eq '--dry-run')) {
	$dry_run = 1;
	shift @ARGV;
}

if ($#ARGV < 0) { @ARGV = ('-'); }

for (my $a = 0; $a <= $#ARGV; $a++) {
	apply_file($ARGV[$a]);
}

exit ($errors ? 1 : 0);


sub apply_file {
	my $filename = $_[0];
	open FH, "< ${filename}";
	while (defined ($_ = <FH>)) {
		my $linedesc = "${filename}:$.";
		next if m/^\s*#/;  # ignore comments
		next if m/^\s*$/;  # ignore blank lines
		if (!m/^\s*(\/[^\s:]+)\s+(\S.*?)\s*$/) {
			printf STDERR "${linedesc}: malformed line\n";
			$errors++;
			next;
		}
		apply_line($1, $2, $linedesc);
	}
	print "\n";
	close FH;
}

sub apply_line {
	my ($key, $value, $linedesc) = @_;
	print ".";

	return if $dry_run;

	systemx('dconf', ('write', $key, $value));
}

