{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2014-12-10
# Description: Uses pear to combine overlapping paired-end sequences
###

# Command used to generate this file:
# {CMD}

## SETTINGS ##

# add your pear options here
OPTS=""

FILES="{files}"

CORES={cores}

TRIM='{trim}'

## End SETTINGS ##


# load modules
module load pear-gcc/0.9.4 limsradseq

carlaseq_log Starting $0

# pair each input file
# loops over each R1 filtered file
MD5="MD5 Hashes:"
for SRCFILENAME1 in ${{FILES}}; do
	echo "Running: $SRCFILENAME1 at: " `date`
	OUTFILE=`basename $SRCFILENAME1 | sed 's/_R1//g'`;
	OUTFILE="${{OUTFILE%$TRIM}}"
	
	# compute the pair filename
	# replaces '_R1' with '_R2' so may break if you named your files differently
	SRCFILENAME2=`echo $SRCFILENAME1 | sed 's/_R1/_R2/g'`
	echo "Pair:    $SRCFILENAME2"
	
	CMD="pear -j $CORES $OPTS -o $OUTFILE -f $SRCFILENAME1 -r $SRCFILENAME2"
	echo $CMD
	$CMD
	
	# merge assembled and forward
	CMD="cat $OUTFILE.assembled.fastq $OUTFILE.unassembled.forward.fastq $OUTFILE.unassembled.reverse.fastq"
	echo "$CMD > $OUTFILE.merge.fastq"
	$CMD > $OUTFILE.merge.fastq

	# compute md5 hash
	echo "md5sum $OUTFILE.assembled.fastq"
	MD5="$MD5\n`md5sum $OUTFILE.assembled.fastq`"
	echo "md5sum $OUTFILE.discarded.fastq"
	MD5="$MD5\n`md5sum $OUTFILE.discarded.fastq`"
	echo "md5sum $OUTFILE.unassembled.forward.fastq"
	MD5="$MD5\n`md5sum $OUTFILE.unassembled.forward.fastq`"
	echo "md5sum $OUTFILE.unassembled.reverse.fastq"
	MD5="$MD5\n`md5sum $OUTFILE.unassembled.reverse.fastq`"
	echo "md5sum $OUTFILE.mergeforward.fastq"
	MD5="$MD5\n`md5sum $OUTFILE.merge.fastq`"
done

# print details of output files (provenance)
echo -e "\nDirectory Contents:"
ls -l
echo ""
echo -e $MD5
echo ""

carlaseq_log Finished $0
