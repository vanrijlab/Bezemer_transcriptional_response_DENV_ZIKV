#!/bin/bash -l
#$ -S /bin/bash
#$ -cwd
#$ -V


#set -x


# General settings

index="${HOME}"/hg19/STARindexHg19
date=$(date +%Y%m%d)

WORKDIR=`pwd`
mkdir "${date}".STARMapping
cd "${date}".STARMapping



echo "This script was run on $(date)
	in 2-pass mode with
	Index: ${index}
	Results will be stored in the folder: ${date}.STARMapping"

echo -e "\n\n"

##############################
####### First mapping ########
##############################
mkdir 1pass_mapping
 
for files in "${WORKDIR}"/fastq/*.fastq.gz; do
	INFILE="${files}"
	FILENAME=`echo $(basename ${files}) | sed 's/\.fastq.gz$//'`
	

	echo "Processing of library ${FILENAME} started at $(date +%H:%M:%S)"

	STAR --runThreadN 20 \
		--genomeDir "${index}" \
		--readFilesIn "${INFILE}" \
	    --readFilesCommand zcat \
		--outSAMtype None \
		--outMultimapperOrder Random \
		--runRNGseed 123 \
		--outSAMmultNmax 1 \
	    --outSAMstrandField intronMotif \
		--outFileNamePrefix "${WORKDIR}"/"${date}".STARMapping/1pass_mapping/"${FILENAME}"

	
done

# catenate all Sj (splice junction files) and then remove all junctions on mitichondria (false positives) 
# to be used in 2nd-pass mapping
cat 1pass_mapping/*SJ.out.tab > 1pass_mapping/SJfiles_cat.tab
sed '/Mt/d' 1pass_mapping/SJfiles_cat.tab > 1pass_mapping/SJfiles_cat_wo_Mt.tab
echo "Done with 1st-pass mapping of all files"



##############################
###### Second mapping ########
##############################


mkdir 2pass_mapping
for files in "${WORKDIR}"/fastq/*.fastq.gz; do
	        INFILE="${files}"
	        FILENAME=`echo $(basename ${files}) | sed 's/\.fastq.gz$//'`


	        echo "Processing of sample ${FILENAME} started at $(date +%H:%M:%S)"

	        STAR --runThreadN 20 \
	             --genomeDir "${index}" \
	             --readFilesIn "${INFILE}" \
	             --readFilesCommand zcat \
	             --outSAMtype BAM SortedByCoordinate \
				 --outMultimapperOrder Random \
				 --runRNGseed 123 \
	             --outSAMmultNmax 1 \
	             --outSAMstrandField intronMotif \
				 --quantMode GeneCounts \
				 --sjdbFileChrStartEnd 1pass_mapping/SJfiles_cat_wo_Mt.tab \
	             --outFileNamePrefix "${WORKDIR}"/"${date}".STARMapping/2pass_mapping/"${FILENAME}"
	        echo -e "\nDone with 2nd-pass mapping of sample ${FILENAME} at $(date +%H:%M:%S)\n\n"
done

cd "${WORKDIR}"

