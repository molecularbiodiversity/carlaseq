{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2014-12-08
# Description: Uses seq-sets to compute the union of all contaminated sequences and
#              then filters the raw sequences to remove contamination.
###

# Command used to generate this file:
# {CMD}

# load modules
module load biostreamtools-gcc/{biostreamtoolsversion} limsradseq

carlaseq_log Starting $0

# filter each input file
MD5="MD5 Hashes:"
for SRCFILENAME in {rawfiles}; do
        echo "Running: $SRCFILENAME at: " `date`
        OUTFILE=`basename $SRCFILENAME`;
        KRAKEN_FILT_FILES=$(ls -1 {krakenfiles} | grep $(echo ${{OUTFILE%%.*}} | sed 's/_R[1-2]/_R.*/'))
        OUTFILE="${{OUTFILE%%.*}}_filtered.fastq"

        CMD="seq-sets --mode NOTUNION -o $OUTFILE -s $SRCFILENAME $KRAKEN_FILT_FILES"
        echo $CMD
        $CMD

        # compute md5 hash
        echo "md5sum $OUTFILE"
        MD5="$MD5\n$(md5sum $OUTFILE)"
done

# print details of output files (provenance)
echo -e "\nDirectory Contents:"
ls -l
echo ""
echo -e $MD5
echo ""

carlaseq_log Finished $0

