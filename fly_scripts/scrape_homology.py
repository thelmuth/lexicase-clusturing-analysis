#!/usr/bin/env python

# Takes a directory name as a single command line argument, and scrapes the
# homology data out of all the log*.txt files in that directory, writing
# the quartile data out to standard output.

import sys
import glob
import re

def print_row(run, generation, quartile, value):
    print(run + "," + str(generation) + "," + quartile + "," + str(value))

directory_to_scrape = sys.argv[1]

# Print the header line for the output CSV
print("Run,Generation,Quartile,Homology")

for file in glob.glob(directory_to_scrape + "/log*.txt"):
  with open(file) as f:
      # Extract the run number from the file name so I can include it
      # in the output in the Run column.
      run = re.match(".*log(\d+).txt", file).groups()[0]
      for line in f:
          # This whole chain of matches is super ugly and could almost
          # certainly be cleaned up a ton.
          is_gen_line = re.match("Processing generation: (\d+)", line.strip())
          if is_gen_line:
              generation = is_gen_line.groups()[0]
          is_first_quartile = re.match("First quartile(\s+\(sample 1\))?:\s+(\d+\.\d+)", line.strip())
          if is_first_quartile:
              first_quartile = is_first_quartile.groups()[1]
              print_row(run, generation, "0.25", first_quartile)
          is_median = re.match("Median(\s+\(sample 1\))?:\s+(\d+\.\d+)", line.strip())
          if is_median:
              median = is_median.groups()[1]
              print_row(run, generation, "0.5", median)
          is_third_quartile = re.match("Third quartile(\s+\(sample 1\))?:\s+(\d+\.\d+)", line.strip())
          if is_third_quartile:
              third_quartile = is_third_quartile.groups()[1]
              print_row(run, generation, "0.75", third_quartile)
