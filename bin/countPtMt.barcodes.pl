#!/usr/bin/perl
use strict;
use warnings;

my %pt;
my %mt;
my %both;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split("\t",$_);
	my $id = join("-", $col[15], $ARGV[1]);
	if($col[2] eq 'Pt'){
		$pt{$id}++;		
	}elsif($col[2] eq 'Mt'){
		$mt{$id}++;
	}
	$both{$id}++;
}
close F;

my @keys = sort {$both{$b} <=> $both{$a}} keys %both;
for (my $i = 0; $i < @keys; $i++){
	print "$keys[$i]\t";
	if(exists $pt{$keys[$i]}){
		print "$pt{$keys[$i]}\t";
	}else{
		print "0\t";
	}
	if(exists $mt{$keys[$i]}){
		print "$mt{$keys[$i]}\n";
	}else{
		print "0\n";
	}
}
