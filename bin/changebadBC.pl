#!/usr/bin/perl
use strict;
use warnings;

die "usage: $0 [correctedbarcodes] [ambiguous_bc.txt] > STDOUT \n" unless @ARGV == 2;

# correction hash
my %hash;
my %id;

# load corrections
open F, $ARGV[0] or die;
while(<F>){
	chomp;
	if($_ =~ /ambiguous/){
		next;
	}
	else{
		my @col = split("\t",$_);
		$hash{$col[0]} = $col[1];
		$id{$col[0]} = $col[2];
	}
}
close F;

# iterate over reads
open G, $ARGV[1] or die;
while(<G>){
	chomp;
	my @col = split("\t",$_);
	if(exists $hash{$col[1]}){
		print "$col[0]\t$hash{$col[1]}\t$col[1]\t$id{$col[1]}\n";
	}
}
close G;
