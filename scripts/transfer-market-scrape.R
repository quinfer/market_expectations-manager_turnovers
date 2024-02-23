rm(list = ls())
library(worldfootballR)
library(tidyverse)
library(progress)
library(stringr)
# Create a list of League URLs of Interest ----

#To test the code I run with the top two English tiers. (In reality we want to loop it across an expanded list of the ilk commented below)
#league_links = list("https://www.transfermarkt.com/league-one/startseite/wettbewerb/GB1", "https://www.transfermarkt.com/league-one/startseite/wettbewerb/GB2")
#Here I have the top 4 tiers in England and the top two in Spain, Germany, France, Italy, Holland, Belgium, Portugal, Turkey, Greece and Scotland
league_links = c("https://www.transfermarkt.com/league-one/startseite/wettbewerb/GB1", 
                    "https://www.transfermarkt.com/league-one/startseite/wettbewerb/GB2", 
                    "https://www.transfermarkt.com/league-one/startseite/wettbewerb/GB3", 
                    "https://www.transfermarkt.com/league-one/startseite/wettbewerb/GB4", 
                    "https://www.transfermarkt.com/primera-division/startseite/wettbewerb/ES1", 
                    "https://www.transfermarkt.com/primera-division/startseite/wettbewerb/ES2", 
                    "https://www.transfermarkt.com/bundesliga/startseite/wettbewerb/L1", 
                    "https://www.transfermarkt.com/bundesliga/startseite/wettbewerb/L2", 
                    "https://www.transfermarkt.com/ligue-1/startseite/wettbewerb/FR1", 
                    "https://www.transfermarkt.com/ligue-1/startseite/wettbewerb/FR2", 
                    "https://www.transfermarkt.com/serie-a/startseite/wettbewerb/IT1",
                    "https://www.transfermarkt.com/serie-a/startseite/wettbewerb/IT2", 
                    "https://www.transfermarkt.com/super-lig/startseite/wettbewerb/TR1",
                    "https://www.transfermarkt.com/super-lig/startseite/wettbewerb/TR2", 
                    "https://www.transfermarkt.com/super-league-1/startseite/wettbewerb/GR1", 
                    "https://www.transfermarkt.com/super-league-1/startseite/wettbewerb/GR2", 
                    "https://www.transfermarkt.com/eredivisie/startseite/wettbewerb/NL1",
                    "https://www.transfermarkt.com/eredivisie/startseite/wettbewerb/NL2", 
                    "https://www.transfermarkt.com/jupiler-pro-league/startseite/wettbewerb/BE1",
                    "https://www.transfermarkt.com/jupiler-pro-league/startseite/wettbewerb/BE2", 
                    "https://www.transfermarkt.com/liga-portugal/startseite/wettbewerb/PO1", 
                    "https://www.transfermarkt.com/liga-portugal/startseite/wettbewerb/PO2", 
                    "https://www.transfermarkt.com/liga-portugal/startseite/wettbewerb/SC1",
                    "https://www.transfermarkt.com/liga-portugal/startseite/wettbewerb/SC2")

# Teams----

team_urls_grab <- function(x,years) {
  team_urls<-c()
  for(i in years) {
    pb$tick()
    cat(x,i,"\n")
    team_url <- tm_league_team_urls(start_year = i, league_url = x)
    team_urls<-append(team_urls,team_url)
  }  
  return(team_urls)
}
years=1999:2023
pb<-progress_bar$new(total=length(league_links)*length(years))
league_links %>% map(~team_urls_grab(.x,years)) -> team_urls
strsplit(team_urls[[1]],"/saison_id") %>% map_chr(~(.[1])) %>% unique()
#Keep only unique teams to avoid duplication of effort when we scrape manager data
strsplit(team_urls[[1]],"/saison_id") %>% map_chr(~(.[1])) %>% unique()
team_urls %>% map(~strsplit(.x,"/saison_id") %>% map_chr(~(.[1])) %>% unique()) %>% flatten_chr()->values
uniquevalues <- values[!duplicated(values)]
print(uniquevalues)

#Gather all club manager data for managers associated with the unique team list above
# tinker with this function to get it to work https://github.com/JaseZiv/worldfootballR/blob/main/R/tm_team_staff_history.R

