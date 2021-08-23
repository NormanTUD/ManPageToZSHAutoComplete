#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $manpage = shift @ARGV;
die "Call $0 name_of_the_manpage" unless $manpage;

my %args = ();
my @man = qx(man $manpage);

my $started_description = 0;
my $last_spaces = ' ' x 1000;
my $last_arg_name = '';
my $param_re = qr/(?:--?[a-zA-Z0-9=_]+(?:$|, --?[a-zA-Z0-9=_]+)*)/;
foreach my $line (@man) {
	if($started_description) {
		if($line =~ m#^(?<spaces>\s*)(.*)#) {
			if(length($+{spaces}) > length($last_spaces)) {
				my $text = $2;
				if($args{$last_arg_name} !~ /^\s*$/) {
					if($text =~ m#^\s*[A-Z]#) {
						$args{$last_arg_name} .= ". $text";
					} else {
						$args{$last_arg_name} .= ", $text";
					}
				} else {
					$args{$last_arg_name} = $text;
				}
			}
		} else {
			$last_spaces = ' ' x 1000;
			$last_arg_name = '';
			$started_description = 0;
		}
	}

	if($line =~ m#^(?<spaces>\s*)(?<param>$param_re)(?<text>\s*.*)?#) {
		if($+{param} !~ m#^\s*$#) {
			$started_description = 1;
			$last_spaces = $+{spaces};
			$last_arg_name = $+{param};
			$args{$+{param}} = $+{text};
		}
	}
}

foreach my $name (keys %args) {
	$args{$name} =~ s#^\s*##g;
	$args{$name} =~ s#((?:.*?)\.(.*?\.)?).*#$1#g;
}

print "function _get_${manpage} {\n";
print qq#\t_describe 'command' "(\n#;
foreach my $name (keys %args) {
	my $print_name = $name;
	$print_name =~ s#\s*##g;
	if($name =~ m#,#) {
		print "\t\t{$print_name}:'".mask_text($args{$name})."'\n";
	} else {
		print "\t\t'$print_name':'".mask_text($args{$name})."'\n";
	}
}
print qq#\t)"\n#;
print "}\n";
print qq#compdef _get_${manpage} "$manpage"\n#;

sub mask_text {
	my $text = shift;
	$text =~ s#['"]##g;
	return $text;
}
