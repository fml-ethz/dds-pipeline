import argparse
import pathlib
import re

parser = argparse.ArgumentParser(description='Parse data from decoding output.')
parser.add_argument('log_file', type=str, help='Log file with output from decoding')
parser.add_argument('errors_file', type=str, help='Output file to write errors average into')
parser.add_argument('erasures_file', type=str, help='Output file to write erasure total into')
parser.add_argument('nreads_file', type=str, help='Output file to write read count into')
args = parser.parse_args()

log_file = pathlib.Path(args.log_file)
contents = log_file.read_text()

# get the float in the line "number of reads: X"
num_reads = re.search(r'number of reads: (\d+)', contents).group(1)

# get the float in the line "inner code: X errors on average corrected per sequence"
errors = re.search(r'inner code: (\d+\.\d+) errors on average corrected per sequence', contents).group(1)

# get the two floats in the line "X many erasures in block 0 of length Y"
block0 = re.search(r'(\d+) many erasures in block 0 of length (\d+)', contents)
dropout = block0.group(1)
total = block0.group(2)

# write the results to the files
with open(args.errors_file, 'w') as f:
    f.write(f"{errors}")
with open(args.erasures_file, 'w') as f:
    f.write(f"{dropout}")
with open(args.nreads_file, 'w') as f:
    f.write(f"{num_reads}")