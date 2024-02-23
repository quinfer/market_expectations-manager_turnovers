rm(list=ls())
library(brms)
library(tidyverse)
library(rstan)
library(survival)
library (tidybayes)
library(readr)
read_csv("dat_part1.csv") |>
  bind_rows(read_csv("dat_part2.csv")) -> dfanal
rstan_options(auto_write=TRUE)
options(mc.cores=parallel::detectCores ()) # Run on multiple cores
#set_cmdstan_path(path="/home/barry/.cmdstan/cmdstan-2.33.1")
dfanal |> drop_na(event,Standardized_CumRS,Pct_of_Possible_Points_Won,Div,`Domestic Games in Charge`)
dfanal$games_to_event<-dfanal$`Domestic Games in Charge`
# Sys.time ()
# mgrs.indiv.brm.test <- brm ((games_to_event) | cens (poach) ~ 1 + Standardized_CumRS
#                             + Pct_of_Possible_Points_Won +                                                                                                                
#                               (1 | Div ) + (-1 + Pct_of_Possible_Points_Won|Div) + (-1 +  Standardized_CumRS|Div),
#                             dfanal, family= weibull (),backend = "cmdstan", warmup= 5, iter= 10, seed= 5781)
# Sys.time()

model <- brm((games_to_event) | cens (poach) ~ 1 + Standardized_CumRS + Pct_of_Possible_Points_Won
             ,warmup = 1000,iter = 5000,data = dfanal)
