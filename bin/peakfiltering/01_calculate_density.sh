#!/bin/bash -e

if [ $# -lt 6 ]; then
    echo "usage:sh *.sh <output_name> <peaks> <bin-size> <step> <genome_size> <path_to_Tn5_sites> "
    exit -1; 
fi

name=$1
peaks=$2
bin=$3
step=$4
size=$5
sample_list=$6

module load BEDTools

#### set up num ###
mkdir $name
cd $name
bedtools makewindows -b $peaks -w $bin -s $step >$name.windows0000.bed
awk '{print $1,$2,$3,"bin_"NR}' OFS="\t" $name.windows0000.bed >$name.windows0001.bed
rm $name.windows0000.bed

#### split peaks ###

sample=($(cat $sample_list))
a=${#sample[@]}
x=$((${a}-1))

l=$(cat $name.windows0001.bed|wc -l)
m=$(($l/100000))
split -l 100000 -d -a ${#m} $name.windows0001.bed ${name}_split_

for n in `seq -w 0 $m`
do
 i=0
 reads=${sample[$i]}
 total$i=$(cat $reads |wc -l)
 bedtools coverage -a ${name}_split_$n -b $reads -counts |awk '{print $1,$2,$3,$4,'$size'*$5/'$[total$i]'/($3-$2)}' OFS="\t" > ${name}_split_$n.$i.bgx
 for((i=1;i<$a;i++))
 do
 	j=$(($i-1))
  reads=${sample[$i]}
  total$i=$(cat $reads |wc -l)
  bedtools coverage -a ${name}_split_$n -b $reads -counts |awk '{print '$size'*$5/'$[total$i]'/($3-$2)}' OFS="\t" > ${name}_split_$n.$i.bg
  paste ${name}_split_$n.$j.bgx ${name}_split_$n.$i.bg > ${name}_split_$n.$i.bgx
  rm ${name}_split_$n.$j.bgx ${name}_split_$n.$i.bg
 done
 rm ${name}_split_$n
done
cat ${name}_split_*.$x.bgx |awk '{c=0;for(i=5;i<=NF;++i){c+=$i};print $0,c}' OFS="\t" > $name.density

rm $name.windows0001.bed

