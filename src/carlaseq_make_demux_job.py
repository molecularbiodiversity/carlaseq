#!/usr/bin/env python
'''
CMDLine program to generate a demultiplex job based on the first X bases of read1

Created on 5 Apr 2016

@author: arobinson
'''

DEFAULT_BARCODES = "CAGGTT ACATCA CATCAA TAGATC GAATCG ATTCCG ACGGTG TCCGGT TTCATA CGTTAT TGTGTG GATCGG"

import sys, argparse, os, subprocess

import common

def main(argv):
    ''''''
    parser = argparse.ArgumentParser(description='Generates a Slurm script for demultiplexing sequence files based on first X bases of read 1')
    
    parser.add_argument("-j", "--cores", nargs=1, metavar='N', type=int, default=[1], help="The maximum number of cores to use, 0=exclusive. [Default: 1]")
    parser.add_argument("-p", "--partition", nargs=1, metavar="partition", default=["8hour"], choices=['bigmem', '8hour', 'compute'], help="The partition (or queue) to submit job to")
    parser.add_argument("rawfile", nargs="+", help="Files or directory of raw fastq/a sequences to process.  If directory, -f filter is used to select files within.")
    parser.add_argument("-b","--barcodes", nargs=1, default=[DEFAULT_BARCODES], help="Barcodes to demultiplex")
    parser.add_argument("-t","--tmpdir", nargs=1, default=["tmp"], help="Directory to place temp files in")
    parser.add_argument("-f", "--dir-filter", nargs=1, metavar='filter', default=["*.f*q*"], help="A filter to match files when searching a directory.  [Default: \"*.f*q*]\"")
    
    args = parser.parse_args(argv[1:])
    
    common.writecmd(argv)

    # expand files
    rawfiles=common.expandFiles(args.rawfile, args.dir_filter[0])

    if len(args.rawfile) == 0:
        sys.stderr.write("No RAW files found: '%s'\n" % (" ".join(args.rawfile)))
        return 1
    
    
    vars={}
    vars["barcodelen"] = "6"
    vars["barcodes"] = args.barcodes[0]
    vars["srcfiles"] = " ".join(rawfiles)
    vars["output"] = '.'
    vars["tmpdir"] = args.tmpdir[0]
    if args.cores[0] == 0:
        vars["slurmheader"] = common.makeExclusiveHeader(partition=args.partition[0])
        vars["cores"] = "16"
    else:
        vars["slurmheader"] = common.makeHeader(partition=args.partition[0], ntasks=args.cores[0])
        vars["cores"] = args.cores[0]
    vars["biostreamtoolsversion"] = subprocess.check_output(["carlaseq_module_version", "biostreamtools-gcc"]).rstrip()
    vars["CMD"] = " ".join(argv)
    
    jobscript = common.loadTemplate("demux.slurm")
    
    print jobscript.format(**vars)
    
    
    return 0

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.argv.append("-h")
    sys.exit(main(sys.argv))
