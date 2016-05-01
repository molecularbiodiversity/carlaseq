{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2016-04-05
# Description: demultiplexes (no mismatches) paired end sequences based on the first X bases in read 1
###

# Command used to generate this file:
# {CMD}

## SETTINGS ##
# the number (X) of bases to use from front of read 1 for matching barcodes
BARCODE_LEN="{barcodelen}"

# the barcodes to demultiplex from the start of read 1
BARCODES="{barcodes}"

# the files that are to be processed
SOURCEFILES="{srcfiles}"

# the directory to put demultiplexed files
OUTPUTPATH="{output}"

# temp file directory (a place where to TSV formatted sequences are stored 
# while processing each barcode, TSV's are deleted afterwards)
TMP_DIR="{tmpdir}"

## DO WORK ##
module load biostreamtools-gcc/{biostreamtoolsversion}

carlaseq_log Starting $0

# make sure output/temp directories exists
mkdir -p $OUTPUTPATH $TMP_DIR

# process each illumina barcode output
for src in $SOURCEFILES; do

	# only do work for Read 1 files (read 2 done with read 1)
	if [[ "$src" =~ "_R1_" ]]; then

		R2_filename=$(echo "$src" | sed 's/_R1_/_R2_/')
		TSV_FILE=$TMP_DIR/$(basename "$src" | sed 's/\(.*\)_R1.*/\1/').tsv
		echo "Processing: $src"
		echo "       and: $R2_filename"

		# TSVise the source file
		interleave-seq-pairs $src $R2_filename | paste - - - - - - - - > $TSV_FILE

		# extract each barcode's sequences and convert back to FastQ
		for barcode in $BARCODES; do
			OUTFILE1=$OUTPUTPATH/$(basename "$src" | sed 's/\(.*\)_\(L[0-9]*\)_R1.*/\1'-$barcode'_\2/')_R1.fastq
			OUTFILE2=$(echo "$OUTFILE1" | sed 's/_R1/_R2/')
			#echo "- OUT1: $OUTFILE1"
			#echo "- OUT2: $OUTFILE2"
			
			awk -F"\t" '{{
	if (substr($2,1,'$BARCODE_LEN')=="'$barcode'") {{
		BC=substr($2,1,'$BARCODE_LEN');
		R1H=$1"-"BC;
		R1B=substr($2,'$((BARCODE_LEN+1))');
		R1P=$3
		R1Q=substr($4,'$((BARCODE_LEN+1))');
		R2H=$5"-"BC;
		R2B=$6;
		R2P=$7;
		R2Q=$8;
		seqlen=length(R1B);
		if (length(R2B) < seqlen)
			seqlen=length(R2B);
		
		print R1H"\n"substr(R1B,1,seqlen)"\n"R1P"\n"substr(R1Q,1,seqlen)"\n"R2H"\n"substr(R2B,1,seqlen)"\n"R2P"\n"substr(R2Q,1,seqlen);
	}}
}}' $TSV_FILE \
				| deinterleave-seq-pairs $OUTFILE1 $OUTFILE2
		done

		# delete the TSV file
		rm $TSV_FILE
	fi
done

# cleanup
rmdir $TMP_DIR

carlaseq_log Finished $0

## END ##

