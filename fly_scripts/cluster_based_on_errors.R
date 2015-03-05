
# args should be: fly scripts directory, error_data filename, problem name, treatment, run number, height
args <- commandArgs(trailingOnly = TRUE)

directory = args[1]
error_file = args[2]
problem_name = args[3]
treatment = args[4]
run_number = args[5]
height = args[6]

source(paste0(directory, '../scripts/clustering.R'))

df = make_frame_from_errors_file(
  error_file, as.numeric(run_number), problem_name, treatment,
  as.numeric(height), elitize_generation_data)

out_file_path = paste0("clustering/error_clustering_and_div", run_number, ".csv")

write.csv(df, out_file_path)
