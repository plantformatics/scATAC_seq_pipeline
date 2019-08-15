#!/bin/bash

##-----------------------##
## submission properties ##
##-----------------------##

#PBS -S /bin/bash                               ##
#PBS -q batch                                   ##
#PBS -N getOrganeller			        ##
#PBS -l nodes=1:ppn=1                           ##
#PBS -l walltime=4:00:00:00                     ##
#PBS -l mem=50gb                                ##
#PBS -M marand@uga.edu                          ##
#PBS -m ae                                      ##


## change working directory
cd $PBS_O_WORKDIR
source ~/.zshrc


## b73mo17
cd b73mo17-bt2
samtools view -h b73mo17_zm_leaf_rep1_scATAC-bt2.rmdup.sort.bc.bam \
	| grep 'Mt\|Pt' - \
	| samtools view -bSh - > b73mo17_zm_leaf_rep1_scATAC-bt2.rmdup.sort.bc.Mt.Pt.bam


## Leaf1
cd ../Leaf1-bt2
samtools view -h b73_zm_leaf_rep1_scATAC-bt2.rmdup.sort.bc.bam \
	| grep 'Mt\|Pt' - \
	| samtools view -bSh - > b73_zm_leaf_rep1_scATAC-bt2.rmdup.sort.bc.Mt.Pt.bam


## Leaf2
cd ../Leaf2-bt2
samtools view -h b73_zm_leaf_rep2_scATAC-bt2.rmdup.sort.bc.bam \
        | grep 'Mt\|Pt' - \
        | samtools view -bSh - > b73_zm_leaf_rep2_scATAC-bt2.rmdup.sort.bc.Mt.Pt.bam


## Ear
cd ../Ear-bt2
samtools view -h b73_zm_ear_rep1_scATAC-bt2.rmdup.sort.bc.bam \
        | grep 'Mt\|Pt' - \
        | samtools view -bSh - > b73_zm_ear_rep1_scATAC-bt2.rmdup.sort.bc.Mt.Pt.bam


## Tassel
cd ../Tassel-bt2
samtools view -h b73_zm_tassel_rep1_scATAC-bt2.rmdup.sort.bc.bam \
        | grep 'Mt\|Pt' - \
        | samtools view -bSh - > b73_zm_tassel_rep1_scATAC-bt2.rmdup.sort.bc.Mt.Pt.bam
