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

    # execute the analyze_clustered.sh script
    /scripts/analyze_clustered.sh "$dir/R1.fq.gz" "$dir/R2.fq.gz" "$dir/design_files.fasta" "${@:2}"

    if [ $? -eq 0 ]; then 
        printf "\n\n########################################################\n" "$dir"
        printf "\n Successfully processed directory: %s\n" "$dir"
        printf "\n########################################################\n" "$dir"

        # print success to output file
        echo "$dir_name: successfully processed" >> "$1/log_batch_analyze_clustered.txt"
    else 
        printf "\n\n########################################################\n" "$dir"
        printf "\n Failed to process directory: %s\n" "$dir"
        printf "\n########################################################\n" "$dir"
        echo "An error occurred while processing $dir. Please check the logs."

        # print error to output file
        echo "$dir_name: error during processing, check logs" >> "$1/log_batch_analyze_clustered.txt"
    fi

    # combine the data from the subdirectory into a single file
    for file in 'errorrates' 'readstats' 'delbias' 'insbias' 'subbias' 'delposition' 'insposition' 'subposition'; do
        /scripts/combine_data.sh "$dir/analysis_clustered/${file}_fw.txt" "$dir_name" "$1/${file}_fw_batch_analyze_clustered.txt"
    done
done

exit