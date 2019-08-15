#!/usr/bin/perl
use strict;
use warnings;

my %hash;

my $reads = 0;
open F, $ARGV[0] or die;
while(<F>){
	chomp;
	$reads++;
	if(($reads % 1000000) == 0){
		print STDERR "$reads processed\n";
	}
	my @col = split("\t",$_);
	my $cb;
	my $xc;
	foreach(@col[11..$#col]){
		if($_ =~ /CB:Z:/){
			$cb=$_;
		}
		elsif($_ =~ /XC:Z:/){
			$xc=$_;
		}
	}
	my $tag = join("_", $cb,$xc);
	$hash{$tag}++;
}
close F;

my @bc = sort {$hash{$b} <=> $hash{$a}} keys %hash;
for (my $i = 0; $i < @bc; $i++){
	print "$bc[$i]\t$hash{$bc[$i]}\n";
}
