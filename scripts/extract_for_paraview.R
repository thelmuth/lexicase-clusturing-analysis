library("reshape2")

original_csv_data <- read.csv("../data/Replace space with newline/rswn_lexicase_errors0.csv")
max_column = ncol(original_csv_data)

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
scaled_data$individual = original_csv_data$individual
scaled_data$size = scale(original_csv_data$size, 0, max(original_csv_data$size))

# Now we melt the data
melted_data <- melt(scaled_data, id.vars=c("generation", "individual"))

# Split the test cases into the even and odd. This won't be generally useful, but is
# important for the "Replace space with newline" problem. For that problem, there are
# two types of test cases that are interleaved: Error in what's printed, and error in
# what's actually returned from the evolved function.
even_cases <- subset(melted_data, 
                     substring(variable, 1, 2) == "TC" &
                       as.integer(substring(variable, 3)) %% 2 == 0)
odd_cases <- subset(melted_data, 
                     substring(variable, 1, 2) == "TC" &
                       as.integer(substring(variable, 3)) %% 2 == 1)
