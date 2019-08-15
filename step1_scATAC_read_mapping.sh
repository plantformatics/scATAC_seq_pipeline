#!/bin/bash

##################################################################################################################
## This script will take the directory name containing fastq files and process them to output uniquely     	##
## mapped, properly paired alignments with 10x barcodes attached as CB:Z: and XC:Z: tags in the read       	##
## group header of the insuing bam files. Duplicates are also removed on a per cell basis using picard     	##
## tools. A number of intermediate files are generated including the counts of each barcode in the 	   	##
## unaligned and aligned data sets. Finally, tagged alignments are used to call peaks with MACS2, which    	##
## serves as the basis for generating accessiblity matrices for individual cells across called peaks.	   	##
##													   	##
## written by: Alexandre Marand, Feb. 2019							 	   	##
##			  										   	##
##################################################################################################################


##--------------------------------------------------------------------------------------------------------------
## HPC submission properties										     	
##--------------------------------------------------------------------------------------------------------------

#PBS -S /bin/bash                       ## shell selection							
#PBS -q schmitz_q                       ## queue selection							
#PBS -N scATAC_pipeline_leaf2	        ## job name								
#PBS -l nodes=1:ppn=24                  ## ppn=threads per node, Needs to match the software argument integer	
#PBS -l walltime=3:00:00:00             ## total time running limit						
#PBS -l mem=50gb                        ## memory limit								
#PBS -M marand@uga.edu                  ## send to address upon initialization and completion of script		
#PBS -m ae                              ##									


## -------------------------------------------------------------------------------------------------------------
## Notes: One can change the intialization step for this script, starting at any given stage by changing     	
## 	  the "start" variable. Useful for troubleshooting failures in the pipeline. 			     	
## -------------------------------------------------------------------------------------------------------------


## change to directory --------------------------------------------------------------------------------------
cd $PBS_O_WORKDIR
source ~/.zshrc


## script-wide variables ------------------------------------------------------------------------------------
threads=24
mem=25G
start=10


## load modules ---------------------------------------------------------------------------------------------
module load Bowtie/1.2.2-foss-2016b
module load SAMtools/1.6-foss-2016b
module load picard/2.16.0-Java-1.8.0_144
module load MACS2/2.1.2.20181017-foss-2016b-Python-2.7.14


## genome reference -----------------------------------------------------------------------------------------
INDEX=/scratch/apm25309/reference_genomes/Zmays/Zm


## processing directory -------------------------------------------------------------------------------------
repid=Leaf2
pro=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/bamfiles/scATAC_bams/$repid
name=Leaf2
outid=b73_zm_leaf_rep2_scATAC


## ATAC files and directories -------------------------------------------------------------------------------
dir1=/scratch/apm25309/single_cell/ATACseq/v2/$name
out1=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/raw_reads/$repid
bcout=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/barcode_data/$repid
out=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/bamfiles/scATAC_bams/$repid/$outid.bam
matrices=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/matrices
peakdir=/scratch/apm25309/single_cell/ATACseq/v2/bulk_alignment/peaks
samp=$dir1/$name
samo=$out1/$name
ln1=_S4_L001_
ln2=_S4_L002_
ln3=_S4_L003_
ln4=_S4_L004_
r1=R1_001.fastq.gz
r2=R3_001.fastq.gz
t1=R1_001.trim.fastq.gz
t2=R3_001.trim.fastq.gz


## make directories only if missing -------------------------------------------------------------------------

# trimmed reads directory
if [ ! -d $out1 ];then
	mkdir $out1
fi

# bam files directory
if [ ! -d $pro ]; then
	mkdir $pro
fi

# barcode directory
if [ ! -d $bcout ]; then
	mkdir $bcout
fi


#############################################################################################################
##													     
##					Print Header 							     
##													     
#############################################################################################################

if [ $start -ne 0 ];then

        echo "###############################################################################################"
        echo "# Step 1 for scATAC-seq analysis - processing FASTQ and BAM files"
        echo "###############################################################################################"
        echo ""
        echo "trimmed fastq dir:        $out1"
        echo "bam dir:			$pro"
        echo "rep_ID:                   $repid"
        echo "raw fastq dir:            $dir1"
        echo ""
        echo "-----------------------------------------------------------------------------------------------"
        echo "Processing scATAC-seq reads"
        echo "-----------------------------------------------------------------------------------------------"

fi


