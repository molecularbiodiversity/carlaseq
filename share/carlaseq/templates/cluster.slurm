{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2016-04-20
# Description: Runs vsearch --cluster_size on each file provided in FILES Setting
###

# Command used to generate this file:
# {CMD}

## SETTINGS ##

FILES="{rawfiles}"

CORES={cores}

IDENTITY={identity}

TRIM='{trim}'

## End SETTINGS ##

# load modules
module load vsearch-gcc/{vsearchversion} limsradseq

carlaseq_log Starting $0

## do work ##
FILESEXP=`ls -1 $FILES`
#FILECOUNT=`ls -1 $FILES | wc -l`

for f in $FILES; do 
	echo "Processing: ${{f}}"
	OUTFILE=$(basename $f)
	OUTFILE=${{OUTFILE%$TRIM}}_centroid${{IDENTITY}}.fa
	vsearch \
		--threads $CORES \
		--cluster_size $f \
		--id $IDENTITY \
		--sizeout \
		--usersort \
		--centroids $OUTFILE
done

carlaseq_log Finished $0

