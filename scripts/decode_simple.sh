#!/bin/bash 
set -e

# check if the input file exists and ends in .fq.gz
if [ ! -f "$1" ] || [[ "$1" != *.fq.gz ]]; then
    echo "Input file must be a .fq.gz file."
    exit 1
fi

# define a variable for the directory where the output will be saved
DECODING_DIR="$(dirname "$1")/decoding_simple"

# create a directory named $DECODING_DIR and if it exists, throw an error
if [ -d "$DECODING_DIR" ]; then
    echo "Directory for the output, $DECODING_DIR, already exists. Please remove it before re-running this script."
    exit 1
fi
mkdir -p "$DECODING_DIR"

# save the full command to file
echo "Command: $0 $@" > "$DECODING_DIR/command.txt"

# uncompress the input file
gunzip -c "$1" > "$DECODING_DIR/input.fastq"

# decode the file and save the output in $DECODING_DIR/output
/scripts/raw_decode.sh "$DECODING_DIR/input.fastq" "$DECODING_DIR/output" "${@:2}" 2>&1 | tee "$DECODING_DIR/log.txt"
rm -f "$DECODING_DIR/input.fastq"

# save decoding stats
python /scripts/helpers/parse_decoding_output.py "$DECODING_DIR/log.txt" "$DECODING_DIR/errorperseq.txt" "$DECODING_DIR/erasures.txt" "$DECODING_DIR/nreads.txt"

# check if the output file was created
if [ ! -f "$DECODING_DIR/output" ]; then
    echo "Decoding failed. Output file not created. Check logs."
    exit 1
fi

# save a md5 hash of the output file
md5sum "$DECODING_DIR/output" > "$DECODING_DIR/md5hash.txt"

# save the size of the output file
stat -c%s "$DECODING_DIR/output" > "$DECODING_DIR/size.txt"