#############################################################################################################
##													     
## 					   Step 1							     
##													     
#############################################################################################################

if [ $start -eq 0 ]; then

	## make the necessary directories if missing --------------------------------------------------------

	# trimmed reads repo
	if [ ! -d $out1 ]; then
		mkdir $out1
	else
		rm -rf $out1
		mkdir $out1
	fi


	# bam files
	if [ ! -d $pro ]; then
		mkdir $pro
	else
		rm -rf $pro
		mkdir $pro
	fi


	## trim raw reads of adapters -----------------------------------------------------------------------
	echo "###########################################################################"
	echo "# Step 1 for scATAC-seq analysis - processing FASTQ and BAM files"
	echo "###########################################################################"
	echo "" 
	echo "trimmed fastq dir:	$out1"
	echo "bam dir:		$pro"
	echo "rep_ID:			$repid"
	echo "raw fastq dir:		$dir1"
	echo ""
	echo "---------------------------------------------------------------------------"
	echo "Processing scATAC-seq reads"
	echo "---------------------------------------------------------------------------"
	echo "1 - Trimming scATAC-seq reads..."
	cpu=$threads


	## adjust CPU for fastp
	if [ $threads -gt 16 ];then
		threads=16
	fi


	## run fastp
	fastp -i $samp$ln1$r1 -I $samp$ln1$r2 -o $samo$ln1$t1 -O $samo$ln1$t2 -w $threads
	fastp -i $samp$ln2$r1 -I $samp$ln2$r2 -o $samo$ln2$t1 -O $samo$ln2$t2 -w $threads
	fastp -i $samp$ln3$r1 -I $samp$ln3$r2 -o $samo$ln3$t1 -O $samo$ln3$t2 -w $threads
	fastp -i $samp$ln4$r1 -I $samp$ln4$r2 -o $samo$ln4$t1 -O $samo$ln4$t2 -w $threads


	# verbose
	echo "1 - Trimmed reads are located in dir: $out1"
	echo "---------------------------------------------------------------------------"


	## move log files to local log directory
	mv fastp.* logs/


	## return threads to normal value
	threads=$cpu


	## merge reads
	cat $samo$ln1$t1 $samo$ln2$t1 $samo$ln3$t1 $samo$ln4$t1 > $samo.merged.$t1
	cat $samo$ln1$t2 $samo$ln2$t2 $samo$ln3$t2 $samo$ln4$t2 > $samo.merged.$t2


	## step next step
	start=1
fi

################################################################################################
##												
##					Step 2							
##												
################################################################################################

if [ $start -eq 1 ]; then

	##-----------------------##
	## map reads with bowtie ##
	##-----------------------##
	echo "2 - Mapping scATAC-seq reads..."


	# bowtie
	time bowtie $INDEX -t -p $threads -v 2 --best --strata -M 1 -X 1000 -S -1 $samo.merged.$t1 -2 $samo.merged.$t2 \
		| samtools view -bSh - > $out


	# verbose
	echo "2 - Mapped reads are located in dir: $pro"
	echo "---------------------------------------------------------------------------"


	# set next step
	start=2

fi


################################################################################################
##												
##					Step 3							
##												
################################################################################################

if [ $start -eq 2 ]; then

	# verbose
	echo "3 - Analyzing barcode reads..."

	if [ ! -f $bcout/$name.barcodes.fastq ]; then

                ## concatenate bc reads
                echo "3 - Merging fastq.gz files..."
                bc=R2_001.fastq.gz
                cat $samp$ln1$bc $samp$ln2$bc $samp$ln3$bc $samp$ln4$bc > $samo.barcodes.fastq.gz
                gunzip $samo.barcodes.fastq.gz

        else
                ## move file back to raw fastq directory
                mv $bcout/$name.barcodes.fastq $samo.barcodes.fastq
        fi


	# reformat BC list and estimate counts
	echo "3 - Reformating barcode list..."
	perl bin/reformat_bc_list.pl $samo.barcodes.fastq $repid > $samo.barcodes.txt
	perl bin/estimateBC_counts_filter.pl files/737K-cratac-v1.txt $samo.barcodes.txt $outid


	# verbose
	echo "3 - Barcode FASTQ are located in dir: $out1"
	echo "3 - Barcode txt files ($outid) are located in dir: $bcout/"
	echo "---------------------------------------------------------------------------"


	# move output to files directory
	mv $outid.ambiguous_bc.txt $bcout/
	mv $outid.matched_bc.txt $bcout/
	mv $outid.matched_bc_counts.txt $bcout/
	mv $outid.ambiguous_bc_counts.txt $bcout/
	mv $samo.barcodes.txt $bcout/
	mv $samo.barcodes.fastq $bcout/


	# reset step
	start=3

