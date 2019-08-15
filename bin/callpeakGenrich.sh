#!/bin/bash


##--------------------------------------------------------------------------------------
## HPC submission properties								
##--------------------------------------------------------------------------------------
#PBS -S /bin/bash                       ##
#PBS -q schmitz_q                       ##
#PBS -N scATAC_peakcalling              ##
#PBS -l nodes=1:ppn=20                  ##
#PBS -l walltime=1:00:00:00             ##
#PBS -l mem=80gb                        ##
#PBS -M marand@uga.edu                  ##
#PBS -m ae                              ##


## change to directory, and source zsh profile ## 
cd $PBS_O_WORKDIR
source ~/.zshrc

## load modules ##
module load MACS2/2.1.2.20181017-foss-2016b-Python-2.7.14


########################################################################################
## call peaks on hclustered bam files							
########################################################################################

## variables ##
dosort=0
control=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/bamfiles/bulkATAC_bams/B73input1.rmdup.nsorted.v4.bam
gdir=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/join_sc_files/rep1
unmap=/scratch/apm25309/reference_genomes/Zmays/Zm.nonmappableregions.bed
auc=10

## change directories ##
cd $gdir

## call peaks for each bam file ##
for i in $(ls *.bam | rev |cut -c 5- | rev | uniq); do

	if [ $dosort == 1 ]; then
		id=$i
		echo "sorting cluster $id reads by name ..."
		samtools sort -@ 20 -n $i.bam > $i.bam.nsort
		echo "calling peaks for cluster $id ..."
		Genrich -t $i.bam.nsort -c $control -o $id.narrowPeak -j -y -g 100 -a $auc -v -E $unmap -d 100

	else

                id=$i
                echo "BAM already name sorted, calling peaks for cluster $id ..."
                Genrich -t $i.bam.nsort -c $control -o $id.narrowPeak -j -y -g 100 -a $auc -v -E $unmap -d 100

	fi
done
