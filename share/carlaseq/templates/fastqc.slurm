{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2014-12-22
# Description: Runs fastqc on each file provided in FILES Setting (and deletes the zipfile)
###

# Command used to generate this file:
# {CMD}

## SETTINGS ##

FILES="{rawfiles}"

CORES={cores}

TRIM='{trim}'

## End SETTINGS ##

# load modules
module load fastqc/0.10.1 parallel/20140722 limsradseq

carlaseq_log Starting $0

## do work ##
FILESEXP=`ls -1 $FILES`
#FILECOUNT=`ls -1 $FILES | wc -l`

CMD="echo \"fastqc {{1}}\"; fastqc -o . {{1}}; export f=\$(basename {{1}}); rm \"\${{f%$TRIM}}_fastqc.zip\";"

parallel -j $CORES  --no-notice "$CMD" ::: $FILESEXP

carlaseq_log Finished $0