fi


################################################################################################
##												
##					Step 4							
##												
################################################################################################

if [ $start -eq 3 ]; then

	#---------------------#
	# Correcting barcodes #
	#---------------------#
	echo "4 - Correcting barcodes ..."

	
	# correct barcodes
	perl bin/barcodeCorrection.pl $bcout/$outid.matched_bc_counts.txt $bcout/$outid.ambiguous_bc_counts.txt > $bcout/$outid.corrected_counts.txt


	# change barcodes need correcting
	perl bin/changebadBC.pl $bcout/$outid.corrected_counts.txt $bcout/$outid.ambiguous_bc.txt > $bcout/$outid.ambiguous_cbc.txt


	# verbose
	echo "4 - Corrected barcodes are located in dir: $bout"
	echo "---------------------------------------------------------------------------"

	
	# reset step
	start=4

fi

################################################################################################
##												
##					Step 5							
##												
################################################################################################

if [ $start -eq 4 ]; then

	##--------------------------------------##
	## Attach bam and barcodes by read name ##
	##--------------------------------------##
	echo "5 - Assigning barcode reads to alignment..."


	# merge matched and corrected
	cat $bcout/$outid.ambiguous_cbc.txt $bcout/$outid.matched_bc.txt > $bcout/$outid.all_cbc.txt
	

	# make header
	samtools view -H $out | grep -v 'Pt\|Mt' - > $pro/header_$name.sam


	# make temporary sorting directory
	if [ ! -d $bcout/tempS ]; then
		mkdir $bcout/tempS	
	else
		rm -rf $bcout/tempS
		mkdir $bcout/tempS
	fi


	# sort barcodes
	echo "5 - Sorting barcodes file..."
	sort -k1,1 \
		--parallel $threads \
		-S $mem \
		-T $bcout/tempS \
		$bcout/$outid.all_cbc.txt > $bcout/$outid.all_cbc.sorted.txt

	#mv $bcout/$outid.all_cbc.sorted.txt $bcout/$outid.all_cbc.txt
	rm -rf $bcout/tempS
	mkdir $bcout/tempS


	# sort by name
	echo "5 - Sorting and removing Pt/Mt reads..."
	samtools view -q 1 -f 3 $out \
		| sort -k1,1 \
			-T $bcout/tempS \
			--parallel $threads \
			-S $mem - \
		| grep -v 'Pt\|Mt' - > $out.nsort

	
	# attach barcodes
	echo "5 - Tagging alignments with barcodes..."
	perl bin/tagBCbam.pl $bcout/$outid.all_cbc.txt $out.nsort \
		| cat $pro/header_$name.sam - \
		| samtools view -bhS - > $pro/$outid.bc.bam


	# verbose
	echo "5 - Barcoded alignments are located in dir: $pro"
	echo "---------------------------------------------------------------------------"


	# reset step
	rm -rf $bcout/tempS
	start=5

fi


################################################################################################
##												
##					Step 6							
##												
################################################################################################

if [ $start -eq 5 ]; then

	##-------------##
	## sort output ##
	##-------------##
	echo "6 - Sorting BAM file..."
	samtools sort -@ $threads $pro/$outid.bc.bam > $pro/$outid.sort.bc.bam


	# verbose
	echo "6 - Sorted BAM file located in dir: $pro"
	echo "---------------------------------------------------------------------------"


	# reset step
	start=6

fi


################################################################################################
##												
##					Step 7							
##												
################################################################################################

if [ $start -eq 100000 ]; then

	##------------------------------------##
	## remove duplicate reads by barcodes ##
	##------------------------------------##
	echo "7 - Removing duplicates..."
	ulimit -c unlimited
	time java -Xmx20g -classpath "/usr/local/apps/eb/picard/2.16.0-Java-1.8.0_144" \
		-jar /usr/local/apps/eb/picard/2.16.0-Java-1.8.0_144/picard.jar \
	        MarkDuplicates \
        	I=$pro/$outid.sort.bc.bam \
	        O=$pro/$outid.rmdup.sort.bc.bam \
	        M=$pro/$outid.duplicate_metrics.txt \
	        BARCODE_TAG=CB \
	        REMOVE_DUPLICATES=FALSE \
	        MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=1000 \
	        ASSUME_SORT_ORDER=coordinate


	# verbose
	echo "7 - De-duplicated BAM files are located in dir: $pro"
	echo "---------------------------------------------------------------------------"

	
	# reset step
	start='NA'

