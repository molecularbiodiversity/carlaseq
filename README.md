# CarlaSeq - User Guide

How to use the CarlaSeq RADseq Pipeline

## Overview

The main steps to process a dataset are:

1. Data structure setup
2. FastQC
3. Demultiplex
  1. by first 6 bases of read1
  2. Remove 6 bases from read2
4. Trim adapters
5. Kraken to remove contaminants (if contamination is present)
6. Pear reads
7. --Deduplicate-- [no longer performed]
8. Convert to FastA
9. Vsearch cluster 75% sim
10. Filter clusters by read count
11. --Denovo assemble-- [Performed externall (with CLC)]
12. Blastn against probes


## Requirements/assumptions

* **Environment Modules**: The code snippets below assume that CarlaSeq has been installed 
  within a software module called 'carlaseq'.  If this is not the case then simply ignore 
  those lines of the snippets.
* **SLURM**: The job scripts that this pipeline generates are for the SLURM HPC manager.  If
  you need to use something else then you will need to modify the template files and alter
  the common.py script to generate the required headers for your HPC manager.
* **PATH**: Scripts assume the following tools are in your path (or loadable via environment 
  modules)
  * fastqc
  * trimmomatic
  * kraken
  * pear
  * vsearch
  * python
  * blastn
  * many other standard unix tools

## Glossary

* **Raw** (sequence, files): the sequences or files as they came off the MiSeq/HiSeq
* **Demux**: short for ‘demultiplex’ (shorthand from electronics field :P)


## Data structure setup

The radseq pipeline expects a specific data structure.  You should create one directory for 
each experiment you complete (i.e. each dataset to come off the MiSeq).  Inside this directory 
you will have one directory for each step in the pipeline.  The pipeline includes a script to 
create the required directory structure however this is what it will look like.

* 2014-12-01_lobster/
  * 00-raw/
  * 00-raw-fastqc
  * 01-demux/
  * 02-trimmomatic/
  * 03-kraken/
  * 04-seqsets/
  * 05-pear/
  * 06-fq2fa
  * 07-cluster
  * 08-filter-size
  * 09-blastprobes
  * ...
  * process.log
  * slurm.conf
* 2014-12-09_abalone/
  * ...

```sh
module load carlaseq

# make a directory for your project (and sub-directories for each step)
carlaseq_make_experiment YOUR-PROJECT-NAME
cd YOUR-PROJECT-NAME

# copy files for into your project structure
# NOTE: you can use a symbolic link instead of copying if your files are saved 
# somewhere else (and won’t change)
cp RAW-SEQ-FILES 00-raw/
```
**Figure**: Commands used to setup the directory structure ready for RADSeq analysis.  
Replace YOUR-PROJECT-NAME with the actual name of your project AND RAW-SEQ-FILES with 
the path to your fastq files given to you by the MiSeq.


### process.log file

When you run the command “make_rad_experiment” a file will be created in the experiment directory 
called “process.log”.  Inside this file will be one line with the current date/time and a message 
saying “Create Experiment: XXX”.

Every time you run one the make_* commands a line will be added to this file with details of what 
command was used (and the date/time).  This will only happen if the process.log file exists; if 
you delete it then no logging will happen.

