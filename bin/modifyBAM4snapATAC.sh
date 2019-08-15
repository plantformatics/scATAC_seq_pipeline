#!/bin/bash

##-----------------------##
## submission properties ##
##-----------------------##

#PBS -S /bin/bash                               ##
#PBS -q batch                                   ##
#PBS -N convertBAMfileformatRG.BC	        ##
#PBS -l nodes=1:ppn=10                          ##
#PBS -l walltime=48:00:00                       ##
#PBS -l mem=25gb                                ##
#PBS -M marand@uga.edu                          ##
#PBS -m ae                                      ##


## change working directory
cd $PBS_O_WORKDIR
source ~/.zshrc

# bamfiles
basedir=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/bamfiles/scATAC_bams
outdir=/scratch/apm25309/single_cell/ATACseq/v2/newApp/homemadeBAM
leaf1=Leaf1
leaf2=Leaf2
mix=b73mo17
ear=Ear
tassel=Tassel

# run pipeline
samtools view $basedir/$leaf1-bt2/b73_zm_leaf_rep1_scATAC-bt2.bc.bam \
	| perl addBC2readname.pl - $leaf1 \
	| cat $basedir/$leaf1-bt2/header_Leaf1.sam - \
	| samtools view -bSh - \
	| samtools sort -n -@ 10 - > $outdir/$leaf1.bc.bam

samtools view $basedir/$leaf2-bt2/b73_zm_leaf_rep2_scATAC-bt2.bc.bam \
        | perl addBC2readname.pl - $leaf2 \
        | cat $basedir/$leaf2-bt2/header_Leaf2.sam - \
        | samtools view -bSh - \
        | samtools sort -n -@ 10 - > $outdir/$leaf1.bc.bam

samtools view $basedir/$mix-bt2/b73mo17_zm_leaf_rep1_scATAC-bt2.bc.bam \
        | perl addBC2readname.pl - $mix \
        | cat $basedir/$mix-bt2/header_b73mo17.sam - \
        | samtools view -bSh - \
        | samtools sort -n -@ 10 - > $outdir/$mix.bc.bam

samtools view $basedir/$ear-bt2/b73_zm_ear_rep1_scATAC-bt2.bc.bam \
        | perl addBC2readname.pl - $ear \
        | cat $basedir/$ear-bt2/header_Ear.sam - \
        | samtools view -bSh - \
        | samtools sort -n -@ 10 - > $outdir/$ear.bc.bam

samtools view $basedir/$tassel-bt2/b73_zm_tassel_rep1_scATAC-bt2.bc.bam \
        | perl addBC2readname.pl - $tassel \
        | cat $basedir/$tassel-bt2/header_Tassel.sam - \
        | samtools view -bSh - \
        | samtools sort -n -@ 10 - > $outdir/$tassel.bc.bam
