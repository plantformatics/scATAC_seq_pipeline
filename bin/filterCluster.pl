#!/usr/bin/perl
use strict;
use warnings;

my %hash;
my %clusts;

my $it = 0;
open F, $ARGV[0] or die;
while(<F>){
	$it++;
	if($it == 1){
		next;
	}
	chomp;
	my @col = split("\t",$_);
	push(@{$hash{$col[10]}},$col[0]);
	$clusts{$col[10]}++;
}
close F;

my @groups = sort {$clusts{$b} <=> $clusts{$a}} keys %clusts;
for (my $i = 0; $i < @groups; $i++){
	if($clusts{$groups[$i]} >= 100){
		my @cells = @{$hash{$groups[$i]}};
		foreach(@cells){
			print "$_\t$groups[$i]\n";
		}
	}
}

