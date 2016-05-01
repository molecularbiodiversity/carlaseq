{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2016-04-20
# Description: Filters minimum cluster size on each file provided in FILES Setting
###

# Command used to generate this file:
# {CMD}

## SETTINGS ##

FILES="{rawfiles}"

CENT_SIZE={centsize}

TRIM='{trim}'

## End SETTINGS ##

# load modules
module load limsradseq

carlaseq_log Starting $0

## do work ##
FILESEXP=`ls -1 $FILES`
#FILECOUNT=`ls -1 $FILES | wc -l`

for f in $FILES; do
	echo "Processing: ${{f}}"
	OUTFILE=$(basename $f)
	OUTFILE=${{OUTFILE%$TRIM}}_clsize${{CENT_SIZE}}.fa
	
	# sed: replace the ';' character at end of line with a tab (for TSV format later)
	# tr: remove newlines
	# sed: replace newlines before each sequence
	# tail: remove the extra newline at beginning
	# awk: filter on size and return to fasta format
	sed 's/;$/;\t/g' $f \
		| tr --delete '\n' \
		| sed 's/>/\n>/g' \
		| tail -n+2 \
		| awk '{{split($1, v, "="); if (v[2] >= '${{CENT_SIZE}}') print $1"\n"$2}}' \
		  > $OUTFILE
	
	echo "Complete:   $(grep '^>' $OUTFILE | wc -l) of $(grep '^>' $f | wc -l) clusters passed filter (>=$CENT_SIZE cluster size)"
done

carlaseq_log Finished $0
