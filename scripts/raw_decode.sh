#!/bin/bash 
set -e

# run decoding
/dnars/simulate/texttodna --decode "${@:3}" --input="$1" --output="$2"

# if the output is larger than the input, then delete the output file
if [ $(stat -c%s "$2") -gt $(stat -c%s "$1") ]; then
    echo "Output is larger than input, therefore decoding failed. Deleting output file to save space."
    rm -f "$2"
    exit 1
fi

exit