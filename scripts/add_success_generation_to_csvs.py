import os, stat, csv

##########################################################################
# Settings

namespace = "count-odds"

filename_prefix = "error_clustering_and_div"

##########################################################################
# You don't need to change anything below here

def add_success_gens(selection):
  output_directory = "../data/%s/%s/clustering/" % (namespace, selection)
  
  print "Adding success generations to files in \"%s\"" % output_directory
  
  dirList = os.listdir(output_directory)
  
  for filename in dirList:
    if not filename_prefix in filename:
      continue
    
    rows_final = []
    with open(output_directory + filename, 'r') as csvfile:
      csvreader = csv.reader(csvfile)
      rows = [r for r in csvreader]
  
      header = rows[0]
      if header[-1] == "success.generation":
        raise IOError("Already added success generations to \"%s\"" % output_directory)
      
      header.append("success.generation")
      
      success_generation = "NA"
      if rows[1][4] == "TRUE":
        success_generation = rows[-1][7]
      
      rows_but_first = rows[1:]
      for row in rows_but_first:
        row.append(success_generation)
        
      rows_final = [header] + rows_but_first
      
    with open(output_directory + filename, 'w') as csv_write_file:
      csvwriter = csv.writer(csv_write_file)
      csvwriter.writerows(rows_final)


selections = ["lexicase", "tourney", "ifs"]

for sel in selections:
  try:
    add_success_gens(sel)
  except IOError as ioe:
    print "-- " + str(ioe)
  except OSError as ose:
    print "-- " + str(ose)
    
    
