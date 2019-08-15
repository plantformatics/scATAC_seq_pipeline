#!/usr/bin/perl
use strict;
use warnings;

open F, $ARGV[0] or die;
while(<F>){
	chomp;
	if($_ =~ /^@/){
		print "$_\n";
		next;
	}else{
		my @col = split("\t",$_);
		my @bc = split(":", $col[11]);
		$bc[2] = $bc[2] . "-" . "$ARGV[1]";
		$col[11] = join(":",@bc);
		my $line = join("\t",@col);
		print "$line\n";
	}
}
close F;
