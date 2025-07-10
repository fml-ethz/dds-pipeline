import argparse
import pathlib
import yaml

parser = argparse.ArgumentParser(description='Parse data from analysis output.')
parser.add_argument('input_file', type=str, help='Input file with output from error analysis')
parser.add_argument('target_directory', type=str, help='Output directory to write files into')
parser.add_argument('suffix', type=str, help='File suffix to use for output files')
args = parser.parse_args()

# define paths
input_file = pathlib.Path(args.input_file)
target_directory = pathlib.Path(args.target_directory)

# read the input file
data = yaml.safe_load(input_file.read_text())

# write error rates
with open(target_directory / f'errorrates_{args.suffix}.txt', 'w') as f:
    f.write(','.join([str(data.get(x, 0)) for x in ('r_matches', 'r_deletions', 'r_insertions', 'r_substitutions')]))

# write read stats
with open(target_directory / f'readstats_{args.suffix}.txt', 'w') as f:
    f.write(','.join([str(data.get(x, 0)) for x in ('r_read_perfect', 'r_read_nodeletion', 'r_read_noinsertion', 'r_read_nosubstitution')]))

# write deletion base bias
with open(target_directory / f'delbias_{args.suffix}.txt', 'w') as f:
    f.write(','.join([str(data['p_deletions_by_type'].get(x, 0)) for x in ('A', 'C', 'G', 'T')]))

# write insertion base bias
with open(target_directory / f'insbias_{args.suffix}.txt', 'w') as f:
    f.write(','.join([str(data['p_insertions_by_type'].get(x, 0)) for x in ('A', 'C', 'G', 'T')]))

# write substitution base bias
with open(target_directory / f'subbias_{args.suffix}.txt', 'w') as f:
    f.write(','.join([str(data['p_substitutions_by_type'].get(x, 0)) for x in ('A2C', 'A2G', 'A2T', 'C2A', 'C2G', 'C2T', 'G2A', 'G2C', 'G2T', 'T2A', 'T2C', 'T2G')]))

# get maximum reference position
max_ref_position = 0
if len(data['p_deletions_by_refposition'].keys()) > 0:
    max_ref_position = max(max_ref_position, max(data['p_deletions_by_refposition'].keys()))
if len(data['p_insertions_by_refposition'].keys()) > 0:
    max_ref_position = max(max_ref_position, max(data['p_insertions_by_refposition'].keys()))
if len(data['p_substitutions_by_refposition'].keys()) > 0:
    max_ref_position = max(max_ref_position, max(data['p_substitutions_by_refposition'].keys()))

# write deletion position bias
with open(target_directory / f'delposition_{args.suffix}.txt', 'w') as f:
    f.write(','.join([str(data['p_deletions_by_refposition'].get(x,0)) for x in range(0, max_ref_position+1)]))

# write insertion position bias
with open(target_directory / f'insposition_{args.suffix}.txt', 'w') as f:
    f.write(','.join([str(data['p_insertions_by_refposition'].get(x,0)) for x in range(0, max_ref_position+1)]))

# write substitution position bias
with open(target_directory / f'subposition_{args.suffix}.txt', 'w') as f:
    f.write(','.join([str(data['p_substitutions_by_refposition'].get(x,0)) for x in range(0, max_ref_position+1)]))