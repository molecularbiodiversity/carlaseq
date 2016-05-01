{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2016-04-13
# Description: Converts fastq files to fasta files with the same name using
#              only standard utilities.  Note: it cannot handle multi-line
#              or gzipped sequence data
###

# Command used to generate this file:
# {CMD}

carlaseq_log Starting $0

INFILES="{infiles}"

OUTFILE="target_all.fasta"

## do work
echo "cat $INFILES | paste - - - - | awk -F \"\t\" '{{print \">\"substr(\$1, 2)\"\n\"\$2}}' > $OUTFILE"
cat $INFILES | paste - - - - | awk -F "\t" '{{print ">"substr($1, 2)"\n"$2}}' > $OUTFILE

# compute md5 hash
echo "md5sum $OUTFILE"
MD5="$MD5\n$(md5sum $OUTFILE)"

# print details of output files (provenance)
echo -e "\nDirectory Contents:"
ls -l
echo ""
echo -e $MD5
echo ""

carlaseq_log Finished $0
