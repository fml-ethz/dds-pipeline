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
ANALYSIS_DIR="$(dirname "$1")/analysis_clustered"

# create a directory named analysis in the parent folder of the input files, and if it exists, throw an error
if [ -d "$ANALYSIS_DIR" ]; then
    echo "Directory for the output, $ANALYSIS_DIR, already exists. Please remove it before re-running this script."
    exit 1
fi
mkdir -p "$ANALYSIS_DIR"

# merge the paired reads
printf "\n\n# Merging reads ...\n\n"
/scripts/merge.sh "$1" "$2" "$ANALYSIS_DIR/merged.fq.gz" 2>&1 | tee "$ANALYSIS_DIR/log_merge.txt"

# cluster the merged reads
printf "\n\n# Clustering reads ...\n\n"
/scripts/cluster.sh "$ANALYSIS_DIR/merged.fq.gz" "$ANALYSIS_DIR/clusters" 2>&1 | tee "$ANALYSIS_DIR/log_clustering.txt"
rm -f "$ANALYSIS_DIR/merged.fq.gz"

# convert the clustered reads to fastq.gz format
printf "\n\n# Converting clustered reads to fastq format ...\n\n"
awk '{printf "@read%d\n%s\n+\n", NR, $0; q=""; for(i=1;i<=length($0);i++) q=q "F"; print q}' "$ANALYSIS_DIR/clusters" | gzip > "$ANALYSIS_DIR/R1.fq.gz"
rm -f "$ANALYSIS_DIR/clusters"

# create symlink to the design file in the analysis directory
ln -s "$(realpath "$3")" "$ANALYSIS_DIR/design_files.fasta"

# run the analysis pipeline
dt4dds-analysis -c standard "$ANALYSIS_DIR" 2>&1 | tee "$ANALYSIS_DIR/log.txt"

# remove the symlinks
rm -f "$ANALYSIS_DIR/R1.fq.gz"
rm -f "$ANALYSIS_DIR/design_files.fasta"

# remove mapped.bam
rm -f "$ANALYSIS_DIR/mapped.bam"

# move everything and extract the main analysis results
mv "$ANALYSIS_DIR/analysis" "$ANALYSIS_DIR/detailed_analysis"
python /scripts/helpers/extract_analysis_results.py "$ANALYSIS_DIR/detailed_analysis/fw.global.mapped_high.stats" "$ANALYSIS_DIR" fw

exit