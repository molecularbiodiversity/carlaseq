{slurmheader}

###
# Author:      Andrew Robinson
# Date:        2016-04-05
# Description: Runs Trimmomatic to remove adapter sequence
###

# Command used to generate this file:
# {CMD}

## SETTINGS ##

FILES="{files}"

CORES={cores}

# the settings used for ILLUMINACLIP (trimmomatic)
CLIPSETTINGS="2:30:10"

## End SETTINGS ##

# load modules
module load trimmomatic/0.32 limsradseq

carlaseq_log Starting $0

## do work ##
FILESEXP=`ls -1 $FILES`
#FILECOUNT=`ls -1 $FILES | wc -l`

for F in $FILESEXP; do
	OF=$(basename $F)
	Fe=${{F%.*}}
	OFe=${{OF%.*}}

	# search for paired files
	F2=$(echo "$F" | sed 's/_R1/_R2/')
	if [ $F != $F2 ] && [ -f $F2 ]; then
		OF2=$(basename $F2)
		OF2e=${{OF2%.*}}
		CMD="trimmomatic PE -threads $CORES -phred33 -trimlog trim.log $F $F2 $OF $OFe.sing.fastq $OF2 $OF2e.sing.fastq ILLUMINACLIP:adapter.fa:${{CLIPSETTINGS}}"
	else
		CMD="trimmomatic SE -threads $CORES -phred33 -trimlog trim.log $F $OF ILLUMINACLIP:adapter.fa:${{CLIPSETTINGS}}"
	fi
	
	# run command
	echo $CMD
	$CMD
done

carlaseq_log Finished $0

