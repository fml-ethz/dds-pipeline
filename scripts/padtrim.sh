#!/bin/bash 
set -e

# run padding and trimming
python /scripts/helpers/padtrim.py "$1" "$2" "$3"

exit