#!/usr/bin/perl
use strict;
use warnings;
use Sort::Naturally;

# usage
die "usage: $0 <white_list_bc> <sequenced_bc.txt> <outputid>" unless @ARGV == 3;


# save BC data
my %hash;

# load barcodes
open F, $ARGV[0] or die;
while(<F>){
	chomp;
	$hash{$_} = 1;
}
close F;

# output files
my $t1 = $ARGV[2] . '.ambiguous_bc.txt';
my $t2 = $ARGV[2] . '.matched_bc.txt';
my $t3 = $ARGV[2] . '.matched_bc_counts.txt';
my $t4 = $ARGV[2] . '.ambiguous_bc_counts.txt';

open (my $z1, '>', $t1) or die;
open (my $z2, '>', $t2) or die;
open (my $z3, '>', $t3) or die;
open (my $z4, '>', $t4) or die;

# count files
my %obsm;
my %obsa;


# iterate over I5 seq
open G, $ARGV[1] or die;
while(<G>){
	chomp;
	my @col = split("\t",$_);
	my $revc = rc($col[1]);
	my $id = join("\t", $col[1], $revc, $col[2]);
	if(exists $hash{$revc} || exists $hash{$col[1]}){
		$obsm{$id}++;
		print $z2 "$col[0]\t$col[1]\t$revc\t$col[2]\n";
	}
	else{
		$obsa{$id}++;
		print $z1 "$col[0]\t$col[1]\t$revc\t$col[2]\n";	
	}
}
close G;
close $z1;
close $z2;

# print barcode counts
my @keys1 = nsort keys %obsm;
for (my $i = 0; $i < @keys1; $i++){
	print $z3 "$keys1[$i]\t$obsm{$keys1[$i]}\n";
}
close $z3;

my @keys2 = nsort keys %obsa;
for (my $i = 0; $i < @keys2; $i++){
	print $z4 "$keys2[$i]\t$obsa{$keys2[$i]}\n";
}
close $z4;

## subroutines
sub rc {
	my ($seq) = @_;
	$seq =~ tr/ATCGN/TAGCN/;
	my $revc = reverse($seq);
	return($revc);
}
