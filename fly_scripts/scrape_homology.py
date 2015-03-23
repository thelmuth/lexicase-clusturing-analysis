#!/usr/bin/env python

# Takes a directory name as a single command line argument, and scrapes the
# homology data out of all the log*.txt files in that directory, putting the
# results in the name of the directory with "_homology.csv" appended.

import sys
import glob
import re

def print_row(run, generation, quartile, value):
    print(run + "," + str(generation) + "," + quartile + "," + str(value))

directory_to_scrape = sys.argv[1]

print("Run,Generation,Quartile,Homology")
for file in glob.glob(directory_to_scrape + "/log*.txt"):
  with open(file) as f:
      run = re.match(".*log(\d+).txt", file).groups()[0]
      for line in f:
          # print("<", line, ">")
          is_gen_line = re.match("Processing generation: (\d+)", line.strip())
          # print(is_gen_line)
          if is_gen_line:
              generation = is_gen_line.groups()[0]
          # First quartile:  0.93203884
          is_first_quartile = re.match("First quartile(\s+\(sample 1\))?:\s+(\d+\.\d+)", line.strip())
          # print(is_first_quartile)
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
