library("reshape2")

# Takes a data frame in the form output by thelmuth's code and reshapes
# it into "long" form in preparation for writing out the separate ParaView
# files. It also and scales all the columns to the range [0, 1], taking the
# log of all the error columns to give us a little better resolution in the
# small values.
reshape_data <- function(original_csv_data) {
  max_column = ncol(original_csv_data)
  first_test_case_index = match("TC0", names(original_csv_data))
  colnames(original_csv_data) <- c(names(original_csv_data)[1:(first_test_case_index-1)], seq(0, max_column-first_test_case_index))
  
  # I'm going to normalize all the columns first, and then reshape the data to be in
  # the form that Paraview wants.
  
  # We want to normalize everything but the first two columns (generation and individual),
  # and we want to take the log of all the error columns to limit the skew caused by the
  # really large errors used to indicate some sort of failure.
  
  # This adds one first so all the zero values don't blow up on us. Assuming the
  # input is in the range [0, inf), then the result of this is also in that range.
  shifted_log10 <- function(x) log10(x+1)
  
  log_data <- shifted_log10(original_csv_data[, c(3, 5:max_column)])
  mins <- apply(log_data, 2, min)
  maxes <- apply(log_data, 2, max)
  scaled_data <- as.data.frame(scale(log_data, mins, maxes-mins))
  scaled_data$generation = original_csv_data$generation
  scaled_data$individual = scale(original_csv_data$individual, 0, max(original_csv_data$individual))
  scaled_data$size = scale(original_csv_data$size, 0, max(original_csv_data$size))
  
  # Now we melt the data
  melted_data <- melt(scaled_data, id.vars=c("generation", "individual", "total.error", "size"))
  
  # Add the discrete.value column that converts the test case error values
  # to either 0 (if the error was 0) or 1.
  melted_data$discrete.value = ifelse(melted_data$value==0, 0, 1)
  return(melted_data)
}

data <- read.csv("../data/Replace space with newline/rswn_lexicase_errors0.csv")
melted_data <- reshape_data(data)

this_gen <- subset(melted_data, generation==50)[c("individual", "size", "total.error", "variable", "value", "discrete.value")]
write.csv(this_gen, file = paste("foo.csv.", 50, sep=""), sep=",", row.names=FALSE)

for (g in unique(melted_data$generation)) {
  this_gen <- subset(melted_data, generation==g)[c("individual", "size", "total.error", "variable", "value", "discrete.value")]
  write.csv(this_gen, file = paste("../data/Replace space with newline/rswn_lexicase_errors0.csv.", g, sep=""), sep=",", row.names=FALSE)
}
