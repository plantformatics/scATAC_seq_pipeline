#!/bin/bash -e

if [ $# -lt 6 ]; then
    echo "usage:sh shuffle.sh <output_name> <peaks> <density-file> <tags> <chrom_info> <contig_prefix> "
    echo "Make sure Tn5 density files are in ./ATAC-seq/reads/bg/ folder and named as SPECIE-input/rep1/rep2.Tn5.bed"
    exit -1; 
fi

#### specie ####
specie=$1
#### peaks to define###
input=$2
#### PATH to density files ####
density=$3
#### path to tag###
tag=$4
####chromosome prefix #####
genome=$5
#### contig prefix ######
ctg=$6

module load BEDTools
module load parallel
mkdir $name
cd $name
#### Tn5 density files ####

function cal {
chr=$1
tag=$2
name=$3
echo -n >$name.$chr.sum.bed
mkdir /dev/shm/$name.$chr.aabb
cp $tag/$chr.bg /dev/shm/$name.$chr.aabb/$chr.bg
cat $name.$chr.tmp |while read LINE
do
 s=$(echo "$LINE"|cut -f2)
 t=$(echo "$LINE"|cut -f3)
 n=$(echo "$LINE"|cut -f4)
 value=$(awk '{if($2<'$s') next}{if($2>='$s'&&$2<'$t') print $2,$3; else if($2>='$t') exit}' /dev/shm/$name.$chr.aabb/$chr.bg |sort -n -r -k2 |head -1)
 printf "$chr\t$s\t$t\t$n\t$value\n" >> $name.$chr.sum.bed
done
}
export -f cal


function ctgc {
tag=$1
name=$2
echo -n >$name.ctg.sum.bed
mkdir /dev/shm/$name.ctg.aabb
cp $tag/ctg.bg /dev/shm/$name.ctg.aabb/$name.ctg.bg
cat $name.ctg.tmp |while read LINE
do
 chr=$(echo "$LINE"|cut -f1)
 s=$(echo "$LINE"|cut -f2)
 t=$(echo "$LINE"|cut -f3)
 n=$(echo "$LINE"|cut -f4)
 value=$(awk '{if($1!="'$chr'") next}{if($1=="'$chr'"&&$2<'$s') next}{if($1=="'$chr'"&&$2>='$s'&&$2<'$t') print $2,$3; else exit}' /dev/shm/$name.ctg.aabb/$name.ctg.bg |sort -n -r -k2 |head -1)
 printf "$chr\t$s\t$t\t$n\t$value\n" >> $name.ctg.sum.bed
done
}

export -f ctgc

echo -n >$name.sum_Commands.txt

cut -f1-3 $input >$input.x
awk '{print $1,$2,$3,$NF}' OFS="\t" $density > $name.x
bedtools intersect -a $name.x -b $input.x -wa -wb |awk '{print $1,$2,$3,$5"-"$6"-"$7,$4}' OFS="\t"  >$name.y
rm $input.x

sort -n -r -k5 $name.y|awk '!seen[$4]++' |bedtools sort -i - |sed "s/-/\t/g" \
|awk '{if($2<$5) print $1,$5,$3,$4"-"$5"-"$6,$7; else if($3>$6) print $1,$2,$6,$4"-"$5"-"$6,$7; else print $1,$2,$3,$4"-"$5"-"$6,$7}' OFS="\t" > $name.highest.bin 

rm $name.x $name.y

chrom=($(sed "/$ctg/d" $genome|cut -f1))
num=${#chrom[@]}

for ((i=0;i<$num;i++))
do
chr=${chrom[$i]}
awk '{if($1=="'$chr'") print $1,$2,$3,$4}' OFS="\t"  $name.highest.bin  >$name.$chr.tmp
echo "cal $chr $tag $name" >> $name.sum_Commands.txt
done
grep -e "$ctg"  $name.highest.bin |cut -f1-4  >$name.ctg.tmp
echo "ctgc $tag $name " >> $name.sum_Commands.txt

parallel < $name.sum_Commands.txt


cat $name.*.sum.bed |cut -f4- |sed "s/-/\t/g" |sed "s/\ /\t/g" |bedtools sort -i - > $name.sum.bed

rm $name.sum_Commands.txt

