
args <- commandArgs(trailingOnly = TRUE)

directory = args[1]
data_file = args[2]

source(paste0(directory, '../scripts/clustering.R'))

transform_data_file_into_error_file(data_file)
