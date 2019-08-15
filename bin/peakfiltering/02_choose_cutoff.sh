#!/bin/bash -e

if [ $# -lt 5 ]; then
    echo "usage:sh cutoff.sh <file> <cutoff> <merge-gaps> <peaks-length> <reps_counts>"
    exit -1; 
fi
module load BEDTools

input=$1
density=$2
gap=$3
len=$4
reps=$5

awk '$NF>('$reps'*'$density')' $input |bedtools sort -i - |bedtools merge -d $gap -i - |awk '$3-$2>'$len'' >  $input.$density.$gap.bed

