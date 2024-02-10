rm(list=ls())
library(brms)
library(tidyverse)
library(rstan)
library(cmdstanr)
library(survival)
library (coda)
library (bayesplot)
library (shinystan)
library (tidybayes)

## recommended by tidybayes vignette
library (magrittr)
library (dplyr)
library (purrr)
library (forcats)
library (tidyr)
library (modelr)
library (ggplot2)
library (ggstance)
library (cowplot)
library (rstan)
library (ggrepel)
library (RColorBrewer)
library (gganimate)

theme_set(theme_tidybayes() + panel_border())

read_csv("./data/df_anal.csv")->dfanal

rstan_options(auto_write=TRUE)
options(mc.cores=parallel::detectCores ()) # Run on multiple cores
set_cmdstan_path(path="/home/barry/.cmdstan/cmdstan-2.33.1")
dfanal |> drop_na(event,Standardized_CumRS,Pct_of_Possible_Points_Won,Div,`Domestic Games in Charge`)
table(dfanal$country)
  

dfanal$games_to_event<-dfanal$`Domestic Games in Charge`
Sys.time ()
mgrs.indiv.brm.test <- brm ((games_to_event) | cens (poach) ~ 1 + Standardized_CumRS
                            + Pct_of_Possible_Points_Won +                                                                                                                
                              (1 | Div ) + (-1 + Pct_of_Possible_Points_Won|Div) + (-1 +  Standardized_CumRS|Div),
                            dfanal, family= weibull (),backend = "cmdstan", warmup= 5, iter= 10, seed= 5781)
Sys.time()
mgrs.indiv.brm <- brm ((games_to_event) | cens (poach) ~ - 1 + Standardized_CumRS
                            + Pct_of_Possible_Points_Won +
                              (1 | country ) + (-1 + Pct_of_Possible_Points_Won|country) + 
                         (-1 +  Standardized_CumRS|country),
                            dfanal, family= weibull (), warmup= 500,iter = 2000, seed= 5781)
Sys.time()

Sys.time()
mgrs.indiv.brm.sack.div <- brm ((games_to_event) | cens (sack) ~ - 1 + 
                                  Standardized_CumRS
                       + Pct_of_Possible_Points_Won +
                         (1 | Div ) + (-1 + Pct_of_Possible_Points_Won|Div) + 
                         (-1 +  Standardized_CumRS|Div),
                       dfanal, family= weibull (), warmup= 500,iter = 2000, seed= 5781)
Sys.time()
start=Sys.time()
mgrs.indiv.brm.poach.cty <- brm ((games_to_event) | cens (poach) ~ - 1 + 
                                   Standardized_CumRS
                                 + Pct_of_Possible_Points_Won +
                                   (1 | country ) + (-1 + Pct_of_Possible_Points_Won|country) + 
                                   (-1 +  Standardized_CumRS|country),
                                dfanal, family= weibull(),backend = "cmdstan", 
                                warmup= 500,iter = 3000, seed= 5781)
saveRDS(mgrs.indiv.brm.poach.cty,"./model/grp_lvl_poach_cty.rds")
end=Sys.time()
print(end-start)

Sys.time()

## Cursory checks
summary (mgrs.indiv.brm.poach.div)
plot(mgrs.indiv.brm)
get_variables(mgrs.indiv.brm)


ranef(mgrs.indiv.brm,groups = "country",probs = c(0.05,0.95))
fixef(mgrs.indiv.brm,groups = "country",probs = c(0.05,0.95))

