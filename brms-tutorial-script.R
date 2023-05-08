#===============================================================================
# Salvatore A. Sidoti, PhD, MA
# Kapili Services, LLC – Contractor
# Centers for Disease Control and Prevention (CDC)
# Division of Foodborne, Waterborne, and Environmental Diseases
# Surveillance, Information Management, and Statistics Office 
# urz2@cdc.gov | 614-558-0049
#===============================================================================

#~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~
# Bayesian Modelling Using the brms Package
#~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~

browseURL("https://ourcodingclub.github.io/tutorials/brms/")

# Set initial state of the pseudorandom number generator for reproducibility
set.seed(123)

# Set the working directory
setwd("your_filepath")

# If you are using "tidyverse' for the first time
# install.packages("tidyverse", dependencies = TRUE)

# Load initial packages
library(tidyverse)

# tidyverse read method
# France <- read_csv("red_knot.csv")

# native R read method
France <- read.csv("red_knot.csv",
                  header = TRUE,
                  na.strings = c("", "NA"), # fill blank cells with NA
                  stringsAsFactors = FALSE)

#===============================================================================
# Research Question: Has the red knot population in France increased over time?
#===============================================================================

(hist_france <- ggplot(France, aes(x = pop)) +
    geom_histogram(colour = "#8B5A00", fill = "#CD8500") +
    theme_bw() +
    ylab("Count\n") +
    xlab("\nCalidris canutus abundance") +  # latin name for red knot
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14, face = "plain")))

hist_france

# Which years were sampled?
unique(France$year) # returns unique the elements of a variable

# If you are using 'brms' for the first time
# install.packages("brms", dependencies = TRUE)

# Enable the brms package in the working environment
library(brms)

france1_mbrms <- brm(pop ~ I(year - 1975),
                     data = France,
                     family = poisson(),
                     chains = 3,
                     iter = 3000,
                     warmup = 1000)

# Save the model as an RDS (R Data Structure)
saveRDS(france1_mbrms,
        file = "france1_mbrms.RDS")

# NOTE: The aforementioned saves only the output summary table.
# To save ALL of the model parameters, including the posterior draws, use the
# save() with the file extension ".Rdata"
save(france1_mbrms,
     file = "france1_mbrms.Rdata")

# Show diagnostic plots to assess model fit
plot(france1_mbrms)

# Assess the strength of the model's predictability
# a.k.a. "posterior predictive check"
pp_check(france1_mbrms)

#===============================================================================
# Adding Random Effects
#===============================================================================

france2_mbrms <- brm(pop ~ I(year - 1975) + (1|year),
                     data = France,
                     family = poisson(),
                     chains = 3,
                     iter = 3000,
                     warmup = 1000)

# NOTE: This model "ran", but it threw a warning due to:
# 1) tree depth too shallow
# 3) insufficient number of samples

# Save faulty model for testing purposes
save(france2_mbrms,
     file = "france2_mbrms.Rdata")

#===============================================================================
# Diagnose potential issues in the sampling process
#===============================================================================

# Show diagnostic plots to assess model fit
plot(france2_mbrms)

# Check for high autocorrelation
# High autocorrelation in the MCMC samples can result in low ESS
# Use mcmc_acf() from 'bayesplot' package to visualize autocorrelation

# If you are using 'bayesplot' for the first time:
# install.packages("bayesplot", dependencies = TRUE)
library(bayesplot)

mcmc_acf(france2_mbrms,
         # Specify which model parameters to plot
         "b_Intercept",
         "b_IyearM1975")

# Compare with previous model
mcmc_acf(france1_mbrms,
         # Specify which model parameters to plot
         "b_Intercept",
         "b_IyearM1975")

# Assess the strength of the model's predictability
# a.k.a. "posterior predictive check"
pp_check(france2_mbrms)

# Compare with previous model
pp_check(france1_mbrms)

# Revised model:

france3_mbrms <- brm(pop ~ I(year - 1975) + (1|year),
                     data = France,
                     family = poisson(),
                     chains = 3,
                     iter = 6000, # doubled the number of iterations from prevous model
                     warmup = 1000,
                     control = list(max_treedepth = 15)) # max_treedepth = 10 is STAN default

summary(france3_mbrms)

plot(france3_mbrms)

# No errors, but the chains look a bit too serpentine
# Additional tweaking of the model is needed
# Some first steps:
# Increase number of iterations
# Thinning

# Save model
save(france3_mbrms,
     file = "france3_mbrms.Rdata")

#===============================================================================
# Adding multiple fixed effects
#===============================================================================

unique(France$Location.of.population)

(boxplot_location <- ggplot(France, aes(Location.of.population, pop)) +
    geom_boxplot() +  # could be a significant effect between locations so should look at that
    theme_bw() +
    xlab("Location\n") +
    ylab("\nCalidris canutus abundance") +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14, face = "plain")))

france4_mbrms <- brm(pop ~ I(year - 1975) + Location.of.population,
                     data = France,
                     family = poisson(),
                     chains = 3,
                     iter = 3000,
                     warmup = 1000)

summary(france4_mbrms)

plot(france4_mbrms)

# Save all models under one file
save(france1_mbrms,
     france2_mbrms,
     france3_mbrms,
     france4_mbrms,
     file = "france_brms_models.Rdata")
