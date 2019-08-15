#!/usr/bin/perl

print "barcodes\talignedBC\n";
open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split("\t",$_);
	my @ids = split("_",$col[0]);
	my @bc = split(":",$ids[0]);
	my $new = join("-",$bc[2],$ARGV[1]);
	print "$new\t$col[1]\n";
}
close F;
