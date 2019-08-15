#!/usr/bin/perl
use strict;
use warnings;


# usage
die "usage: $0 [(header)-BAM] [outputfilename.duplicates] > STDOUT\n" unless @ARGV == 2;


# output
my $temp = $ARGV[1];
open (my $output, '>', $temp) or die;


# variables
my $bef = 0;
my %dups;
my $keep = {};

# filtering summary
my $in = 0;
my $out = 0;


# track total reads iterated over;
my $treads = 0;

# iterate over alignments
open F, $ARGV[0] or die;
while(<F>){
	chomp;

	# print header lines
	if($_ =~ /^@/){
		print "$_\n";
		next;
	}

	# alignment lines
	$treads++;
	if(($treads % 1000000) == 0){
		print STDERR "$treads processed...\n";
	}

	# process
	my @col = split("\t",$_);
	if(exists $keep->{$col[0]}){
		print "$_\n";
		delete($keep->{$col[0]});
		next;
	}
	my $id = join("_",@col[2..3]);
	my $frag = join("_",@col[2..3],$col[7]);

	# if duplicate, push to array
	if($id eq $bef){
		$bef = $id;
		push(@{$dups{$col[15]}{$frag}}, $_);
		next;
	}
	
	# if not duplicate
	else{
		# reset bef
		$bef = $id;

		# if dup array full, process prev dups
		if(%dups){
			my @dedup = keepbest(\%dups, $keep);
			%dups = ();
			push(@{$dups{$col[15]}{$frag}}, $_);
			$in = $in + $dedup[0];
			$out = $out + $dedup[1];
			$keep = $dedup[2];
		}

		# if dup array empty, start new dups array
		else{
			push(@{$dups{$col[15]}{$frag}}, $_);
		}	
	}
}
close F;
close $output;


# print summary
print STDERR "$in reads processed, $out reads dumped...\n";

# subroutines
sub keepbest {
	my ($ref, $save) = @_;
	my @bc = keys %{$ref};
	my $in = 0;
	my $out = 0;
	foreach my $barcodes (@bc){
		my @frags = keys %{$ref->{$barcodes}};
		foreach my $aln (@frags){
			my @alignments = @{$ref->{$barcodes}->{$aln}};
			my %qual;
			my %read;
			foreach my $ind (@alignments){
				$in++;
				my @line = split("\t",$ind);
				$read{$line[0]} = $ind;
				my @score = split("",$line[10]);
				my $total = 0;
				foreach my $bq (@score){
					if($bq eq 'F'){
						$total++;
					}
				}
				$qual{$line[0]} = $total;
			}
			my @sortedscores = sort {$qual{$b} <=> $qual{$a}} keys %qual;
			$out++;
			print "$read{$sortedscores[0]}\n";
			$save->{$sortedscores[0]} = 1;	
			if(@sortedscores > 1){
				foreach(@sortedscores[1..$#sortedscores]){
					print $output "$read{$_}\n";
				}
			}
		}
	}
	return($in, $out, $save);
}