fi
	

################################################################################################
##
##                                      Step 7
##
################################################################################################

if [ $start -eq 6 ]; then

        ##------------------------------------##
        ## remove duplicate reads by barcodes ##
        ##------------------------------------##
        echo "7 - Removing duplicates..."

	# run
	samtools view -h $pro/$outid.sort.bc.bam \
		| perl bin/dedupBAM.pl - $pro/$outid.duplicates.sam \
		| samtools view -bS - > $pro/$outid.rmdup.sort.bc.bam

        # verbose
        echo "7 - De-duplicated BAM files are located in dir: $pro"
        echo "---------------------------------------------------------------------------"


        # reset step
        start=7

fi


################################################################################################
##												
##					Step 8							
##												
################################################################################################

if [ $start -eq 7 ]; then

	##-------------------------------------------##
	## estimate number of reads for each barcode ##
	##-------------------------------------------##
	echo "8 - Counting barcodes..."
	samtools view $pro/$outid.rmdup.sort.bc.bam | perl bin/countTAGs.pl - > $pro/$outid.bc.counts.txt
	mv $pro/$outid.bc.counts.txt $bcout/


	# verbose
	echo "8 - Barcode counts are located in dir: $bcout"
	echo "---------------------------------------------------------------------------"


	# reset
	start=8
fi


################################################################################################
##												
##                                      Step 9							
##												
################################################################################################

if [ $start -eq 8 ]; then

	##----------------------------##
	## Call ATAC peaks with MACS2 ##
	##----------------------------##
	echo "9 - Calling accessibility peaks with MACS2..."


	# create peak directory
	if [ ! -d $peakdir/$repid ]; then
		mkdir $peakdir/$repid 
	else
		rm -rf $peakdir/$repid
		mkdir $peakdir/$repid
	fi


	# run macs2 for fine-scale ACR peaks
	macs2 callpeak -t $pro/$outid.rmdup.sort.bc.bam \
                -g 1575667463 \
                --nomodel \
                --keep-dup all \
                --extsize 200 \
                --shift 100 \
                --outdir $peakdir/$repid \
                -n $outid

	
	# run macs2 for broad accessible chromatin peaks and nucleosome calling
	macs2 callpeak -t $pro/$outid.rmdup.sort.bc.bam \
	       -g 1575667463 \
                --nomodel \
                --keep-dup all \
                --extsize 200 \
                --shift 100 \
		--broad \
                --outdir $peakdir/$repid/broadpeaks \
                -n $outid 

	# verbose
	echo "9 - Peak files are located in dir: $peakdir/$repid"
	echo "---------------------------------------------------------------------------"

	# reset
	start=9

fi

################################################################################################
##												
##                                      Step 10							
##												
################################################################################################

if [ $start -eq 9 ]; then

	# verbose
	echo "10 - Merging bed files..."

	# extend, merge broad peaks for nucleosome calling
	tempname1=_peaks.broadPeak
	broadpeaks=$peakdir/$repid/broadpeaks/$outid$tempname1
	bedtools slop -i $broadpeaks -g $INDEX.fa.fai -b 500 > $broadpeaks.ext500 
	bedtools merge -i $broadpeaks.ext500 -d 500 > $broadpeaks.merged

	# filenames
	tempname=_peaks.narrowPeak
	repidpeaks=$peakdir/$repid/$outid$tempname
	cut -f1-3 $repidpeaks > $peakdir/$repid/$outid.simple.bed
	straightpeaks=$peakdir/$repid/$outid.simple.bed

	
	# verbose
        echo "9 - Peak files are located in dir: $peakdir/$repid"
        echo "---------------------------------------------------------------------------"


	# reset
	start=10
fi



################################################################################################
##												
##					Step 11							
##												
################################################################################################

