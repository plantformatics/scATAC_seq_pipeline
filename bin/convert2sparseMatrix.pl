#!/usr/bin/perl
use strict;
use warnings;

# output file names
my $t1 = 'barcodes.tsv';
my $t2 = 'peaks.tsv';
my $t3 = 'matrix.mtx';

open (my $a1, '>', $t1) or die;
open (my $a2, '>', $t2) or die;
open (my $a3, '>', $t3) or die;


# determine total counts
open F, $ARGV[0] or die;
my @file = <F>;
close F;
my $genes = @file - 1;
my $total = 0;
foreach(@file){
	if($_ =~ /^gene/){
		my @line = split("\t",$_);
		foreach my $sitecell (@line[1..$#line]){
			if($sitecell > 0){
				$total++;
			}
		}
	}
}


# print matrix.mtx header
print $a3 "%%MatrixMarket matrix coordinate integer general\n%\n";


# iterate over matrix
my $it = 0;
open F, $ARGV[0] or die;
while(<F>){
	$it++;
	chomp;
	my @col = split("\t",$_);
	if($it == 1){
		my $num = @col;
		print $a3 "$genes $num $total\n";
		foreach(@col){
			print $a1 "$_\n";
		}
	}
	else{
		print $a2 "$col[0]\t$col[0]\n";
		for (my $i = 1; $i < @col; $i++){
			if($col[$i] > 0){
				print $a3 "$it $i 1\n";
			}
		}
	}
}
close F;
close $a1;
close $a2;
close $a3;
