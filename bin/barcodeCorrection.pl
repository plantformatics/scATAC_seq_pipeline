#!/usr/bin/perl
use strict;
use warnings;

# usage ----------------------------------------------------------------------------
die "usage: $0 [matched] [ambiguous] > STDOUT \n" unless @ARGV == 2;


# hash variables -------------------------------------------------------------------
my %hash;
my %unmatch;
my %name;


# load whitelist matched barcode counts---------------------------------------------
open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split("\t",$_);
	$hash{$col[0]} = $col[3];
	$name{$col[0]} = $col[2];
}
close F;


# load unmatched barcount counts----------------------------------------------------
open G, $ARGV[1] or die;
while(<G>){
	chomp;
	my @col = split("\t",$_);
	$unmatch{$col[0]} = $col[3];
}
close G;


# correct barcodes by hamming to top 17K bc-----------------------------------------
 my @good = sort {$hash{$b} <=> $hash{$a}} keys %hash;
 my %top = map{$_ => $hash{$_}} @good[0..19999];
 my @topkeys = @good[0..19999];


# iterate over putative matches with hamming dist ----------------------------------
print "ambiguousBC\tcorrectedBC\tbcID\tambiguousCounts\tcorrectedTotal\n";
my $found = 0;
my @maybe = keys %unmatch;
for (my $i = 0; $i < @maybe; $i++){
	if(($i % 1000) == 0){
		print STDERR "Checked $i ambiguous barcodes, corrected $found...\n";
	}
	my $results = check_dist($maybe[$i], \%top);
	if($results ne 'NA'){
		$found++;
		my $total = $unmatch{$maybe[$i]} + $hash{$results};
		print "$maybe[$i]\t$results\t$name{$results}\t$unmatch{$maybe[$i]}\t$total\n";
	}
}


# subroutines------------------------------------------------------------------------
sub check_dist {
	my ($pos, $ref) = @_;
	my @seq = split("", $pos);
	my $match;
	my @letters = ("A", "T", "C", "G");
	my $eexit = 0;
	for (my $i = 0; $i < @seq; $i++){
		my @tester = @seq;
		if($eexit > 0){
			return($match);
			last;
		}
		foreach(@letters){
			$tester[$i] = $_;
			my $recon = join("",@tester);
			if(exists $ref->{$recon}){
				$match = $recon;
				return($match);
				$eexit++;
				last;
			}
		}
	}
	return("NA");
}
