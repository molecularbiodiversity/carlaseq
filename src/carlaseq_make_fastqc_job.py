#!/usr/bin/env python
# encoding: utf-8
'''
Generates a Slurm script for running fastqc on various sequence data files

@author:     Andrew Robinson
'''
import sys, argparse, os, subprocess

import common

def main(argv):
    ''''''
    parser = argparse.ArgumentParser(description='Generates a Slurm script for running fastqc on various sequence data files')
    
    parser.add_argument("-j", "--cores", nargs=1, metavar='N', type=int, default=[1], help="The maximum number of cores to use, 0=exclusive. [Default: 1]")
    parser.add_argument("-p", "--partition", nargs=1, metavar="partition", default=["8hour"], choices=['bigmem', '8hour', 'compute'], help="The partition (or queue) to submit job to")
    parser.add_argument("rawfile", nargs="+", help="Files or directory of raw fastq/a sequences to process.  If directory, -f filter is used to select files within.")
    parser.add_argument("-f", "--dir-filter", nargs=1, metavar='filter', default=["*.f*q*"], help="A filter to match files when searching a directory.  [Default: '*.f*q*']")
    parser.add_argument("-t", "--filename-trim", nargs=1, metavar='trim', default=[".f*q*"], help="Bash REGEX to trim extension from end of filename.  [Default: '.f*q*']")
   
    args = parser.parse_args(argv[1:])
    
    common.writecmd(argv)

    # expand files
    rawfiles=common.expandFiles(args.rawfile, args.dir_filter[0])

    if len(rawfiles) == 0:
        sys.stderr.write("No RAW files found: '%s'\n" % (" ".join(args.rawfile)))
        return 1
    
    ## make the variable parts of script
    vars={}
    vars["rawfiles"] = " ".join(rawfiles)
    if args.cores[0] == 0:
        vars["slurmheader"] = common.makeExclusiveHeader(partition=args.partition[0])
        vars["cores"] = "16"
    else:
        vars["slurmheader"] = common.makeHeader(partition=args.partition[0], ntasks=args.cores[0])
        vars["cores"] = args.cores[0]
    vars["trim"] = args.filename_trim[0]
    vars["CMD"] = " ".join(argv)
    
    jobscript = common.loadTemplate("fastqc.slurm")

    print jobscript.format(**vars)
    
    
    return 0

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.argv.append("-h")
    sys.exit(main(sys.argv))

