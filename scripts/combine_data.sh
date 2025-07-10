#!/bin/bash 
set -e

# check if file was created
if [ -f "$1" ]; then
    data=$(cat "$1")
else
    data="None"
fi

# print to output file
echo "$2,$data" >> "$3"