if [ $start -eq 10 ]; then

	##---------------------------------##
	## Generate accessibility matrices ##
	##---------------------------------##
	echo "11 - Creating accessibility matrices..."
	

	# accessible matrices directory
	if [ ! -d $matrices/$repid ]; then
		mkdir $matrices/$repid
	else
		rm -rf $matrices/$repid
		mkdir $matrices/$repid
	fi


	# variables
	aln=$pro/$outid.rmdup.sort.bc.bam
	peak=$peakdir/$repid/$outid.simple.bed

	# sort peak file
        sort -k1,1V -k2,2n $peak > $peak.sort

	# convert to SE bed file
       	samtools view $aln \
               	| perl bin/makeSE.pl - $repid \
		| sort -k1,1V -k2,2n - > $matrices/$repid/$outid.rmdup.sort.bc.SE.bed


	# check overlap with peaks
	bedtools intersect -a $matrices/$repid/$outid.rmdup.sort.bc.SE.bed -b $peak.sort -wa -wb -sorted \
	        | perl bin/convert2cicero.pl - $bcout/$outid.readsIP.txt > $matrices/$repid/$outid.cicero.txt


	# dense format
	bedtools intersect -a $matrices/$repid/$outid.rmdup.sort.bc.SE.bed -b $peak.sort -wa -wb -sorted \
        	| perl bin/convert2densemat.pl - > $matrices/$repid/$outid.dense.txt


	# verbose
        echo "11 - Accessibility matrices are located in dir: $matrices/$repid"
        echo "---------------------------------------------------------------------------"

	
	# reset
	start=11
fi



################################################################################################
##												
##					Step 12							
##												
################################################################################################

if [ $start -eq 11 ]; then

	##-------------------------------------------------##
	## Run nucleosome calling pipeline with nucleoATAC ##
	##-------------------------------------------------##
	echo "12 - Nucleosome calling..."
	
	# run nucleosome ATAC
	nucleodir=$peakdir/$repid/nucleosomecalling
	if [ ! -d $nucleodir ]; then
		mkdir $nucleodir
	else
		rm -rf $nucleodir
		mkdir $nucleodir
	fi

	# index bam file
	samtools index $pro/$outid.rmdup.sort.bc.bam 


	# run nucleoatac run
	nucleoatac run --bed $broadpeaks.merged \
		--bam $pro/$outid.rmdup.sort.bc.bam \
		--fasta $INDEX.fa \
		--out $nucleodir/$outid.nucleo \
		--cores $threads

	# verbose
	echo "12 - nucleosome calling files are located in dir: $nucleodir"
	echo "---------------------------------------------------------------------------"


	# reset
	start=12
fi


################################################################################################
##												
##					Step 13							
##												
################################################################################################

if [ $start -eq 12 ]; then

	##----------------------------##
	## Check nucleosome positions ##
	##----------------------------##
	echo "13 - Assigning single cells to nucleosomes and NFR regions..."

	# create the necessary directories
	nucleotag=$matrices/$repid/nucleosome_and_NFR
	if [ ! -d $nucleotag ]; then
		mkdir $nucleotag
	else
		rm -rf $nucleotag
		mkdir $nucleotag
	fi

	
	# split reads into x > 140 > y fragments
	samtools view $pro/$outid.rmdup.sort.bc.bam \
		| perl -ne 'chomp; my @col = split("\t",$_);
			if ($col[8] > 140){my $len = $col[3] + length($col[9]);
			print "$col[2]\t$col[3]\t$len\t$col[13]\n";' - > $nucleotag/$outid.nuc.bc.bed


        # split reads into x > 140 > y fragments
        samtools view $pro/$outid.rmdup.sort.bc.bam \
                | perl -ne 'chomp; my @col = split("\t",$_);
                        if ($col[8] < 140){my $len = $col[3] + length($col[9]);
                        print "$col[2]\t$col[3]\t$len\t$col[13]\n";' - > $nucleotag/$outid.nfr.bc.bed	


	# tag single cell nucleosome positions
	bedtools intersect -a $nucleotag/$outid.nuc.bc.bed -b $nucleodir/$outid.nucleo.nucpos.bed -wa -wb -sorted \
        	| perl bin/convert2densemat.pl - > $nucleotag/$outid.NUC.dense.txt

	
	# tag nfr in single cells
        bedtools intersect -a $nucleotag/$outid.nfr.bc.bed -b $nucleodir/$outid.nucleo.nfrpos.bed -wa -wb -sorted \
                | perl bin/convert2densemat.pl - > $nucleotag/$outid.NFR.dense.txt



fi

####################
####################
####################
echo "--Finished running scATAC-seq read processing--"
