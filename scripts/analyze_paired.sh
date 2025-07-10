#!/bin/bash 
set -e

# check if the forwards sequencing file exists and ends in .fq.gz
if [ ! -f "$1" ] || [[ "$1" != *.fq.gz ]]; then
    echo "Forward sequencing file must be a .fq.gz file."
    exit 1
fi

# check if the reverse sequencing file exists and ends in .fq.gz
if [ ! -f "$2" ] || [[ "$1" != *.fq.gz ]]; then
    echo "Reverse sequencing file must be a .fq.gz file."
    exit 1
fi

# check if the design file exists and ends in .fasta
if [ ! -f "$3" ] || [[ "$3" != *.fasta ]]; then
    echo "Design file must be a .fasta file."
    exit 1
fi

# define a variable for the directory where the output will be saved
ANALYSIS_DIR="$(dirname "$1")/analysis_paired"

# create a directory named analysis in the parent folder of the input files, and if it exists, throw an error
if [ -d "$ANALYSIS_DIR" ]; then
    echo "Directory for the output, $ANALYSIS_DIR, already exists. Please remove it before re-running this script."
    exit 1
fi
mkdir -p "$ANALYSIS_DIR"

# create symlinks to the input files in the analysis directory
ln -s "$(realpath "$1")" "$ANALYSIS_DIR/R1.fq.gz"
ln -s "$(realpath "$2")" "$ANALYSIS_DIR/R2.fq.gz"
ln -s "$(realpath "$3")" "$ANALYSIS_DIR/design_files.fasta"

# run the analysis pipeline
dt4dds-analysis -c standard "$ANALYSIS_DIR" --paired 2>&1 | tee "$ANALYSIS_DIR/log.txt"

# remove the symlinks
rm -f "$ANALYSIS_DIR/R1.fq.gz"
rm -f "$ANALYSIS_DIR/R2.fq.gz"
rm -f "$ANALYSIS_DIR/design_files.fasta"

# remove mapped.bam
rm -f "$ANALYSIS_DIR/mapped.bam"

# move everything and extract the main analysis results
mv "$ANALYSIS_DIR/analysis" "$ANALYSIS_DIR/detailed_analysis"
python /scripts/helpers/extract_analysis_results.py "$ANALYSIS_DIR/detailed_analysis/fw.global.mapped_high.stats" "$ANALYSIS_DIR" fw
python /scripts/helpers/extract_analysis_results.py "$ANALYSIS_DIR/detailed_analysis/rv.global.mapped_high.stats" "$ANALYSIS_DIR" rv

exit