#!/usr/bin/perl
use strict;
use warnings;
use locale;

# usage
die "usage: $0 [bc] [sam]\n" unless @ARGV == 2;


# progress tracking
my $track = 0;
my $paired = 0;


# log skipped barcodes
#my $log = 'skipped_barcodes.txt';
#my $los = 'skipped_alignedreads.txt';
#open (my $t1, '>', $log) or die;
#open (my $t2, '>', $los) or die;


# output files
open(my $f1, $ARGV[0]) or die;
open(my $f2, $ARGV[1]) or die;
my $pair1 = read_file_line($f1);
my $pair2 = read_file_line($f2);


# track lines
my $lin1 = 1;
my $lin2 = 1;


# iterate over files
while ($pair1 and $pair2) {
	if(($lin1 % 1000000) == 0 || ($lin2 % 1000000) == 0){
		print STDERR "Current lines| $ARGV[0]:$lin1\t$ARGV[1]:$lin2 | tagged $track reads...\n";
	}
	
	if($pair1->[0] lt $pair2->[0]) {
		$paired = 0;
		$pair1 = read_file_line($f1);
		$lin1++;
	} 
	elsif($pair1->[0] gt $pair2->[0]) {
		$paired = 0;
		$pair2 = read_file_line($f2);
		$lin2++;
	} 
	elsif($pair1->[0] eq $pair2->[0]){
		$track++;
		$paired++;
		compute($pair1, $pair2);
		$pair2 = read_file_line($f2);
		$lin2++;
		if($paired == 2){
			$pair1 = read_file_line($f1);
			$lin1++;
		}
	}
}

close($f1);
close($f2);

########################################################################
## subroutines 								
########################################################################

sub read_file_line {
	my $fh = shift;
	if ($fh and my $line = <$fh>) {
		chomp $line;
		return [ split(/\s+/, $line) ];
	}
	return;
}

sub compute {
	my ($p1, $p2) = @_;
	my @col1 = @$p1;
	my @col2 = @$p2;
	my $line2 = join("\t",@col2);
	print "$line2\tCB:Z:$p1->[1]\tXC:Z:$p1->[3]\n";
}
