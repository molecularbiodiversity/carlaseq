#!/bin/bash

# Script to deploy CarlaSeq to a specified directory

if [ -z "$1" ]; then
	echo ""
	echo "Usage: carlaseq_deploy PREFIX_DIR"
	echo ""
	exit 1
fi

PREFIX_DIR=$1

## dir structure
mkdir -p $PREFIX_DIR/bin

## python executables
for f in src/carlaseq_*.py; do
	BASENAME=$(basename $f)
	OUTFILE=${BASENAME%.py}
	
	echo "Installing executable: $PREFIX_DIR/bin/$OUTFILE"
	cp $f $PREFIX_DIR/bin/$OUTFILE
	chmod +x $PREFIX_DIR/bin/$OUTFILE
done

## shell executables
for f in util/carlaseq_*; do
	OUTFILE=$(basename $f)
	
	echo "Installing executable: $PREFIX_DIR/bin/$OUTFILE"
	cp $f $PREFIX_DIR/bin/$OUTFILE
	chmod +x $PREFIX_DIR/bin/$OUTFILE
done

## python libs
echo "Installing library:    $PREFIX_DIR/bin/common.py"
cp src/common.py $PREFIX_DIR/bin

## shared files
echo "Installing shared data files:"
cp -vr share $PREFIX_DIR

## EOF ##
