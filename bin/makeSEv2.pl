#!/usr/bin/perl
use strict;
use warnings;

my %hash;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split("\t",$_);
	my $end = $col[3] + length($col[9]);
	my $bc;
	my $cb;
	foreach(@col){
		if($_ =~ /^CB:Z/){
			$bc = substr($_, 0, (length($_)-2));
			last;
		}
	}
	if($bc){
		print "$col[2]\t$col[3]\t$end\t$bc-$ARGV[1]\n";
	}
}
close F;
