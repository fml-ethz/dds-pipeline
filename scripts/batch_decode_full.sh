#!/bin/bash 

# check if the input directory exists
if [ ! -d "$1" ]; then
    echo "Input directory does not exist."
    exit 1
fi

# iterate over all subdirectories in the input directory
for dir in "$1"/*/; do
    printf "\n\n########################################################\n" "$dir"
    printf "\n Processing directory: %s\n" "$dir"
    printf "\n########################################################\n" "$dir"

    # get the name of the directory
    dir_name=$(basename "$dir")

    # execute the decode_full.sh script
    /scripts/decode_full.sh "$dir/R1.fq.gz" "$dir/R2.fq.gz" "${@:2}"

    if [ $? -eq 0 ]; then 
        printf "\n\n########################################################\n" "$dir"
        printf "\n Successfully processed directory: %s\n" "$dir"
        printf "\n########################################################\n" "$dir"

        # print success to output file
        echo "$dir_name: successfully processed, but this does not mean decoding succeeded" >> "$1/log_batch_decode_full.txt"
    else 
        printf "\n\n########################################################\n" "$dir"
        printf "\n Failed to process directory: %s\n" "$dir"
        printf "\n########################################################\n" "$dir"
        echo "An error occurred while processing $dir. Please check the logs."

        # print error to output file
        echo "$dir_name: error during processing, check logs" >> "$1/log_batch_decode_full.txt"
    fi

    # combine the data from the subdirectory into a single file
    for file in 'md5hash' 'size' 'errorperseq' 'erasures' 'nreads'; do
        /scripts/combine_data.sh "$dir/decoding_full/${file}.txt" "$dir_name" "$1/${file}_batch_decode_full.txt"
    done

done

exit