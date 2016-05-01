{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2016-04-21
# Description: Runs blast against DATABASE on each file provided in FILES Setting
###

# Command used to generate this file:
# {CMD}

## SETTINGS ##

FILES="{rawfiles}"

CORES={cores}

TRIM='{trim}'

DATABASE={probes}

TMP=.

## End SETTINGS ##

# load modules
module load blast+/{blastversion} biostreamtools-gcc/{biostreamtoolsversion} limsradseq

carlaseq_log Starting $0

## do work ##
FILESEXP=`ls -1 $FILES`
#FILECOUNT=`ls -1 $FILES | wc -l`

# index the probes file
if [ ! -f $DATABASE ]; then
	echo "Probes database file doesn't exist: '${{DATABASE}}'"
	carlaseq_log "Finished(Error)" $0
	exit 1
fi

makeblastdb -in $DATABASE -parse_seqids -dbtype nucl

# blast each sample
for f in $FILES; do 
	if [ -s $f ]; then
		echo "Processing: ${{f}}"
		BASENAME=$(basename $f)
		BLASTOUTFILE=${{BASENAME%$TRIM}}_hits.tsv
		LISTOUTFILE=${{BASENAME%$TRIM}}_hits.list
		FASTAOUTFILE=${{BASENAME%$TRIM}}_hits.fa
		
		# blast
		blastn -task megablast \
			-query $f \
			-db $DATABASE \
			-outfmt 6 \
			-out $BLASTOUTFILE \
			-num_threads $CORES
		
		# make hit list
		cut -f1 $BLASTOUTFILE \
			| sort | uniq \
			 > $LISTOUTFILE
		
		# create fasta for centroids
		awk '{{print ">"$0";\n"}}' $LISTOUTFILE > $TMP/tmp.fa
		seq-sets -s $f -m I $TMP/tmp.fa > $FASTAOUTFILE
		rm $TMP/tmp.fa
		
		echo "Complete:"
		echo " - TSV:     $BLASTOUTFILE ($(cat $BLASTOUTFILE | wc -l) hits)"
		echo " - ID List: $LISTOUTFILE ($(cat $LISTOUTFILE | wc -l) ids)"
		echo " - Fasta:   $FASTAOUTFILE ($(grep '^>' $FASTAOUTFILE | wc -l) sequences)"
	else
		echo "Skipping empty file: ${{f}}"
	fi
done

carlaseq_log Finished $0

