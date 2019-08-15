#!/usr/bin/perl
use strict;
use warnings;
use Sort::Naturally;

my %hash;
my %peaks;
my %cells;

my $reads = 0;
open F, $ARGV[0] or die;
while(<F>){
	chomp;
	$reads++;
	if(($reads % 1000000) == 0){
		print STDERR "Read $reads SE reads into memory...\n"; 
	}
	my @col = split("\t",$_);
	$col[4] = "chr" . $col[4];
	my $peakid = join("_", @col[4..6]);
	$peaks{$peakid} = 1;
	$hash{$col[3]}{$peakid}++;
}
close F;

my @bcs = nsort keys %hash;
my @atac = nsort keys %peaks;
print "$bcs[0]";
foreach(@bcs[1..$#bcs]){
	print "\t$_";
}
print "\n";
for (my $i = 0; $i < @atac; $i++){
	print "$atac[$i]";
	for (my $j = 0; $j < @bcs; $j++){
		if(exists $hash{$bcs[$j]}{$atac[$i]}){
			print "\t1";
		}
		else{
			print "\t0";
		}
	}
	print "\n";
}

