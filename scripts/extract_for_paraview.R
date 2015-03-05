library("reshape2")

# Rename all the test case columns from "TCXYZ" to just "XYZ".
# Assumes that the first test case is TC0 and that go incrementally
# from there to the last column in the data from. If it turns out
# that there are some non-test-case columns that get added to the
# right hand side of the data frame after the test case columns, then
# this logic will break and we'll need to revisit this.
rename_test_case_columns <- function(data) {
  max_column = ncol(data)
  first_test_case_index = match("TC0", names(data))
  mid = (max_column-first_test_case_index) / 2
  
  new_evens = seq(0, mid)
  new_odds = seq(floor(mid + 0.5), max_column-first_test_case_index)
  colnames(data)[seq(5, ncol(data), 2)] <- new_evens
  colnames(data)[seq(6, ncol(data), 2)] <- new_odds

  return(data)
}

# Normalizes everything but the first column (generation) so each column is in
# the range [0, 1]. This also takes the log of all the error columns to limit 
# the skew caused by the really large errors used to indicate some sort of failure.
#
# This makes a lot of assumptions about the position of the various columns, and
# thus is quite brittle in the face of change there.
scale_data <- function(data) {
  max_column = ncol(data)

  # This adds one first so all the zero values don't blow up on us. Assuming the
  # input is in the range [0, inf), then the result of this is also in that range.
  shifted_log10 <- function(x) log10(x+1)
  
  log_data <- shifted_log10(data[, c(3, 5:max_column)])
  mins <- apply(log_data, 2, min)
  maxes <- apply(log_data, 2, max)
  scaled_data <- as.data.frame(scale(log_data, mins, maxes-mins))
  scaled_data$generation = data$generation
  scaled_data$individual = scale(data$individual, 0, max(data$individual))
  scaled_data$size = scale(data$size, 0, max(data$size))
  
  return(scaled_data)
}

# Takes a data frame in the form output by thelmuth's code and reshapes
# it into "long" form in preparation for writing out the separate ParaView
# files. It also and scales all the columns to the range [0, 1], taking the
# log of all the error columns to give us a little better resolution in the
# small values.
#
# This makes some significant assumptions about the column names, which makes
# it fragile if those change.
reshape_data <- function(data) {
  melted_data <- melt(data, id.vars=c("generation", "individual", "total.error", "size"))
  
  # Add the discrete.value column that converts the test case error values
  # to either 0 (if the error was 0) or 1.
  melted_data$discrete.error = ifelse(melted_data$value==0, 0, 1)
  test_case_ids = as.integer(as.character(melted_data$variable))
  scaled_test_case_ids = scale(test_case_ids, 0, max(test_case_ids))
  melted_data$test.case.id = scaled_test_case_ids
  melted_data$variable = NULL
  names(melted_data)[names(melted_data) == 'value'] <- 'test.case.error'
  return(melted_data)
}

transform_for_paraview <- function(original_csv_data) {
  data <- rename_test_case_columns(original_csv_data)
  data <- scale_data(data)
  data <- reshape_data(data)
  return(data)
}

# Takes a data frame with a "generation" column, and splits that into one
# CSV file per generation for loading into ParaView.
write_paraview_files <- function(shaped_data, path) {
  para_dir = paste0(dirname(path), "/paraview/")
  dir.create(para_dir, showWarnings = FALSE)
  filename = basename(path)
  for (g in unique(shaped_data$generation)) {
    this_gen <- subset(shaped_data, generation==g)[c("individual", "size", "total.error", "test.case.id", "test.case.error", "discrete.error")]
    write.csv(this_gen, 
              file = paste0(para_dir, filename, ".", g), 
              row.names=FALSE)
  }
}

convert_file_to_paraview <- function(error_file_path) {
  data <- read.csv(error_file_path)
  paraview_data <- transform_for_paraview(data)
  write_paraview_files(paraview_data, error_file_path)  
}

convert_file_to_paraview("../data/replace-space-with-newline/lexicase/rswn_lexicase_errors0.csv")
