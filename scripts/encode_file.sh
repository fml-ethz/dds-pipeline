#!/bin/bash 
set -e

# check if the input file exists
if [ ! -f "$1" ]; then
    echo "Input file does not exist."
    exit 1
fi

# create a directory named $1.encoded and if it exists, throw an error
if [ -d "$1.encoded" ]; then
    echo "Directory for the output, $1.encoded, already exists. Please remove it before re-running this script."
    exit 1
fi
mkdir -p "$1.encoded"

# save a md5 hash of the input file
md5sum "$1" > "$1.encoded/md5hash.txt"

# save the size of the input file
stat -c%s "$1" > "$1.encoded/size.txt"

# save the invoked command
echo "$0 $@" > "$1.encoded/command.txt"

# run encoding and save the output in $1.encoded
/scripts/raw_encode.sh "$1" "$1.encoded/sequences.txt" "${@:2}" 2>&1 | tee "$1.encoded/log.txt"

# convert the encoded file to fasta format with the sequence ID as the line number
awk '{print ">"NR"\n"$0}' "$1.encoded/sequences.txt" > "$1.encoded/design_files.fasta"

# add 0F to the beginning of each sequence and 0R to the end of each sequence
cp "$1.encoded/sequences.txt" "$1.encoded/sequences_with_primers.txt"
sed -i 's/^/ACACGACGCTCTTCCGATCT/' "$1.encoded/sequences_with_primers.txt"
sed -i 's/$/AGATCGGAAGAGCACACGTCT/' "$1.encoded/sequences_with_primers.txt"

exit