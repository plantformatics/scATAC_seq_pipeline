#!/usr/bin/perl
use strict;
use warnings;
use Sort::Naturally;

my %hash;
my %rip;

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
	if($col[4] =~ /chrB73V4_ctg/){
		$col[4] =~ s/chrB73V4_ctg/chrB73V4ctg/g;
	}
	my $peakid = join("_", @col[4..6]);
	$hash{$col[3]}{$peakid}++;
	$rip{$col[3]}++;
}
close F;

my @bcs = nsort keys %hash;
for (my $i = 0; $i < @bcs; $i++){
	my @pos = nsort keys %{$hash{$bcs[$i]}};
	for (my $j = 0; $j < @pos; $j++){
		print "$pos[$j]\t$bcs[$i]\t$hash{$bcs[$i]}{$pos[$j]}\n";
	}
}

my $out = $ARGV[1];
open (my $t1, '>', $out) or die;
for (my $j = 0; $j < @bcs; $j++){
	print $t1 "$bcs[$j]\t$rip{$bcs[$j]}\n";
}
close $t1;
