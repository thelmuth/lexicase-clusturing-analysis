
args <- commandArgs(trailingOnly = TRUE)

directory = args[1]
data_file = args[2]

source(paste(directory, '../scripts/clustering.R', sep=""))

transform_data_file_into_error_file(data_file)
