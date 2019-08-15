#!/usr/bin/perl
use strict;
use warnings;

my $sample = $ARGV[1];
my $activate = 0;
my $tag = 0;

my %bc;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	my @col = split(/\s+/,$_);
	if($_ =~ /^\@/){
		$activate++;
		$col[0] =~ s/\@//g;
		print "$col[0]\t";
		next;
	}
	elsif($activate == 1){
		if(exists $bc{$_}){
			print "$_\tbarcodeID_$sample" . "_" . "$bc{$_}\n";
			$activate = 0;
		}
		else{
			$tag++;
			$bc{$_} = $tag;
			print "$_\tbarcodeID_$sample" . "_" . "$bc{$_}\n";
			$activate = 0;
		}
	}
}
close F;