tm_team_staff_history_bq <- function(team_urls, staff_role = "Manager") {
  
  main_url <- "https://www.transfermarkt.com"
  
  tm_staff_types <- read.csv("https://raw.githubusercontent.com/JaseZiv/worldfootballR_data/master/raw-data/transfermarkt_staff/tm_staff_types.csv", stringsAsFactors = F)
  
  if(!tolower(staff_role) %in% tolower(tm_staff_types$staff_type_text)) stop("Check that staff role exists...")
  
  tm_staff_idx <- tm_staff_types$staff_type_idx[tolower(tm_staff_types$staff_type_text) == tolower(staff_role)]
  
get_each_team_staff_history<- function(team_url) {
  pb$tick()
  manager_history_url <- gsub("startseite", "mitarbeiterhistorie", team_url) %>% gsub("saison_id.*", "", .) %>% paste0(., "personalie_id/", tm_staff_idx, "/plus/1")
  history_pg <- xml2::read_html(manager_history_url)
  team_name <- history_pg %>% rvest::html_nodes("h1") %>% rvest::html_text() %>% stringr::str_squish() %>% na_if('')
  league <- history_pg %>% rvest::html_nodes(".data-header__club a") %>% rvest::html_text() %>% stringr::str_squish() %>% na_if('')
  country <- history_pg %>% rvest::html_nodes(".data-header__content img") %>% rvest::html_attr("title") %>% na_if('')
  mgrs <- history_pg %>% rvest::html_nodes("#yw1") %>% rvest::html_nodes("tbody") %>% .[[1]] %>% rvest::html_children()

  mgr_df <-data.frame()
  
  for(each_row in 1:length(mgrs)) {
    mgr_df[each_row, "staff_name"] <- tryCatch(mgrs[each_row] %>% rvest::html_node(".hauptlink") %>% rvest::html_nodes("a") %>% rvest::html_text(),
                                               error = function(e)  mgr_df[each_row, "manager_name"] <- NA_character_)
    mgr_df[each_row, "staff_url"] <- tryCatch(mgrs[each_row] %>% rvest::html_node(".hauptlink") %>% rvest::html_nodes("a") %>% rvest::html_attr("href") %>% paste0(main_url, .),
                                              error = function(e) mgr_df[each_row, "manager_url"] <- NA_character_)
    mgr_df[each_row, "staff_dob"] <- tryCatch(mgrs[each_row] %>% rvest::html_node(".inline-table tr+ tr td") %>% rvest::html_text(),
                                              error = function(e) mgr_df[each_row, "dob"] <- NA_character_)
    mgr_df[each_row, "staff_nationality"] <- tryCatch(mgrs[each_row] %>% rvest::html_nodes(".zentriert .flaggenrahmen") %>% .[[1]] %>% rvest::html_attr("title"),
                                                      error = function(e) mgr_df[each_row, "staff_nationality"] <- NA_character_)
    mgr_df[each_row, "staff_nationality_secondary"] <- tryCatch(mgrs[each_row] %>% rvest::html_nodes(".zentriert .flaggenrahmen") %>% .[[2]] %>% rvest::html_attr("title"),
                                                                error = function(e) mgr_df[each_row, "staff_nationality_secondary"] <- NA_character_)
    mgr_df[each_row, "appointed"] <- tryCatch(mgrs[each_row] %>% rvest::html_nodes("td:nth-child(3)") %>% rvest::html_text(),
                                              error = function(e) mgr_df[each_row, "appointed"] <- NA_character_)
    mgr_df[each_row, "end_date"] <- tryCatch(mgrs[each_row] %>% rvest::html_nodes("td:nth-child(4)") %>% rvest::html_text(),
                                             error = function(e) mgr_df[each_row, "end_date"] <- NA_character_)
  mgr_df <- cbind(team_name, league, country, staff_role, mgr_df)
  return(mgr_df)
  }
}
  # create the progress bar with a progress function.
  pb <- progress::progress_bar$new(total = length(team_urls))
  
  f_possibly <- purrr::possibly(get_each_team_staff_history, otherwise = data.frame(), quiet = FALSE)
  purrr::map_dfr(
    team_urls,
    f_possibly
  )
  
}
club_manager_history<-tm_team_staff_history_bq(team_urls = uniquevalues)

#Display this club manager data as a dataframe
#This data is detailed enough that if we scraped it for most of the leagues of interest we could effectively follow a manager around using just the "appointed", "end_date" and "team_name"
as.data.frame(club_manager_history)

#Specifically Extract the Manager URL
club_manager_history %>% distinct(staff_url) %>%
  unlist(use.names = F) -> manager_urls
saveRDS(list(league_links=league_links,manager_urls=manager_urls,team_urls=uniquevalues),
        file = "data/transfermkt-links.rds")

#This function can be found here: https://github.com/JaseZiv/worldfootballR/blob/main/R/tm_staff_job_history.R



