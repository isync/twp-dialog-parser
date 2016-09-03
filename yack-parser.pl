#!/usr/bin/perl

use strict;
use warnings;
use Path::Tiny;
use Data::Dumper;
use Term::Choose;
use Time::HiRes;
use Term::ANSIColor;

=pod

From L<http://blog.thimbleweedpark.com/drinkingfountain>:
"The format for the dialogs is pretty simple. There can be only one 1 and one 2,
etc choice, so the first one chosen is used and the others discarded.
The [random] condition makes the odds of it being chosen random. the -> label
just tells the system where you go if the choice was selected by the player.
You can refer back to L<http://blog.thimbleweedpark.com/dialog_puzzles|this post>
for more examples."

Example .yack-scripts and scripting format, Copyright Ron Gilbert 2015.


=cut

die "Please specify at least one .yack file, a dialog tree formatted as outlined on the Thimbleweed Park blog" unless @ARGV;
room();

sub parse {
	my @lines = path($_[0])->lines_utf8;

	my $dialog = { _filename => $_[0]};
	my $meta;
	my $section;
	for(@lines){
		chomp($_);
		if($_ =~ /^:/){
			$section = substr($_,1);
			push(@{ $dialog->{_sequence} }, $section);
			next;
		}
		next unless $_ ;
		next if $_ =~ /^\s+$/;
		next if $_ =~ /^#|^\/\//; # comment are # and //
		push(@{ $dialog->{$section}->{_raw} },$_);
		$dialog->{$section}->{_index} = scalar(@{ $dialog->{_sequence} });
	}

	return $dialog;
}

sub room {
	my $states = $_[0] || {}; # could be more global

	while(1){
		my $choice;
		if(@ARGV > 1){
			print "\n You're inside a developer directory.\n There are a number of .yack files here.\n\n";

			my $tc = Term::Choose->new();
			$tc->config({ layout => 3 });

			$choice = $tc->choose( \@ARGV );
		}else{
			$choice = shift @ARGV;
		}

		print "You're now talking to $choice \n\n";

		my $dialog = parse($choice);
		print Dumper($dialog);

		$states = run_conversation($dialog, $states);
		print Dumper($states);
	}
}

sub run_conversation {
	my ($dialog, $states) = @_;

	my $tc = Term::Choose->new();
	$tc->config({ layout => 3, index => 1 });

	my $section = undef;
	my $pointer = 0;

	again: {

		$section = ${ $dialog->{_sequence} }[$pointer] unless $section; # switch between sequence mode (with pointer) and directed section mode (when $section is set)
		debug("section is '$section', via pointer $pointer");

		if($section eq 'exit'){
			debug("exit via jump mark");
			return $states;
		}

		my @choice;
		my @goto;
		my $speaker;
		for (@{ $dialog->{$section}->{_raw} }){
			if($_ =~ /^!/){
				if($_ =~ /\s=\s/){
					my ($var,$value) = split(/\s=\s/, substr($_,1));
					debug("set var $var to $value");
					$states->{$var} = $value;
				}elsif($_ =~ /!\+\+/){
					my ($value,$var) = split(/\+\+/, substr($_,1));
					debug("increment var (prepended ++) $var");
					$states->{$var}++;
				}elsif($_ =~ /\+\+/){
					my ($var,$value) = split(/\+\+/, substr($_,1));
					debug("increment var $var");
					$states->{$var}++;
				}elsif($_ =~ /!\-\-/){
					my ($value,$var) = split(/\-\-/, substr($_,1));
					debug("decrement var (prepended --) $var");
					$states->{$var}--;
				}elsif($_ =~ /\-\-/){
					my ($var,$value) = split(/\-\-/, substr($_,1));
					debug("decrement var $var");
					$states->{$var}--;
				}else{
					debug("variable operation unknown");
				}
			}elsif($_ =~ /^pause\s([0-9\.]+)/){
				debug("command: pause for $1");
				Time::HiRes::sleep($1 * 1);
			}elsif($_ =~ /^(\d+)\s(.*)/){	# choices
				my ($number, $text) = ($1,$2);
				if($text =~ /\s\[(\w+)\]/){
					my $condition = $1;
					debug("condition on choice: $condition");
					if($condition eq 'once' || $condition eq 'showonce'){
		print Dumper($states);
						next if $states->{ $dialog->{_filename} }->{$section}->[$number] ; # todo: keep track of 
						$states->{ $dialog->{_filename} }->{$section}->[$number]++;
					}elsif($condition =~ /([^\s]+)\s==\s(.*)/){
						my ($var,$value) = ($1,$2);
						debug("condition on choice: variable check: var:$var, value:$value");
						next if $states->{ $dialog->{_filename} }->{$section}->[$number] != $value;
					}
				}
				if($text =~ /\-\>/){
					($text, my $goto) = split(/\s?\-\>\s/,$text);
					push(@goto,$goto);
				}
				push(@choice, $text) if $number > scalar(@choice);
			}elsif($_ =~ /^->/){
				(my $markup, my $goto) = split(/\s?\-\>\s/,$_);
				die "section '$goto' is not defined!" unless defined($dialog->{ $goto });
				$section = $goto;
				$pointer = $dialog->{ $goto }->{_index};
				debug("jump mark: to section '$goto' (which is index $pointer)");
				goto again;
			}elsif($_ =~ /^exit/){
				debug("exit: end conversation");
				return $states;
			}else{
				my $speaker_end = index($_, ':  ');
				my $text;
				if($speaker_end > 0){
					$speaker = substr($_,0,$speaker_end);
					$text = substr($_, $speaker_end+3);
					debug("dialog line: has speaker till $speaker_end, text is ". ($text||''));
				}else{
					$text = substr($_,4);
				}
				speak($speaker,$text);
				Time::HiRes::sleep(1);
			}
		}

		if(@choice){
			print "\n";
			print Dumper(\@goto);
			my $choice = $tc->choose( \@choice );

			$states->{ $dialog->{_filename} }->{$section}->[$choice]++;

			$section = $goto[$choice];

			debug("you chose $choice: goto '$section'");
			speak('You', $choice[$choice]);
		}else{
			$section = undef;
			$pointer++;
			debug("no choice or command found, incrementing pointer to $pointer");
		}

		print Dumper($states);

		goto again;
	}

	return $states;
}


sub speak {
	my ($speaker,$text) = @_;
	my @colors = qw(red green blue yellow magenta cyan white bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white);
	print colored($speaker, $colors[length($speaker)]) .'> '. $text ."\n";
}

sub debug {
	my $debug = 1;
	print colored("  DEBUG: $_[0] \n",'bright_black') if $debug;
}
