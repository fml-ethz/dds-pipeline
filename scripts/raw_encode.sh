#!/bin/bash 
set -e

# run encoding
/dnars/simulate/texttodna --encode "${@:3}" --input="$1" --output="$2"

exit