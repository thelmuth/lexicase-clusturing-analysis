
library('cluster')

#setwd("~/Documents/R/Clustering/lexicase-clusturing-analysis")

transform_data_file_into_error_file <- function(file_path){
  data <- read.csv(file_path)

  columns_to_drop = c("parent.uuids", "genetic.operators", "push.program.size", "plush.genome.size", "push.program", "plush.genome")
  
  data = data[,!(names(data) %in% columns_to_drop)]
  
  write_path = paste0(dirname(file_path), "/", "errors_", basename(file_path))
  
  write.csv(data, write_path, row.names = FALSE) 
}

# Takes error data (including generation and location columns) and a generation, and returns test case error data from the given generation
extract_clustering_data = function(data, gen){
  
  print(sprintf("Generation %i", gen))
  
  this_gen_data = subset(data, generation == gen)
  
  columns_to_drop = c("generation", "location", "uuid", "total.error")
  right_cols = this_gen_data[,!(names(this_gen_data) %in% columns_to_drop)]
  
  return(right_cols)
}

# Takes a generation of error data, and converts it to 1 for eliteness on that test case and 0 for not-eliteness
elitize_generation_data = function(gen_data){
  # Note: 0 means not elite, 1 means elite
  
  result <- gen_data
  for (i in 1:length(gen_data)) {
    result[i] <- ifelse(gen_data[i] == min(gen_data[i]), 1, 0)
  }
  
  return(result)
}

# Takes a generation of error data, and converts it to 1 for passing that test case and 0 for failing
pass_fail_generation_data = function(gen_data){
  # Note: 0 means fail, 1 means pass
  return(ifelse(gen_data == 0, 1, 0))
}

# For a generation of binary data, uses agnes to cluster the data and then find the number of clusters that are at least `height` apart.
count_clusters = function(clustering_data, height) {
  agnes_results <- agnes(clustering_data, metric = "manhattan")
  num_clusters <- sum(agnes_results$height>height) + 1
  
  #plot(agnes_results, which.plots=2)
  
  print(sprintf("  Number of clusters is: %i", num_clusters))
  
  return(num_clusters)
}

# Takes a dataset consisting of individuals, generations, and test case errors, as well as a height cutoff for clustering and a normalization function, and returns a vector of numbers of clusters at each generation.
num_clusters_for_all_gens = function(data, height, normalization_fn){
  num_gens = max(data$generation)
  num_clusters <- sapply(seq(0, num_gens),
                         function(gen){
                           count_clusters(normalization_fn(extract_clustering_data(data, gen)),
                                          height)
                         }
  )
  
  return(num_clusters)
}

######################################################

# Takes a generation of error vectors and finds the percent of distinct error vectors
generation_error_diversity = function(gen_data){
  result = nrow(unique(gen_data)) / nrow(gen_data)
  print(sprintf("  Error Diversity is: %f", result))
  return(result)
}

error_diversity = function(data){
  num_gens = max(data$generation)
  error_divs <- sapply(seq(0, num_gens),
                       function(gen){
                         generation_error_diversity(extract_clustering_data(data, gen))
                       }
  )
  
  return(error_divs)
}

######################################################

make_frame_from_counts_and_div <- function (run_number, problem, treatment, 
                                            succeeded, height, normalization.fn,
                                            counts, error.div) {
  num_gens = length(counts)
  result = data.frame(run.num = rep(run_number, num_gens), 
                      problem = rep(problem, num_gens),
                      treatment = rep(treatment, num_gens),
                      succeeded = rep(succeeded, num_gens),
                      height = rep(height, num_gens),
                      normalization.function = rep(normalization.fn, num_gens),
                      generation = seq(0, num_gens-1), 
                      cluster.count = counts,
                      error.diversity = error.div)
  return(result)
}

make_frame_from_errors_file <- function(file_path, run_number, problem, treatment,
                                        height, normalization.fn){
  errors = read.csv(file_path)
 
  succeeded = min(errors$total.error) == 0
  
  cluster.counts = num_clusters_for_all_gens(errors, height, normalization.fn)
    
  div = error_diversity(errors)
  
  return(make_frame_from_counts_and_div(run_number, problem, treatment, succeeded, height,
                                        as.character(substitute(normalization.fn)),
                                        cluster.counts, div))
}
