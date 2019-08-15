#!/usr/bin/perl
use strict;
use warnings;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	print "./sc_bam/b73_zm_leaf_rep1_scATAC_called_nuclei.$_.bam\n";
}
close F;



