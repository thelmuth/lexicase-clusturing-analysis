
library('cluster')
library("plyr")

#setwd("~/Documents/R/Clustering/lexicase-clusturing-analysis")

#####################################################################
## Functions for working with data files
#####################################################################

# Transforms a data.csv file from Clojush into an errors-only file that is smaller.
transform_data_file_into_error_file <- function(file_path){
  data <- read.csv(file_path)

  columns_to_drop = c("parent.uuids", "genetic.operators", "push.program.size", "plush.genome.size", "push.program", "plush.genome")
  
  data = data[,!(names(data) %in% columns_to_drop)]
  
  write_path = paste(dirname(file_path), "/", "errors_", basename(file_path), sep="")
  
  write.csv(data, write_path, row.names = FALSE)
}

# Takes a directory path that contains error_clustering_and_div CSVs and combines them into a new data frame
import_from_error_clustering_and_div <- function(dir_path){
  file_list = list.files(path=dir_path, pattern="*.csv")
  separated_data = lapply(paste(dir_path, file_list, sep=""), read.csv)
  data = do.call(rbind, separated_data)
  return(data)
}

#####################################################################
## Functions for data frames
#####################################################################

# Makes a data frame for a set of runs based on a number of inputs
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

# Makes a data frame for a set of runs based on an errors file
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

#####################################################################
## Functions for clustering data
#####################################################################

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

#####################################################################
## Functions for finding error diversity
#####################################################################

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

#####################################################################
## Functions for finding success rates
#####################################################################

# Finds the number of successes up to each generation for a particular treatment and maximum generations; It is expected that the data only contains 
get_successes_up_to_each_generation_treatment <- function(data, treat, max_gen){
  success_gens = subset(data, generation == 0 & treatment == treat)$success.generation
  
  successes_before_or_at_each_gen = sapply(seq(0, max_gen),
                                           function(gen) sum(success_gens <= gen, na.rm = TRUE))
  
  result = data.frame(generation = seq(0, max_gen),
                      treatment = rep(treat, max_gen + 1),
                      num.successes = successes_before_or_at_each_gen)
  
  return(result)
}

# Find the number of successes up to each generation for each treatment in data
get_generational_success_counts <- function(data){
  max_gen = max(data$generation)
  treatments = levels(data$treatment)
  
  result = ldply(treatments,
                 function(treat) get_successes_up_to_each_generation_treatment(data,
                                                                               treat,
                                                                               max_gen))
  
  return(result)
}

#####################################################################
## Functions for making plots
#####################################################################

# Plots the diversity, faceted by treatment and success
plot_all_diversity_lines_faceted <- function(data) {
  p <- ggplot(data, aes(x=generation, y=error.diversity, group=run.num)) +
    geom_line(alpha=0.25) +
    facet_grid(succeeded ~ treatment, labeller=label_both) +
    ylim(c(0,1)) +
    theme_bw()
  return(p)
}

# Plots the numbers of clusters, faceted by treatment and success
plot_all_clusters_lines_faceted <- function(data) {
  max_clusters = max(data$cluster.count)
  p <- ggplot(data, aes(x=generation, y=cluster.count, group=run.num)) +
    geom_line(alpha=0.25) +
    facet_grid(succeeded ~ treatment, labeller=label_both) +
    ylim(c(0,max_clusters+1)) +
    theme_bw()
  return(p)
}

# Plots diversity medians and quartiles of data. Takes optional quartiles_percent, which tells what percent of the center data to include
plot_diversity_medians_and_quartiles <- function(data, quartiles_percent = 0.5){
  p <- ggplot(data, aes(x=generation, y=error.diversity, color=treatment)) + 
    stat_summary(fun.data="median_hilow", conf.int=quartiles_percent, alpha=0.5) +
    theme_bw() +
    ylim(c(0,1))
  return(p)
}

# Plots clusters medians and quartiles of data. Takes optional quartiles_percent, which tells what percent of the center data to include
plot_cluster_count_medians_and_quartiles <- function(data, quartiles_percent = 0.5){            
#   treatments = levels(data$treatment)  
#   max_clusters = 1 + max(sapply(treatments, function(treat) {
#     hilow = smedian.hilow(subset(data, treatment == treat)$cluster.count, conf.int=quartiles_percent)
#     return(hilow["Upper"])
#   }))

  p <- ggplot(data, aes(x=generation, y=cluster.count, color=treatment)) + 
    stat_summary(fun.data="median_hilow", conf.int=quartiles_percent, alpha=0.5) +
    theme_bw()
  return(p)
}

# Makes a plot giving the number of successes at or before each generation
plot_generational_success_counts <- function(data){
  success_counts = get_generational_success_counts(data)
  
  first_treatment = levels(data$treatment)[1]
  num_runs_per_treatment = nrow(subset(data, treatment==first_treatment & generation == 0))
  
  p <- ggplot(success_counts, aes(x=generation, y=num.successes, color=treatment)) +
    geom_line(size=1) +
    ylim(c(0, num_runs_per_treatment)) +
    theme_bw()
  
  return(p)
}

# Add a number of successes plot below the given plot for the given data
add_generational_success_counts_plot <- function(data, other_plot){
  success_plot = plot_generational_success_counts(data)
  op = other_plot + theme(axis.title.x=element_blank(),
                          axis.ticks.x=element_blank(),
                          axis.text.x=element_blank())
  result = grid.arrange(arrangeGrob(op, success_plot, heights=c(3/4, 1/4), ncol=1))
  return(result)
}
