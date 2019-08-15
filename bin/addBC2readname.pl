#!/usr/bin/perl
use strict;
use warnings;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split("\t",$_);
	my @bc = split(":",$col[21]);
	print "$bc[2]-$ARGV[1]:$_\n";
}
close F;
