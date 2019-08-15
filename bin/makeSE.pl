#!/usr/bin/perl
use strict;
use warnings;

my %hash;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split("\t",$_);
	my $end = $col[3] + length($col[9]);
	print "$col[2]\t$col[3]\t$end\t$col[11]\n";
}
close F;
