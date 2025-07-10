#!/bin/bash 
set -e

# check if the forward sequencing file exists and ends in .fq.gz
if [ ! -f "$1" ] || [[ "$1" != *.fq.gz ]]; then
    echo "Forward sequencing file must be a .fq.gz file."
    exit 1
fi

# check if the reverse sequencing file exists and ends in .fq.gz
if [ ! -f "$2" ] || [[ "$2" != *.fq.gz ]]; then
    echo "Reverse sequencing file must be a .fq.gz file."
    exit 1
fi

# define a variable for the directory where the output will be saved
DECODING_DIR="$(dirname "$1")/decoding_full"

# create a directory named decoding in the parent folder of the input files, and if it exists, throw an error
if [ -d "$DECODING_DIR" ]; then
    echo "Directory for the output, $DECODING_DIR, already exists. Please remove it before re-running this script."
    exit 1
fi
mkdir -p "$DECODING_DIR"

# save the full command to file
echo "Command: $0 $@" > "$DECODING_DIR/command.txt"

# merge the paired reads
printf "\n\n# Merging reads ...\n\n"
/scripts/merge.sh "$1" "$2" "$DECODING_DIR/merged.fq.gz" 2>&1 | tee "$DECODING_DIR/log_merge.txt"

# cluster the merged reads
printf "\n\n# Clustering reads ...\n\n"
/scripts/cluster.sh "$DECODING_DIR/merged.fq.gz" "$DECODING_DIR/clusters" 2>&1 | tee "$DECODING_DIR/log_clustering.txt"
rm -f "$DECODING_DIR/merged.fq.gz"

# padtrim the clustered reads
printf "\n\n# Padtrimming reads ...\n\n"
/scripts/padtrim.sh "$DECODING_DIR/clusters" "$DECODING_DIR/input" "$3" 2>&1 | tee "$DECODING_DIR/log_padtrim.txt"
rm -f "$DECODING_DIR/clusters"

# decode the file and save the output in the decoding directory
printf "\n\n# Decoding ...\n\n"
/scripts/raw_decode.sh "$DECODING_DIR/input" "$DECODING_DIR/output" "${@:4}" 2>&1 | tee "$DECODING_DIR/log_decoding.txt"
rm -f "$DECODING_DIR/input"

# save decoding stats
python /scripts/helpers/parse_decoding_output.py "$DECODING_DIR/log_decoding.txt" "$DECODING_DIR/errorperseq.txt" "$DECODING_DIR/erasures.txt" "$DECODING_DIR/nreads.txt"

# check if the output file was created
if [ ! -f "$DECODING_DIR/output" ]; then
    echo "Decoding failed. Output file not created. Check logs."
    exit 1
fi

# save a md5 hash of the output file
md5sum "$DECODING_DIR/output" > "$DECODING_DIR/md5hash.txt"

# save the size of the output file
stat -c%s "$DECODING_DIR/output" > "$DECODING_DIR/size.txt"