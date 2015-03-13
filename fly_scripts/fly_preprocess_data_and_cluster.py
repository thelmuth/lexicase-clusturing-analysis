import os, stat

##########################################################################
# Settings
number_runs = 100

namespace = "negative-to-zero"

height = 20

#selection = "lexicase"
selection = "tourney"
#selection = "ifs"

output_directory = "/home/thelmuth/Results/clustering-bench/" + namespace + "/"
r_directory = "/home/thelmuth/lexicase-clusturing-analysis/fly_scripts/"

title_string = "Preprocess; Find Clusters | " + namespace + " | "

# Make selection experiments easier
if selection == "lexicase":
    title_string += "lexicase"
    output_directory += "lexicase/"
if selection == "tourney":
    title_string += "tourney (size 7)"
    output_directory += "tourney-7/"
if selection == "ifs":
    title_string += "IFS (size 7)"
    output_directory += "ifs-7/"

output_directory += "csv/"

##########################################################################
# Probably don't change these

service_tag = "tom"

##########################################################################
# You don't need to change anything below here

os.mkdir(output_directory + "clustering/")

# Make alf file
alf_file_string = output_directory + "fly_error_clusterer.alf"
alf_f = open(alf_file_string, "w")

alfcode = """##AlfredToDo 3.0
Job -title {%s} -subtasks {
""" % (title_string)

for run in range(0, number_runs):
    data_preprocessing_command = "echo Unzipping; cd %s; tar zxf data%i.csv.tar.gz; echo Running R transformation; Rscript %stransform_data_file.R %s data%i.csv; echo Removing data%i.csv; rm data%i.csv;" % (output_directory, run, r_directory, r_directory, run, run, run)

    error_clustering_command = "echo Beginning clustering R script; cd %s; Rscript %scluster_based_on_errors.R %s errors_data%i.csv %s %s %i %i; echo Done;" % (output_directory, r_directory, r_directory, run, namespace, selection, run, height)

    full_command = data_preprocessing_command + error_clustering_command

    alfcode += """    Task -title {%s - run %i} -cmds {
        RemoteCmd {/bin/sh -c {%s}} -service {%s}
    }
""" % (title_string, run, full_command, service_tag)

alfcode += "}\n"

alf_f.writelines(alfcode)
alf_f.close()

# Run tractor command
source_string = "source /etc/sysconfig/pixar"
pixar_string = "/opt/pixar/tractor-blade-1.7.2/python/bin/python2.6 /opt/pixar/tractor-blade-1.7.2/tractor-spool.py --engine=fly:8000"

os.system("%s;%s %s" % (source_string, pixar_string, alf_file_string))