library(progress)
library(rvest)
extract_records<-function(staff_url) {
  pb$tick()
staff_url <- staff_url %>% gsub("profil", "stationen", .) %>% paste0(., "/plus/1")
staff_pg <- read_html(staff_url)
name <- staff_pg %>% html_nodes("h1") %>% html_text()
name  = gsub("[\r\n\t]", "", name)
current_club <- staff_pg %>% 
  html_nodes(".data-header__club a") %>% 
  html_text()
current_role <- staff_pg %>% 
  html_nodes(".data-header__label b") %>% 
  html_text() %>% 
  str_squish()
staff_hist <- staff_pg %>% 
  html_nodes("#yw1") %>% 
  html_nodes("tbody") %>% .[[1]] %>% 
  html_children()
club <- staff_hist %>% html_nodes(".no-border-links a") %>% html_text()
position <- staff_hist %>% html_nodes("td:nth-child(2)") %>% html_text()
appointed <- staff_hist %>% 
  html_nodes(".no-border-links+ .zentriert") %>% 
  html_text() %>%
  gsub(".*\\(", "", .) %>% gsub("\\)", "", .) %>% 
  str_squish()
contract_expiry <- staff_hist %>% html_nodes("td:nth-child(4)") %>% html_text() %>%
  gsub(".*\\(", "", .) %>% gsub("\\)", "", .) %>% stringr::str_squish() %>% 
  gsub("expected ", "", .) # This is the in charge until column
days_in_charge <- staff_hist %>% html_nodes("td:nth-child(5)") %>% html_text() %>% 
  gsub(" Days", "", .) %>% as.numeric()
matches <- staff_hist %>% html_nodes("td:nth-child(6)") %>% html_text() %>% 
  as.numeric() %>% suppressWarnings()
wins <- staff_hist %>% html_nodes("td:nth-child(7)") %>% html_text() %>% 
  as.numeric() %>% suppressWarnings()
draws <- staff_hist %>% html_nodes("td:nth-child(8)") %>% html_text() %>% 
  as.numeric() %>% suppressWarnings()
losses <- staff_hist %>% html_nodes("td:nth-child(9)") %>% 
  html_text() %>% as.numeric() %>% suppressWarnings()
players_used <- staff_hist %>% html_nodes("td:nth-child(10)") %>% html_text() %>% 
  as.numeric() %>% suppressWarnings()
goals <- staff_hist %>% html_nodes("td:nth-child(11)") %>% 
  html_text()
avg_goals_for <- gsub(":.*", "", goals) %>% stringr::str_squish() %>% as.numeric()
avg_goals_against <- gsub(".*:", "", goals) %>% stringr::str_squish() %>% as.numeric()
ppm <- staff_hist %>% html_nodes("td:nth-child(12)") %>% html_text() %>% 
  as.numeric() %>% suppressWarnings()
clean_role <- function(dirty_string, dirt) {
  gsub(dirt, "", dirty_string)
}
position = mapply(clean_role, dirty_string=position, dirt=club)
staff_df <- cbind(name, current_club, current_role, club, position, 
                  appointed, contract_expiry, days_in_charge, matches, 
                  wins, draws, losses, players_used, avg_goals_for, 
                  avg_goals_against, ppm)
message<-paste0("Name=",name," Current Club=",current_club,"Current Role=",current_role)
cat(message,sep = "\n" )
return(staff_df)
}

# extract_records_alt<-function(staff_url) {
#   pb$tick()
#   staff_url <- staff_url %>% gsub("profil", "stationen", .) %>% paste0(., "/plus/1")
#   staff_pg <- read_html(staff_url)
#   staff_pg |> html_table()
# }
pb<-progress_bar$new(total = length((manager_urls)))
manager_urls %>% map(possibly(extract_records,NULL)) -> spells
names(spells) <- club_manager_history %>% 
  distinct(staff_name)  %>% unlist(use.names = F)
spells %>% map_lgl(is.null) %>% which() -> the_nulls
spells %>% map(~as_tibble(.x)) %>% bind_rows() -> spells_df
library(lubridate)
mdy(spells_df$contract_expiry)

spells_df %>%
  mutate(Start=mdy(appointed),
         Finish=mdy(contract_expiry),
         matches=as.numeric(matches),
         days_in_charge=as.numeric(days_in_charge),
         wins=as.numeric(wins),
         draws=as.numeric(draws),
         losses=as.numeric(losses),
         players_used=as.numeric(players_used),
         avg_goals_for=as.numeric(avg_goals_for),
         avg_goals_against=as.numeric(avg_goals_against),
         ppm=as.numeric(ppm)) -> spells_df

# How many negative spells?----
spells_df %>% 
  arrange(name,club,Start,Finish) %>% 
  group_by(name,club) %>%
  mutate(days_btw_spells=Finish-Start) %>%
  filter(days_btw_spells<0) %>%
  select(name,current_club,days_btw_spells, appointed,contract_expiry,days_in_charge)
spells_df |>
arrange(name,club,Start,Finish) %>% 
  group_by(name,club) %>%
  mutate(days_btw_spells=Finish-Start,# This is wrong and needs changed
         Finish=if_else(days_btw_spells<0,Start+days_in_charge,Finish),
         days_btw_spells=Finish-Start) -> spells_df
saveRDS(spells_df,"data/transfermkt_managers_new.rds")
