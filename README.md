# 🧬📎 DDS-Pipeline - Pipelines for DNA Data Storage

- [Overview](#overview)
- [Installation Guide](#installation-guide)
- [Usage Guide](#usage-guide)
- [Implementation Details](#implementation-details)
- [How To Cite](#how-to-cite)
- [References](#references)
- [License](#license)


# Overview
DDS-Pipeline is a Docker container enabling simple and reproducible access to data encoding, data decoding, and error analysis of sequencing data for DNA data storage. To do so, this container implements the decoding and analysis pipelines as easy-to-use scripts, supporting their use by non-experts. This repository hosts the scripts, configuration files, and the manual for this Docker container.

The following tasks are supported:
- Encoding arbitrary data into DNA using the DNA-RS codec by Reinhard Heckel [1]
- Decoding sequencing data using read merging, sequence clustering and multiple sequence alignment to decrease effective error rates
- Analysing the error patterns and biases in the sequencing data using the DT4DDS tool by Andreas Gimpel [2]

In addition, the decoding and analysis tasks have scripts to support batch processing, i.e. to process multiple sequencing datasets automatically.


# Installation Guide
As a Docker container, this tool requires a working Docker installation. Please refer to the official installation instructions for [Windows](https://docs.docker.com/desktop/setup/install/windows-install/) or [macOS](https://docs.docker.com/desktop/setup/install/mac-install/) to install Docker Desktop. Alternatively, install Docker Engine on [Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

The following instructions are identical no matter which operating system is used. Note that the commands must be used within the Docker Desktop console and not your system's terminal. Generally, there are two steps: first, the Docker container must be downloaded, then, the Docker container is started locally.

## Pulling the Docker container
The built Docker container has been deposited in two container registries. Choose either registry to pull the image:
```bash
docker pull ghcr.io/fml-ethz/dds-pipeline
# or
docker pull agimpel/dds-pipeline
```
This will save the Docker container locally. For the following section, use the command for the same registry you just used.

## Starting the Docker container
In order to use the Docker container, a local directory on your computer must be mounted ('shared') with the Docker container to exchange files and data. This folder must exist on your computer, and can be either empty of already filled. Replace the absolute path to this folder in the following commands:

```bash
docker run --mount type=bind,src=<path/to/shared/dir>,dst=/data -it ghcr.io/fml-ethz/dds-pipeline bash
# or
docker run --mount type=bind,src=<path/to/shared/dir>,dst=/data -it agimpel/dds-pipeline bash

# example using a folder called dds-pipeline-share on your Desktop on Windows:
docker run --mount type=bind,src=c:/Users/USERNAME/Desktop/dds-pipeline-share,dst=/data -it ghcr.io/fml-ethz/dds-pipeline bash

# example using a folder called dds-pipeline-share on your Desktop on MacOS:
docker run --mount type=bind,src=~/Desktop/dds-pipeline-share,dst=/data -it ghcr.io/fml-ethz/dds-pipeline bash
```

> [!NOTE]
> This command has to be re-run every time you wish to use the Docker container after you closed the terminal or stopped the container. Also, Docker Desktop creates a new container each time you run this command. The previous, old containers can be safely deleted.

Upon running the above command, you will have terminal access within the container. Your working directory is `/data` which corresponds to the top level of the folder you mounted with your command above. Thus, all file paths within your container are now relative to `/data`, e.g. a file `myfile.txt` in your shared directory now has the path `/data/myfile.txt`. To orient yourself, check the contents of your directory with `ls`.


# Usage Guide
The pipelines implemented in this Docker container support the following actions:
- [Encoding files](#file-encoding) into DNA sequences
- [Decoding files](#file-decoding) from sequencing data
- [Analyzing the error patterns](#error-analysis) in sequencing data

> [!IMPORTANT]
> Please make sure you have started the Docker container locally and have mounted a local directory into it. If you have not, please follow the instructions in the [previous section on installation](#installation-guide).


### Required file formats and folder structure
This tool has specific requirements on the file format and folder structure for the decoding and analysis tasks. Please ensure that your input files follow these requirements to ensure that the pipelines run successfully.

__File Formats:__
- sequencing data must be supplied as gzipped FASTQ files with the file ending `.fq.gz`. This is the default format directly from the sequencer.
- reference sequences for error analysis must be supplied as a FASTA file with the ending `.fasta`. A suitable file of this type is automatically generated during the encoding step, and is called `design_files.fasta`.


__Folder Structure:__\
Following the folder structure is only required if using the scripts for batch processing. However, it is highly advised to follow this folder structure for all decoding and analysis tasks. Note that the file names (but not the folder names) are also mandatory if using the scripts for batch processing.
```
<mounted directory>
└── MyExperiments
    ├── Experiment1
    │   ├── R1.fq.gz            (forward reads)
    │   ├── R2.fq.gz            (optional, reverse reads)
    │   └── design_files.fasta  (reference sequences, needed for analysis)
    ├── Experiment2
    │   ├── R1.fq.gz
    │   ├── R2.fq.gz
    │   └── design_files.fasta
    etc ...
```


### Setup of demo folder for examples
A folder with demo data is provided in this repository and within the Docker container. Throughout this usage guide, examples will use this demo data to exemplify the usage of commands. To use them, execute the following in the Docker container:
```bash
/scripts/setup_demo.sh
```
The demo data is also available in this repository, at [demo/raw/](/demo/raw/). The structure of the demo data is as follows:
```
/data
└── DemoData
    ├── MyOriginalFile          (file to be encoded into DNA)
    ├── codec_parameters.xlsx   (settings file for encoding)
    │
    ├── MySingleExperiment      (experiment folder for single processing)
    │   ├── R1.fq.gz            
    │   ├── R2.fq.gz            
    │   └── design_files.fasta  
    │
    └── MyMultipleExperiments   (folder with subfolders for batch processing)
        ├── BatchExperiment1
        │   ├── R1.fq.gz
        │   ├── R2.fq.gz
        │   └── design_files.fasta
        └── BatchExperiment2
            ├── R1.fq.gz
            ├── R2.fq.gz
            └── design_files.fasta
```


## File Encoding
To encode a file, e.g. `MyFile.zip`, copy it into the mounted directory of the Docker container. Then, open the [Excel sheet for codec parameters](https://static-content.springer.com/esm/art%3A10.1038%2Fs41596-019-0244-5/MediaObjects/41596_2019_244_MOESM4_ESM.xlsx) and adjust the following parameters:

- Change the file size (cell A58) to the file size of your file (check via file properties)
- Select a compatible combination of sequence length (A60) and inner redundancy symbols (A23) as shown by green shading in the table. A common choice is 4 redundancy symbols and a sequence length of 108 nt, so that the full sequence with primers is 149 nt. 
- Select the number of sequences to be synthesized (A58). It is advisable to choose a value that maximizes the number of sequences within the synthesis provider's cost bracket.
- Check the outer code redundancy (A74). If the file is too large for the selected number of sequences, this will turn negative. Aim for at least 10%, depending on synthesis provider.

Note down the codec parameters `N` (A66), `K` (A67), `nuss` (A68), `numblock` (A69), `n` (A70), and `k` (A71).

> [!TIP]
> Compress your files (e.g., as a zip archive) before encoding to minimize file size. 7-Zip or similar software is recommended, as these tools allow control over compression settings, so that the smallest file sizes can be achieved.

To encode your file, execute the following command in the Docker container, replacing the codec parameters with those selected above:
```bash
/scripts/encode_file.sh <path/to/MyFile.zip> --N=<N> --K=<K> --nuss=<nuss> --numblock=<numblock> --n=<n> --k=<k>
```

> [!WARNING]
> Rarely, the encoding process stalls without progress. In this case, increase `k` by one and retry. This error is caused by rounding errors in the Excel sheet, leading to a slight underprovisioning of data-carrying sequences.


This will create a folder called `<filename>.encoded` in the same directory, with the following contents:
- __command.txt__ containing the encoding command
- __log.txt__ containing a log of the program output
- __sequences.txt__ containing the sequences created by the codec
- __design_files.fasta__ containing the sequences created by the codec, in FASTA format
- __sequences_with_primers.txt__ containing the sequences created by the codec, with default amplification primers (0F/0R)
- __md5hash.txt__ containing the MD5 hash of the file for later comparisons
- __size.txt__ containing the file size of the file for later comparisons

> [!CAUTION]
> Copy all these files, ideally together with the Excel sheet used to select the codec parameters, to a safe location. The mounted directory of the Docker container is not a safe location. Knowledge of the codec parameters is critical for the decoding step.

The generated `sequences_with_primers.txt` file can be directly used to order the pool from a commercial supplier, following the protocol by Meiser et al. [1]. However, it is strongly recommended to double-check the generated sequences prior to ordering.

> [!NOTE]
> The following example requires setting up the demo data, see section [Setup of demo folder for examples](#setup-of-demo-folder-for-examples).

In the demo setup, you can encode the demo file `DemoData/MyOriginalFile` with:
```bash
/scripts/encode_file.sh ./DemoData/MyOriginalFile --N=36 --K=32 --nuss=12 --numblock=1 --n=1000 --k=715
```
This will create 1000 sequences of 108 nt, with the output in `DemoData/MyOriginalFile.encoded/`. The codec settings are documented in `DemoData/codec_parameters.xlsx`. The processed output is also shown in this repository, at [demo/processed/MyOriginalFile.encoded/](/demo/processed/MyOriginalFile.encoded/).


## File Decoding
There are two pipelines available to decode a file using experimental sequencing data: the simple pipeline and the full pipeline. The decoding pipelines include:

- The __simple decoding pipeline__ attempts to directly decode the sequencing data, using only the forwards reads (i.e., no read merging or clustering). This follows the protocol by Meiser et al. [1]. 

- The __full decoding pipeline__ first merges the forwards and reverse reads, then clusters the sequences and creates consensus sequences via multiple sequence alignment (see the [section on implementation for more details](#implementation-details)). Only these consensus sequences are then decoded. This follows the protocol by Gimpel et al. [2].

Starting with the simple decoding pipeline is recommended, as it is faster. However, the full decoding pipeline is considerably more resilient to high error rates, as clustering drastically reduces the effective error rate. Both pipelines can be used for the same sequencing data without any problem.

Both decoding pipelines create the following output in a subdirectory:
- __command.txt__ containing the decoding command
- __log.txt__ containing a log of the decoding output
- __output__ representing the recovered, decoded file (adding a file suffix for opening potentially required)
- __md5hash.txt__ containing the MD5 hash of the decoded file for comparison to original file
- __size.txt__ containing the file size of the decoded file for comparison to original file

In addition, some statistics from the decoding process are also saved:
- __errorperseq.txt__ with the average number of error corrected per sequence (must be divided by sequence length to obtain an error rate)
- __erasures.txt__ with the number of unrecovered design sequences (must be divided by the total number of design sequences to obtain a dropout rate)
- __nreads.txt__ with the total number of reads used by the decoder

> [!TIP]
> The [plotting directory](/plotting/) of this repository contains some Jupyter Notebooks to visualize the data generated during decoding. Moreover, the [demo/processed/ subdirectory](/demo/processed/) exemplifies the usage of these Jupyter Notebooks with the demo data.


### Simple decoding pipeline
To use the simple decoding pipeline to decode sequencing data, execute the following command in the Docker container, replacing the codec parameters with those selected during encoding:
```bash
/scripts/decode_simple.sh <path/to/forward_reads.fq.gz> --N=<N> --K=<K> --nuss=<nuss> --numblock=<numblock> --n=<n> --k=<k>
```
Note that decoding might take a few seconds to multiple minutes, depending on the number of reads and the size of the file.

> [!WARNING]
> Always manually check the decoded file against the original file (e.g., via the MD5 hash), SUCCESSFULL COMPLETION OF THE DECODING PIPELINE IS NOT AN INDICATOR OF SUCCESSFUL DECODING (i.e., complete data recovery). Follow the decoding progress written to the console (or read the logfile, see below) to identify any problems encountered during decoding. 

This will create a folder called `decoding_simple` in the folder with the sequencing data, with the results of the decoding, see above.


> [!NOTE]
> The following example requires setting up the demo data, see section [Setup of demo folder for examples](#setup-of-demo-folder-for-examples).

In the demo setup, you can attempt decoding the demo experiment `DemoData/MySingleExperiment` with:
```bash
/scripts/decode_simple.sh ./DemoData/MySingleExperiment/R1.fq.gz --N=36 --K=32 --nuss=12 --numblock=1 --n=1000 --k=715
```
The output of the decoding can then be found in `DemoData/MySingleExperiment/decoding_simple/`. The processed output is also shown in this repository, at [demo/processed/MySingleExperiment/decoding_simple/](/demo/processed/MySingleExperiment/decoding_simple/). To check whether the decoding was successfull, compare the two MD5 hashes between the original file and the recovered file, like this:
```bash
diff ./DemoData/MyOriginalFile.encoded/md5hash.txt ./DemoData/MySingleExperiment/decoding_simple/md5hash.txt
```
They should be identical.


### Full decoding pipeline
To use the full decoding pipeline to decode sequencing data, both the forwards and the reverse read file must be supplied, as well as the designed sequence length (i.e., the sequence length selected in the Excel sheet during encoding). Then, execute the following command in the Docker container, replacing the codec parameters with those selected during encoding:
```bash
/scripts/decode_full.sh <path/to/forward_reads.fq.gz> <path/to/reverse_reads.fq.gz> <sequence_length> --N=<N> --K=<K> --nuss=<nuss> --numblock=<numblock> --n=<n> --k=<k>
```
Note that decoding with the full pipeline will take considerably longer than the simple pipeline, from a few minutes to an hour, depending on the number of reads and the size of the file.

> [!WARNING]
> Always manually check the decoded file against the original file (e.g., via the MD5 hash), SUCCESSFULL COMPLETION OF THE DECODING PIPELINE IS NOT AN INDICATOR OF SUCCESSFUL DECODING (i.e., complete data recovery). Also follow the decoding progress written to the console (or read the logfile, see below) to identify any problems encountered during decoding. 

This will create a folder called `decoding_full` in the folder with the sequencing data, with the results of the decoding, see above.


> [!NOTE]
> The following example requires setting up the demo data, see section [Setup of demo folder for examples](#setup-of-demo-folder-for-examples).

In the demo setup, you can attempt decoding the demo experiment `DemoData/MySingleExperiment` with:
```bash
/scripts/decode_full.sh ./DemoData/MySingleExperiment/R1.fq.gz ./DemoData/MySingleExperiment/R2.fq.gz 108 --N=36 --K=32 --nuss=12 --numblock=1 --n=1000 --k=715
```
The output of the decoding can then be found in `DemoData/MySingleExperiment/decoding_full/`. The processed output is also shown in this repository, at [demo/processed/MySingleExperiment/decoding_full/](/demo/processed/MySingleExperiment/decoding_full/). To check whether the decoding was successfull, compare the two MD5 hashes between the original file and the recovered file, like this:
```bash
diff ./DemoData/MyOriginalFile.encoded/md5hash.txt ./DemoData/MySingleExperiment/decoding_full/md5hash.txt
```
They should be identical.



### Running decoding pipelines for batch processing
To process multiple sequencing datasets using the same codec settings at once, both decoding pipelines can be run in batch mode. The corresponding scripts are called `/scripts/batch_decode_simple.sh` and `/scripts/batch_decode_simple.sh`, and are invoked with the path to a parent folder containing subfolders with sequencing data, see the [corresponding section on the folder structure above](#required-file-formats-and-folder-structure). The script will then invoke the decoding pipeline on all subfolders of this parent folder. Note that the codec parameters still need to be supplied as before.

> [!IMPORTANT]
> Running the decoding pipelines in batch mode requires that the folder structure is followed exactly, see the [corresponding section on the folder structure above](#required-file-formats-and-folder-structure).

To run the basic decoding pipeline for batch processing:
```bash
/scripts/batch_decode_simple.sh <path/to/parent_folder> --N=<N> --K=<K> --nuss=<nuss> --numblock=<numblock> --n=<n> --k=<k>
```

To run the full decoding pipeline for batch processing:
```bash
/scripts/batch_decode_full.sh <path/to/parent_folder> <sequence_length> --N=<N> --K=<K> --nuss=<nuss> --numblock=<numblock> --n=<n> --k=<k>
```

In addition to saving the decoding results for each subdirectory individually, the batch scripts also save aggregate results across all sub-experiments in the parent folder:
- __md5hash_batch_decode_simple/full.txt__ contains the MD5 hashes of all recovered files, line by line
- __size_batch_decode_simple/full.txt__ contains the file sizes of all recovered files, line by line
- __errorperseq_batch_decode_simple/full.txt__ contains the average number of corrected bases per sequence during decoding for all sub-experiments, line by line (must be divided by sequence length to obtain an error rate)
- __erasures_batch_decode_simple/full.txt__ contains the number of unrecovered sequences during decoding for all sub-experiments, line by line  (must be divided by the total number of design sequences to obtain a dropout rate)
- __nreads_batch_decode_simple/full.txt__ contains the number of sequencing reads used for decoding for all sub-experiments, line by line


> [!NOTE]
> The following example requires setting up the demo data, see section [Setup of demo folder for examples](#setup-of-demo-folder-for-examples).

In the demo setup, you can attempt batch-decoding of two demo experiments residing in the `DemoData/MyMultipleExperiments` parent folder, using either:
```bash
/scripts/batch_decode_simple.sh ./DemoData/MyMultipleExperiments --N=36 --K=32 --nuss=12 --numblock=1 --n=1000 --k=715
```
for the simple decoding pipeline, or
```bash
/scripts/batch_decode_full.sh ./DemoData/MyMultipleExperiments 108 --N=36 --K=32 --nuss=12 --numblock=1 --n=1000 --k=715
```
for the full decoding pipeline. To check whether the decoding was successfull for each sub-experiment, compare the MD5 hashes between the original file and the recovered files, like this:
```bash
diff ./DemoData/MyOriginalFile.encoded/md5hash.txt ./DemoData/MyMultipleExperiments/md5hash_batch_decode_simple.txt
diff ./DemoData/MyOriginalFile.encoded/md5hash.txt ./DemoData/MyMultipleExperiments/md5hash_batch_decode_full.txt
```
They should all be identical. The processed output is also shown in this repository, at [demo/processed/MyMultipleExperiments/](/demo/processed/MyMultipleExperiments/).



## Error Analysis
There are three pipelines available for analysing the error patterns and biases in the sequencing data. They differ in which data is analysed:

- The __single analysis pipeline__ considers only the forwards reads. This is representative of the errors encountered by the codec during the simple decoding pipeline. The results are representative of the errors occuring in the reads of the sequencing data.

- The __paired analysis pipeline__ considers both the forwards and reverse reads, individually. This is mainly useful to assess differences in error rates and error patterns between the forward and reverse reads (e.g., to assess sequencing errors).

- The __clustered analysis pipeline__ considers both the forwards and reverse reads, after they were merged and clustered. This is representative of the errors encountered by the codec during the full decoding pipeline. The results are only representative of the errors still occuring in the consensus sequences after clustering, NOT of the reads in the sequencing data.

Starting with the single analysis pipeline is recommended, as it is faster and characterizes the general error level in the sequencing data. Using the clustered analysis pipeline is only useful if the full decoding pipeline was used for decoding. When interpreting the results of the clustered analysis pipeline, it must be made clear that the errors are after clustering and consensus generation during multiple sequence alignment.

> [!TIP]
> The analysis pipelines are indifferent to the source of the reference sequences. Thus, these analysis pipelines can also be used for sequencing data that was generated with design sequences from a different codec than the DNA-RS codec implemented in the encoding pipeline.

All analysis pipelines create the following output in a subdirectory:
- __log.txt__ containing a log of the analysis output
- __detailed_analysis/__ containing the full output of the analysis tool

In addition, major statistics from the analysis are also saved separately:
- __errorrates_fw/rv.txt__ contains the overall error rates. In order, the values represent the rate of matches, rate of deletions, rate of insertions, and rate of substitutions
- __readstats_fw/rv.txt__ contains the error statistics on a read level. In order, the values represent the ratio of error-free reads, ratio of deletion-free reads, ratio of insertion-free reads, and ratio of substitution-free reads
- __delbias_fw/rv.txt__ contains the base bias of deletions. In order, the values represent the ratio of A, ratio of C, ratio of G, and ratio of T
- __insbias_fw/rv.txt__ contains the base bias of insertions. In order, the values represent the ratio of A, ratio of C, ratio of G, and ratio of T
- __subbias_fw/rv.txt__ contains the base bias of substitutions. In order, the values represent the ratio of A2C, A2G, A2T, C2A, C2G, C2T, G2A, G2C, G2T, T2A, T2C, and T2G
- __delposition_fw/rv.txt__ contains the deletion rate by sequence position. The values correspond to sequence positions, in increasing order
- __insposition_fw/rv.txt__ contains the insertion rate by sequence position. The values correspond to sequence positions, in increasing order
- __subposition_fw/rv.txt__ contains the substitution rate by sequence position. The values correspond to sequence positions, in increasing order


> [!TIP]
> The [plotting directory](/plotting/) of this repository contains some Jupyter Notebooks to visualize the data generated during analysis. Moreover, the [demo/processed/ subdirectory](/demo/processed/) exemplifies the usage of these Jupyter Notebooks with the demo data.



### Single analysis pipeline
To use the single analysis pipeline to analyze error patterns in the sequencing data, only the forwards read file must be supplied, as well as the FASTA file with the reference sequence (i.e., the sequences as designed by the encoder, usually called `design_files.fasta`). Then, execute the following command in the Docker container:
```bash
/scripts/analyze_single.sh <path/to/forward_reads.fq.gz> <path/to/design_files.fasta>
```
Analyzing the sequencing data will take a few minutes, and might take up to one hour if the sequencing dataset is large and there are many design sequences.

This will create a folder called `analysis_single` in the folder with the sequencing data, with the results of the analysis, see above.


> [!NOTE]
> The following example requires setting up the demo data, see section [Setup of demo folder for examples](#setup-of-demo-folder-for-examples).

In the demo setup, you can analyze the demo experiment `DemoData/MySingleExperiment` with:
```bash
/scripts/analyze_single.sh ./DemoData/MySingleExperiment/R1.fq.gz ./DemoData/MySingleExperiment/design_files.fasta
```
The output of the decoding can then be found in `DemoData/MySingleExperiment/analysis_single/`. The processed output is also shown in this repository, at [demo/processed/MySingleExperiment/analysis_single/](/demo/processed/MySingleExperiment/analysis_single/).


### Paired analysis pipeline
To use the paired analysis pipeline to analyze error patterns in the sequencing data, both the forwards and reverse read files must be supplied, as well as the FASTA file with the reference sequence (i.e., the sequences as designed by the encoder, usually called `design_files.fasta`). Then, execute the following command in the Docker container:
```bash
/scripts/analyze_paired.sh <path/to/forward_reads.fq.gz> <path/to/reverse_reads.fq.gz> <path/to/design_files.fasta>
```
Analyzing the sequencing data will take a few minutes, and might take up to one hour if the sequencing dataset is large and there are many design sequences.

This will create a folder called `analysis_paired` in the folder with the sequencing data, with the results of the analysis, see above.


> [!NOTE]
> The following example requires setting up the demo data, see section [Setup of demo folder for examples](#setup-of-demo-folder-for-examples).

In the demo setup, you can analyze the demo experiment `DemoData/MySingleExperiment` with:
```bash
/scripts/analyze_paired.sh ./DemoData/MySingleExperiment/R1.fq.gz ./DemoData/MySingleExperiment/R2.fq.gz ./DemoData/MySingleExperiment/design_files.fasta
```
The output of the decoding can then be found in `DemoData/MySingleExperiment/analysis_paired/`. The processed output is also shown in this repository, at [demo/processed/MySingleExperiment/analysis_paired/](/demo/processed/MySingleExperiment/analysis_paired/).



### Clustered analysis pipeline
To use the clustered analysis pipeline to analyze error patterns in the sequencing data, both the forwards and reverse read files must be supplied, as well as the FASTA file with the reference sequence (i.e., the sequences as designed by the encoder, usually called `design_files.fasta`). Then, execute the following command in the Docker container:
```bash
/scripts/analyze_clustered.sh <path/to/forward_reads.fq.gz> <path/to/reverse_reads.fq.gz> <path/to/design_files.fasta>
```
Analyzing the sequencing data will take a few minutes, and might take up to one hour if the sequencing dataset is large and there are many design sequences.

This will create a folder called `analysis_clustered` in the folder with the sequencing data, with the results of the analysis, see above.


> [!NOTE]
> The following example requires setting up the demo data, see section [Setup of demo folder for examples](#setup-of-demo-folder-for-examples).

In the demo setup, you can analyze the demo experiment `DemoData/MySingleExperiment` with:
```bash
/scripts/analyze_clustered.sh ./DemoData/MySingleExperiment/R1.fq.gz ./DemoData/MySingleExperiment/R2.fq.gz ./DemoData/MySingleExperiment/design_files.fasta
```
The output of the decoding can then be found in `DemoData/MySingleExperiment/analysis_clustered/`. The processed output is also shown in this repository, at [demo/processed/MySingleExperiment/analysis_clustered/](/demo/processed/MySingleExperiment/analysis_clustered/).


### Running analysis pipelines for batch processing
To process multiple sequencing datasets using the same analysis settings at once, all three analysis pipelines can be run in batch mode. The corresponding scripts are called `/scripts/batch_analyze_single.sh`, `/scripts/batch_analyze_paired.sh`, and `/scripts/batch_analyze_clustered.sh`, and are invoked with the path to a parent folder containing subfolders with sequencing data and reference sequences, see the [corresponding section on the folder structure above](#required-file-formats-and-folder-structure). The script will then invoke the decoding pipeline on all subfolders of this parent folder.

> [!IMPORTANT]
> Running the analysis pipelines in batch mode requires that the folder structure is followed exactly, see the [corresponding section on the folder structure above](#required-file-formats-and-folder-structure).

To run the single analysis pipeline for batch processing:
```bash
/scripts/batch_analyze_single.sh <path/to/parent_folder>
```

To run the paired analysis pipeline for batch processing:
```bash
/scripts/batch_analyze_paired.sh <path/to/parent_folder>
```

To run the clustered analysis pipeline for batch processing:
```bash
/scripts/batch_analyze_clustered.sh <path/to/parent_folder>
```

In addition to saving the analysis results for each subdirectory individually, the batch scripts also save aggregate results across all sub-experiments in the parent folder:
- __errorrates_batch_analyze_single/paired/clustered.txt__ contains the overall error rates for all sub-experiments, line by line. In order, the values represent the rate of matches, rate of deletions, rate of insertions, and rate of substitutions
- __readstats_batch_analyze_single/paired/clustered.txt__ contains the error statistics on a read level for all sub-experiments, line by line. In order, the values represent the ratio of error-free reads, ratio of deletion-free reads, ratio of insertion-free reads, and ratio of substitution-free reads
- __delbias_batch_analyze_single/paired/clustered.txt__ contains the base bias of deletions for all sub-experiments, line by line. In order, the values represent the ratio of A, ratio of C, ratio of G, and ratio of T
- __insbias_batch_analyze_single/paired/clustered.txt__ contains the base bias of insertions for all sub-experiments, line by line. In order, the values represent the ratio of A, ratio of C, ratio of G, and ratio of T
- __subbias_batch_analyze_single/paired/clustered.txt__ contains the base bias of substitutions for all sub-experiments, line by line. In order, the values represent the ratio of A2C, A2G, A2T, C2A, C2G, C2T, G2A, G2C, G2T, T2A, T2C, and T2G
- __delposition_batch_analyze_single/paired/clustered.txt__ contains the deletion rate by sequence position for all sub-experiments, line by line. The values correspond to sequence positions, in increasing order
- __insposition_batch_analyze_single/paired/clustered.txt__ contains the insertion rate by sequence position for all sub-experiments, line by line. The values correspond to sequence positions, in increasing order
- __subposition_batch_analyze_single/paired/clustered.txt__ contains the substitution rate by sequence position for all sub-experiments, line by line. The values correspond to sequence positions, in increasing order



> [!NOTE]
> The following example requires setting up the demo data, see section [Setup of demo folder for examples](#setup-of-demo-folder-for-examples).

In the demo setup, you can batch-analyze the two demo experiments residing in the `DemoData/MyMultipleExperiments` parent folder, using:
```bash
/scripts/batch_analyze_single.sh ./DemoData/MyMultipleExperiments
```
for the single analysis pipeline, or
```bash
/scripts/batch_analyze_paired.sh ./DemoData/MyMultipleExperiments
```
for the paired analysis pipeline, or
```bash
/scripts/batch_analyze_clustered.sh ./DemoData/MyMultipleExperiments
```
for the clustered analysis pipeline. The processed output is also shown in this repository, at [demo/processed/MyMultipleExperiments/](/demo/processed/MyMultipleExperiments/).


# Implementation Details

Programmatically, the implementation of the pipelines in the Docker container is documented in the [Dockerfile](/Dockerfile) and the [scripts subdirectory](/scripts/). For details on the implementation of the individual pipelines, see the following subsections.

## Data Encoding
The data encoding is fully handled by the DNA-RS codec by Reinhard Heckel, described in [1] and available in the repository at https://github.com/reinhardh/dna_rs_coding. Amplification adapters 0F and 0R are automatically added based on the protocol by Meiser et al. [1].

## Data Decoding

The simple pipeline for decoding only uses the DNA-RS codec by Reinhard Heckel, described in [1] and available in the repository at https://github.com/reinhardh/dna_rs_coding. It directly uses the forwards reads for decoding, without any read merging or clustering. To increase decoding speed, the inner decoding of individual blocks was parallelized using OpenMP, see the fork at https://github.com/agimpel/dna_rs_coding.

The implementation of the full decoding pipeline consists of five steps:

1. Read merging by NGmerge
2. Read clustering by CD-HIT
3. Consensus generation by multiple sequence alignment via BioPython
4. Padding and trimming of consensus sequences to the design length
5. Data decoding by the DNA-RS codec

### Read merging
The forwards and reverse reads are merged in stitch mode using NGmerge by John M. Gaspar [3], available from the repository at https://github.com/jsh58/NGmerge. By read merging, sequencing adapters are removed the error level is slightly reduced. The parameters used for read merging are:
```bash
NGmerge -1 <R1.fq.gz> -2 <R2.fq.gz> -o <merged.fq.gz> -d -e 20 -z -v
```
Enabling the evaluation of dovetailed arrangements via `-d` is very important, as sequences are often shorter than the read length of the synthesizer, leading to fully overlapping segments.

### Read clustering
The merged reads are clustered using CD-HIT by Weizhong Li [4,5], available from the repository at https://github.com/weizhongli/cdhit. By clustering, the erroneous sequencing reads of each reference sequence are grouped, thereby enabling the generation of consensus sequences in the next step. Due to the input requirements of CD-HIT, the merged reads from the previous step are first converted to FASTA format. Then, the used parameters for clustering are:
```bash
cd-hit-est -i <merged_reads.fasta> -o <clusters.fasta> -sf 1 -bak 1 -c 0.85 -n 6
```
The choice of CD-HIT as clustering algorithm, as well as its main parameters - sequence identity threshold (`c`) and word length (`n`) - are based on empirical optimization performed in the preprint by Gimpel et al. [6].

The output of CD-HIT contains a FASTA file of representative sequences (the centroids of each cluster) and a text file with the identifiers of the reads belonging to each cluster. Using the file of representative sequences does NOT yield a reduction in error rate, as it only lists each cluster's most representative original read, rather than the cluster's consensus sequence. To enable consensus generation in the next step, a Python script (at [scripts/helpers/parse_clusters.py](/scripts/helpers/parse_clusters.py)) parses the second file generated by CD-HIT to compile the reads of each cluster.


### Consensus generation
The reads belonging to each cluster are fed into kalign by Timo Lassmann [7] to create a multiple sequence alignment, available from the repository at https://github.com/TimoLassmann/kalign. This alignment is then fed into Biopython's sequence motif analysis to generate a consensus sequence, see [scripts/helpers/cluster2consensus.py](/scripts/helpers/cluster2consensus.py). Importantly, only up to 100 reads from each cluster are used to generate the alignment, to increase performance for large sequencing datasets.


### Padding and trimming
The DNA-RS codec cannot handle input sequences shorter than the design length, thus the consensus sequences are padded to the design length with random nucleotides. Moreover, consensus sequences longer than the design length are trimmed, as the DNA-RS codec discards these overhangs anyway. The script used for padding and trimming is located at [scripts/helpers/padtrim.py](/scripts/helpers/padtrim.py).


### Data decoding
The full pipeline for decoding also uses the DNA-RS codec by Reinhard Heckel, described in [1] and available in the repository at https://github.com/reinhardh/dna_rs_coding. In the full pipeline, it used the merged, clustered, and padded/trimmed reads for decoding. To increase decoding speed, the inner decoding of individual blocks was parallelized using OpenMP, see the fork at https://github.com/agimpel/dna_rs_coding.



## Error analysis
The analysis of error patterns and biases is fully handled by the `dt4dds` Python package by Andreas Gimpel, described in [2] and available in the repository at https://github.com/fml-ethz/dt4dds. The analysis scripts within DT4DDS call BBMap internally, a read mapper developed by Brian Bushnell, described in [8] and available in the repository at https://sourceforge.net/projects/bbmap/.


# How To Cite
There is no manuscript directly associated to DDS-Pipeline. However, if you used DDS-Pipeline in your work, please reference this repository __and reference the publications belonging to the pipeline components you used__, e.g.

> The encoding and decoding of data, as well as the error analysis of sequencing data, was performed with DDS-Pipeline (github.com/fml-ethz/dds-pipeline). Encoding and decoding used the DNA-RS codec [1], with read merging by NGmerge [3], read clustering by CD-HIT [4,5], and multiple-sequence alignment by kalign [7]. The error analysis used the Python package dt4dds [6].

Feel free to remove individual parts of this statement if certain pipeline components were not used, i.e., beccause only the simple decoding pipeline was used or no error analysis was performed.

# References

1. Meiser, L.C., Antkowiak, P.L., Koch, J. et al. Reading and writing digital data in DNA. Nat Protoc 15, 86–101 (2020). https://doi.org/10.1038/s41596-019-0244-5
2. Gimpel, A.L., Stark, W.J., Heckel, R. et al. A digital twin for DNA data storage based on comprehensive quantification of errors and biases. Nat Commun 14, 6026 (2023). https://doi.org/10.1038/s41467-023-41729-1
3. Gaspar, J.M. NGmerge: merging paired-end reads via novel empirically-derived models of sequencing errors. BMC Bioinformatics 19, 536 (2018). https://doi.org/10.1186/s12859-018-2579-2
4. Li W., Godzik A. Cd-hit: a fast program for clustering and comparing large sets of protein or nucleotide sequences. Bioinformatics 22, 13, 1658–1659 (2006). https://doi.org/10.1093/bioinformatics/btl158
5. Fu L., Niu B., Zhu Z., Wu S., Li W. CD-HIT: accelerated for clustering the next-generation sequencing data. Bioinformatics 28, 23, 3150-3152 (2012). https://doi.org/10.1093/bioinformatics/bts565
6. Gimpel, A.L., Remschak, A., Stark, W.J., et al. Comparison of state-of-the-art error-correction coding for sequence-based DNA data storage. Preprint at Research Square (2025).
7. Lassmann T. Kalign 3: multiple sequence alignment of large datasets, Bioinformatics 36, 6, 1928–1929 (2020). https://doi.org/10.1093/bioinformatics/btz795
8. Bushnell B., Rood J., Singer E. BBMerge – Accurate paired shotgun read merging via overlap. PLOS ONE 12, 10, e0185056 (2017). https://doi.org/10.1371/journal.pone.0185056


# License

The individial parts of the pipeline are individually published under their own licenses:

- DNA-RS codec by Reinhard Heckel, Apache-2.0 license, https://github.com/reinhardh/dna_rs_coding
- NGmerge by John M. Gaspar, MIT license, https://github.com/jsh58/NGmerge
- CD-HIT by Weizhong Li, GPL-2.0 license, https://github.com/weizhongli/cdhit
- kalign by Timo Lassmann, GPL-3.0 license, https://github.com/TimoLassmann/kalign
- DT4DDS by Andreas Gimpel, GPL-3.0 license, https://github.com/fml-ethz/dt4dds
- BBMap by Brian Bushnell, custom license, https://sourceforge.net/projects/bbmap/

For license compatability, the scripts invoking the pipeline components are licensed under the GPLv3 license, see [LICENSE](LICENSE). The Jupyter notebooks for plotting are licensed under the MIT license.