#!/bin/bash 
set -e

# convert fastq.gz file to fasta file
gunzip -c "$1" > "$1.uncompressed.fastq"
awk 'NR%4==1{printf(">%s\n", substr($0, 2)); next} NR%4==2{print}' "$1.uncompressed.fastq" > "$1".fasta
rm -f "$1.uncompressed.fastq"

# run clustering
/cdhit/cd-hit-est -i "$1".fasta -o "$2".fasta -sf 1 -bak 1 -c 0.85 -n 6

# parse clusters
python /scripts/helpers/parse_clusters.py "$1".fasta "$2".fasta.bak.clstr "$2".clusters
rm -f "$1".fasta
rm -f "$2".fasta
rm -f "$2".fasta.clstr
rm -f "$2".fasta.bak.clstr

# convert clusters to consensus sequences
export PYTHONWARNINGS="ignore"
python /scripts/helpers/cluster2consensus.py "$2".clusters "$2"
rm -f "$2".clusters

exit