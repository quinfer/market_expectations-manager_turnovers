library(dplyr)
library(purrr)
library(stringr)
spells <- read.csv("raw_data/manager_spells_from_manager_urls.csv")

# Define season_to_date() function here
season_to_date <- function(season) {
  if (is.na(season) | length(gsub("/", "", season)) == 0) {
    return(NA_real_)
  }
  
  parts <- strsplit(season, "/")[[1]]
  month <- as.numeric(parts[2])
  if (month < 8) {
    year <- paste0("20", substr(parts[1], 1, 2))
  } else {
    year <- paste0("19", substr(parts[1], 1, 2))
  }
  
  date_str <- paste0("01/08/", year)
  as.Date(paste(date_str, collapse = "/"), "%d/%m/%Y")
}

data_helper <- spells |>
  mutate(row_id=row_number()) |>
  filter(is.na(Finish)&contract_expiry!="-") |>
  select(contract_expiry, Finish,row_id)
data_helper$Finish<-as.Date(map_dbl(data_helper$contract_expiry, season_to_date))
spells |>
  mutate(row_id=row_number()) |>
  left_join(data_helper |> select(-Finish), by="row_id") |>
  mutate(Start = as.Date(Start),
         Finish = as.Date(Finish)) |>
  mutate(days_in_charge = as.numeric(Finish - Start)) ->spells
# find duplicates for name,club,Finish
#spells |> drop_na(Start,Finish) |> group_by(name,club,Finish) |> summarise(n=n()) |> filter(n>1) |> arrange(desc(n))
# remove duplicates
spells |> drop_na(Start,Finish) |> distinct(name,club,Finish,.keep_all = TRUE) |> filter(Finish-Start>0) -> spells
terms_to_remove <- c("1.FC Köln II","Al-Ahli (UAE)","Gimnasia (J)","San Martín (T)",
                     "San Martín (SJ)","Racing (Cba)","Juv. Unida (G)","1.FC Köln U19",
                     "1.FC Köln U17","1.FC Köln Yth.",
                     "1.FC Köln U16"," II","1.FC Köln","Bor. M'gladbach",
                     "Hertha BSC","F. Düsseldorf",
                     "Velez Mostar","SSV Reutlingen","FV Ravensburg",
                     "Fenerbahce","FC Teningen","FV Nimburg","Heart of Midl.",
                     "Vetra","Sp.Genzano (PZ)","Honvéd FC","Olympiacos","Honvéd SE","Hungary",
                     "ADO Den Haag(A)","Dordrecht'90","Haarlem","AZ Alkmaar","Roda JC","AZ '67",
                     "Sparta R.","De Treffers","NEC Nijmegen","FC Oss","VV Gemert","PSV U21")
spells %>%
  mutate(position = str_remove_all(position, paste0("(", paste(terms_to_remove, collapse = "|"), ")"))) -> spells
spells |> mutate(
  staff_position = trimws(tolower(position)),
  staff_position = ifelse(staff_position=="manager","manager",staff_position),
  staff_position = ifelse(staff_position=="assistant manager","assistant manager",staff_position),
  staff_position = ifelse(staff_position=="caretaker manager","caretaker manager",staff_position),
  staff_position = ifelse(str_detect(staff_position,"player-coach"),"player-coach",staff_position),
  staff_position = ifelse(str_detect(staff_position,"director of football"),"director of football",staff_position),
  staff_position = ifelse(str_detect(staff_position,"technical director"),"technical director",staff_position),
  staff_position = ifelse(str_detect(staff_position,"director of professional football"),"director of professional football",staff_position),
  staff_position = ifelse(str_detect(staff_position,"sporting director"),"sporting director",staff_position),
  staff_position = ifelse(str_detect(staff_position,"academy manager"),"academy manager",staff_position),
  staff_position = ifelse(str_detect(staff_position,"advisor"),"advisor",staff_position),
  staff_position = ifelse(str_detect(staff_position,"head of football operations"),"head of football operations",staff_position),
  staff_position = ifelse(str_detect(staff_position,"head of football operations"),"head of football operations",staff_position))-> spells

#spells |> distinct(club,Finish) |> select(club,Finish) |> rename("club_name"="club","end_of_spell"="Finish") |> write_csv("LLM-work/input.csv")

llm<-read.csv(file = "LLM-work/outputadj_parsed.csv")
spells |>
  mutate(mergevar=as.character(Finish)) |>
  left_join(llm, by=c("club"="club_name","mergevar"="end_of_spell")) |>
  select(-mergevar&-contract_expiry.x) |> 
  rename("contract_expiry"="contract_expiry.y") |>
  saveRDS("raw_data/manager_spells_from_manager_urls.rds")
