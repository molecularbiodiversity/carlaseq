#!/usr/bin/env python
# encoding: utf-8
'''
Generates a Slurm script for converting FastQ files to FastA 

@author:     Andrew Robinson
'''
import sys, argparse, os, subprocess

import common

def main(argv):
    ''''''
    parser = argparse.ArgumentParser(description='Generates a Slurm script for converting FastQ files to FastA')
    
    parser.add_argument("-p", "--partition", nargs=1, metavar="partition", default=["8hour"], choices=['bigmem', '8hour', 'compute'], help="The partition (or queue) to submit job to")
    parser.add_argument("rawfile", nargs="+", help="Files or directory of raw fastq/a sequences to process.  If directory, -f filter is used to select files within.")
    parser.add_argument("-f", "--dir-filter", nargs=1, metavar='filter', default=["*merge.f*q"], help="A filter to match files when searching a directory.  [Default: '*merge.f*q']")
   
    args = parser.parse_args(argv[1:])
    
    common.writecmd(argv)
    
    #print args

    # expand files
    rawfiles=common.expandFiles(args.rawfile, args.dir_filter[0])

    if len(rawfiles) == 0:
        sys.stderr.write("No RAW files found: '%s'\n" % (" ".join(args.rawfile)))
        return 1
    
    ## make the variable parts of script
    vars={}
    vars["infiles"] = " ".join(rawfiles)
    vars["slurmheader"] = common.makeHeader(partition=args.partition[0], cores=1)
    vars["CMD"] = " ".join(argv)
    
    jobscript = common.loadTemplate("fq2fa.slurm")
    
    #print jobscript

    print jobscript.format(**vars)
    
    
    return 0

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.argv.append("-h")
    sys.exit(main(sys.argv))