NOTE: because BASH performs some “magic” on the command before giving it to the make_* command, 
the command printed here may not exactly match what you typed but it should work in MOST cases.  
The main case where it will get the command wrong is when you list files with a * (i.e. 
../00-raw/*.fq) instead of just a directory (i.e. ../00-raw) to look in.

### slurm.conf file

When you run the command “make_rad_experiment” a file will be created in the experiment directory 
called “slurm.conf”.  Initially this file is blank however if you add anything to it then this 
will be added to slurm scripts that are generated by the make_* commands immediately after the
 #SBATCH lines.  You can use this to add additional slurm configuration or 
custom commands to every job.

```sh
#SBATCH --mail-type=ALL
#SBATCH --mail-user=YOU@EMAIL.ADDRESS
```
**Figure**: slurm.conf example that instructs slurm to email you when you job starts and finishes 
(or errors)

## FastQC

FastQC is used to get a summary of the quality of your sequences.

```sh
module load carlaseq

# move to the directory
cd 00-raw-fastqc

# make the slurm script
# Note: make_fastqc has other options (e.g. # of cores to use) 
# see -h for details
# when in 00-raw-fastqc/
carlaseq_make_fastqc_job ../00-raw > run_fastqc

# run job
sbatch run_fastqc

cd ..
```
**Figure**: Commands used to run FastQC.  OUTPUT_DIR is a directory of your choosing, see note 
above figure.

Afterwards, your output directory should contain a directory for each sample which contains the 
fastqc results.  Note: it deletes the .zip file since it is just a compressed version of the files 
in the directory.

## Demux

Demultiplexes the sequence files as they come off illumina sequencer by the first 6 bases of read1

```
module load carlaseq

# move to the directory
cd 01-demux

# make the slurm script
carlaseq_make_demux_job ../00-raw > run_demux

# run job
sbatch run_demux

cd ..
```
**Figure**: Commands used to run Demux.


Your 01-demux directory should contain one fastq file per barcode per input file. 

## Adapter removal (trimmomatic)

The trimmomatic tool is used to remove adapter sequence from paired (or single)-end data.  If you 
are using paired-end data only give it the forward read (*_R1.fastq) files.  If using single-end 
data then it expects the name to contain ‘_R1’, so if it doesn’t then you need to change the -f 
option to reflect your files.

```sh
module load carlaseq

# move to the trimmomatic step directory
cd 02-trimmomatic

# make the slurm script
carlaseq_make_trimmomatic_job ../01-demux > run_trimmomatic

# run job
sbatch run_trimmomatic

cd ..
```
**Figure**: Commands used to run pear

Your 02-trimmomatic directory should contain one fastq file for each input fastq file.  If using 
paired-end data then there will also be another fastq for each input fastq (SAMPLENAME.sing.fastq) 
which contains any passing sequences for which it’s pair failed.  Details of sequences that were 
removed due to adapter can be found in your slurm-XXXXX.out file.

## Filter Contaminant (Kraken & Seqsets)

### Kraken (identification)

The meta genomic sequence identification tool called kraken is used

```sh
module load carlaseq

# move to the kraken step directory
cd 03-kraken

# make the slurm script
# note: carlaseq_make_kraken_job has other parameters to alter how it works (see -h opt)
carlaseq_make_kraken_job ../02-trimmomatic > run_kraken
# To kraken gz files you will need to nano into the run_kraken script and add --gzip-compressed option (type gz option before --preload)

# run job
sbatch run_kraken

cd ..
```
**Figure**: Commands used to run kraken

Afterwards, your 03-kraken directory should contain 3 files sequence file from trimmomatic step; 
classified & unclassified Fastq files as well as a classification (output) file.  There will also 
be the slurm-XXXX.out file which contains the percentage of contaminant sequences (i.e. ‘classified’ 
as bacterial) for each sample.  The ‘*_unclassified.fastq’ file are the important ones (i.e. not 
contaminated)

### Seq-sets (removal)

The general purpose utility called seq-sets is used to remove the contaminated sequences from the 
raw data.  It calculates the union of the classified read 1 and read 2 files from kraken and outputs 
any of the raw sequences that are NOT present in the union.  See Venn diagram below.


Figure: venn diagram showing the classification of read 1 and read 2.  Seq-sets keeps only sequences 
NOT in the UNION of read1 and read2 classified.  i.e. 83% unclassified reads in this example.

```sh
module load carlaseq

# move to the filtered step directory
cd 04-seqsets

# make the slurm script
# Note: run carlaseq_make_seqsets_job -h to see other options
carlaseq_make_seqsets_job -k ../03-kraken -f '*_R[1-2].f*q*' -- ../02-trimmomatic > run_seqsets
# NOTE: -- flag means no more flags will appear after this. Hence all additional options need to go before the -- flag.

# run job
sbatch run_seqsets

cd ..
```
**Figure**: Commands used to run raw sequence filtering

Afterwards, your 04-seqsets directory should contain 1 fastq file per raw fastq file, the 
run_seq-sets script and the slurm-XXXX.out file.  The slurm-XXXX.out file contains lots of 
useful information about how the filtering went including the percentage of sequences that 
were removed from each file.

**NOTE**: if the amount filtered is less than 1.5% then you should NOT use the filtered results 
in the next step.  Instead, you should just use the adapter removed sequences.

Merge overlapping pairs (pear)
The Pear tool is used to merge overlapping paired-end sequences.  This will only be useful if 
your insert size is smaller than 2x read length.

```sh
module load carlaseq

# move to the paired step directory
cd 05-pear

# make the slurm script
carlaseq_make_pear_job ../04-seqsets -T '_filter*' > run_pear

# you may want to add settings in run_pear.  Use the OPTS="" line to add them.

# run job
sbatch run_pear

cd ..
```
**Figure**: Commands used to run pear

Your 05-pear directory should contain 5 fastq files per pair of input fastq files; assembled, 
discarded, unassembled forward, unassembled reverse and merge (which contains the contents of 
assembled and unassembled forward/reverse files).  The slurm-XXXXX.out file will contain the 
number of sequences that were merged.  

**NOTE**: The ‘*.merge.fastq’ files are used in the next step.

## De-duplication

No longer performed

## FastQ to FastA

FastQ files from earlier step are merged and converted to FastA format.

```sh
module load carlaseq

# move to the paired step directory
cd 06-fq2fa

# make the slurm script
carlaseq_make_fq2fa_job ../05-pear > run_fq2fa

# run job
sbatch run_fq2fa

cd ..
```
**Figure**: Commands used to run fq2fa

Your 06-fq2fa directory should contain 1 fasta file (called target_all.fasta) which is simple a 
FastA format of all sequences found in ‘*.merge.fastq’ from the previous step.

## Cluster

FastA targets are clustered at a given identity

```sh
module load carlaseq

# move to the paired step directory
cd 07-cluster

# make the slurm script
# -j controls number of threads/CPUs to use
# -i controls the clustering identity
carlaseq_make_cluster_job -j 4 -i 0.75 ../06-fq2fa/target_all.fasta > run_cluster_0.75

# run job
sbatch run_cluster_0.75

cd ..
```
**Figure**: Commands used to run vsearch clustering

Your 07-cluster directory will contain one fasta file per fasta file from the fq2fa step.

**NOTE**: you can run this multiple times with different identity if you wish.  If you do this, then 
you will need to reproduce the run_* scripts in any later steps if you created them before doing 
so.

## Filter Clusters

Removes clusters smaller than a given size

```sh
module load carlaseq

# move to the paired step directory
cd 08-filter-size

# make the slurm script
# -c option controls the minimum number of clusters to accept.
# NOTE: it’s a good idea to include this number in your run script name
carlaseq_make_filter_cluster_size_job ../07-cluster -c 20 > run_filter_size20

# NOTE: the run_filter.. script will hard code the source fasta files from 07-.. step.  You will need to rerun the make_filter.. command if you rerun earlier steps with different options/names

# run job
sbatch run_filter_size20

cd ..
```
**Figure**: Commands used to run cluster size filtering

Your 08-filter-size will contain one fasta file for each fasta file found in 07-cluster step.  
Note: the search for fasta files is performed when you run ‘carlaseq_make_filter_cluster_size_job’ 
script so if you make changes to identity in step 7 then you will need to recreate the run_filter_* 
script.

**NOTE**: if you only want to re-run a single fasta file then replace ‘../07-cluster’ in the make_filter 
command with the actual fasta file you want to process.

## Blast Probes

Blasts the target sequences against the probes database file

```sh
module load carlaseq

# move to the paired step directory
cd 09-blastprobes

# copy your probes database into the current directory.
cp XXX.fa probes.fasta

# make the slurm script
# -j controls the number of threads
# -d sets the name of the probes database fasta file
carlaseq_make_blastprobes_job -j 8 ../08-filter-size -d probes.fasta > run_blast_probes

# run job
sbatch run_blast_probes

cd ..
```
**Figure**: Commands used to run blast against probes

Your 09-blastprobes directory will contain 3 files per input fasta file: (1) *_hits.tsv contains 
the blastn (megablast) output results, (2) *_hits.list’ contains the sequence id’s for the centroids 
that matched a sequence in your probes.fasta, (3) *_hits.fa contains a the sequence of the ID’s 
in *_hits.list file in FastA format.

