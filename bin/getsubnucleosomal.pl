#!/usr/bin/perl
use strict;
use warnings;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split("\t",$_);
	my $fragment = abs($col[8]);
	if($fragment < 150){
		print "$_\n";
	}
}
close F;
