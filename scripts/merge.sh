#!/bin/bash 
set -e

/ngmerge/NGmerge -1 "$1" -2 "$2" -o "$3" -d -e 20 -z -v

exit