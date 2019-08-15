#!/usr/bin/perl
use strict;
use warnings;

my %hash;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split("\t",$_);
	my @bc = split(":",$col[11]);
	my $id = join("-", $bc[2], $ARGV[1]);
	$hash{$id}++;
}
close F;

print "barcodes\tMtPt_counts\n";
my @keys = sort {$hash{$b} <=> $hash{$a}} keys %hash;
for (my $i = 0; $i < @keys; $i++){
	print "$keys[$i]\t$hash{$keys[$i]}\n";
}