mgrs.indiv.brm.sack %>%
  spread_draws(r_country[country,Coeff]) |>
  ggplot(aes(x=country,y=r_country)) +
  stat_halfeye(.width = .5,size=2/3,fill = "#859900") +
  facet_wrap(~Coeff)

  # plot
  ggplot(aes(x = mu, y = reorder(site, mu))) +
  geom_vline(xintercept = fixef(k_fit_brms)[1, 1], color = "#839496", size = 1) +
  geom_vline(xintercept = fixef(k_fit_brms)[1, 3:4], color = "#839496", linetype = 2) +
  geom_halfeyeh(.width = .5, size = 2/3, fill = "#859900") +
  labs(x = expression("Cottonwood litterfall (g/m^2)"),
       y = "BEMP sites ordered by mean predicted litterfall") +
  theme(panel.grid   = element_blank(),
        axis.ticks.y = element_blank(),
        axis.text.y  = element_text(hjust = 0),
        text = element_text(family = "Ubuntu"))
## plot between versus within subject variability for transitions
######################################################################################################

hens.indiv.brm %>%
  spread_draws (# within subj
    sd_henDate__type.trans12,
    sd_henDate__type.trans21,
    sd_henDate__type.trans23,
    sd_henDate__type.trans32,
    sd_henDate__type.trans34,
    sd_henDate__type.trans42,
    sd_henDate__type.trans43,
    sd_henDate__type.trans45,
    sd_henDate__type.trans52,
    sd_henDate__type.trans53,
    sd_henDate__type.trans54,
    # between subject
    sd_henID__type.trans12,
    sd_henID__type.trans21,
    sd_henID__type.trans23,
    sd_henID__type.trans32,
    sd_henID__type.trans34,
    sd_henID__type.trans42,
    sd_henID__type.trans43,
    sd_henID__type.trans45,
    sd_henID__type.trans52,
    sd_henID__type.trans53,
    sd_henID__type.trans54
  ) %>%
  mutate (bw12= (sd_henID__type.trans12)^2 / (sd_henDate__type.trans12)^2) %>%
  mutate (bw21= (sd_henID__type.trans21)^2 / (sd_henDate__type.trans21)^2) %>%
  mutate (bw23= (sd_henID__type.trans23)^2 / (sd_henDate__type.trans23)^2) %>%
  mutate (bw32= (sd_henID__type.trans32)^2 / (sd_henDate__type.trans32)^2) %>%
  mutate (bw34= (sd_henID__type.trans34)^2 / (sd_henDate__type.trans34)^2) %>%
  mutate (bw42= (sd_henID__type.trans42)^2 / (sd_henDate__type.trans42)^2) %>%
  mutate (bw43= (sd_henID__type.trans43)^2 / (sd_henDate__type.trans43)^2) %>%
  mutate (bw45= (sd_henID__type.trans45)^2 / (sd_henDate__type.trans45)^2) %>%
  mutate (bw52= (sd_henID__type.trans52)^2 / (sd_henDate__type.trans52)^2) %>%
  mutate (bw53= (sd_henID__type.trans53)^2 / (sd_henDate__type.trans53)^2) %>%
  mutate (bw54= (sd_henID__type.trans54)^2 / (sd_henDate__type.trans54)^2) %>%
  select (.chain:.draw, contains ('bw')) %>%
  filter (.chain > 2) %>% ## use only chains that have converged
  gather ('tt', 'bw', 4:14) %>%
  group_by (tt) %>%
  ggplot (aes (y= tt, x= bw)) +
  xlab ('Ratio of between / within subject variance') +
  ylab ('Types of transitions') +
  scale_y_discrete(breaks= c ('bw12', 'bw21', 'bw23', 'bw32', 'bw34', 'bw42', 'bw43', 'bw45', 'bw52', 'bw53', 'bw54'),
                   labels= c ('12', '21', '23', '32', '34', '42', '43', '45', '52', '53', '54'))  +
  stat_intervalh (.width= c (.50, .75, .95, .99)) +
  scale_color_brewer () +
  stat_summary (fun= median, geom= 'point', shape= 20, size= 3, color= 'darkblue', fill= 'darkblue') +
  geom_vline (xintercept= 0:1)

ggsave ('bw_hens.eps', width= 12, height= 6, units= 'cm', dpi= 320)
ggsave ('bw_hens.jpg', width= 12, height= 6, units= 'cm', dpi= 320)
