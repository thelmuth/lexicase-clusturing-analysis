#!/usr/bin/env python

import sys
import re

def print_row(generation, quartile, value):
    print(str(generation) + "," + quartile + "," + str(value))

with open(sys.argv[1]) as f:
    print("Generation,Quartile,Homology")
    for line in f:
        # print("<", line, ">")
        is_gen_line = re.match("Processing generation: (\d+)", line.strip())
        # print(is_gen_line)
        if is_gen_line:
            generation = is_gen_line.groups()[0]
        # First quartile:  0.93203884
        is_first_quartile = re.match("First quartile:\s+(\d+\.\d+)", line.strip())
        # print(is_first_quartile)
        if is_first_quartile:
            first_quartile = is_first_quartile.groups()[0]
            print_row(generation, "'25%'", first_quartile)
        is_median = re.match("Median:\s+(\d+\.\d+)", line.strip())
        if is_median:
            median = is_median.groups()[0]
            print_row(generation, "'50%'", median)
        is_third_quartile = re.match("Third quartile:\s+(\d+\.\d+)", line.strip())
        if is_third_quartile:
            third_quartile = is_third_quartile.groups()[0]
            print_row(generation, "'75%'", third_quartile)
