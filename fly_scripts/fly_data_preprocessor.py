import os, stat

##########################################################################
# Settings
number_runs = 100

namespace = "replace-space-with-newline"

#selection = "lexicase"
selection = "tourney"
#selection = "ifs"

output_directory = "/home/thelmuth/Results/clustering-bench/" + namespace + "/"
r_directory = "/home/thelmuth/lexicase-clusturing-analysis/fly_scripts/"

title_string = "Preprocess Error Data | " + namespace + " | "

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

# Make alf file
alf_file_string = output_directory + "fly_data_preprocessor.alf"
alf_f = open(alf_file_string, "w")

alfcode = """##AlfredToDo 3.0
Job -title {%s} -subtasks {
""" % (title_string)

for run in range(0, number_runs):
    full_command = "echo Unzipping; cd %s; tar zxf data%i.csv.tar.gz; echo Running R transformation; Rscript %stransform_data_file.R %s data%i.csv; rm data%i.csv; echo Done" % (output_directory, run, r_directory, r_directory, run, run)

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
