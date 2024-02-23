#### load data and software ####
DeleteList<-ls()
rm(list=DeleteList)
pacman::p_load(tidyverse,implied,lubridate,pracma,googledrive,plotly,install = F)
tf_records<-readRDS("data/transfermkt_managers_new.rds")
match_dat<-readRDS("data/matches_raw.rds") %>%
  mutate(Date=dmy(Date)) %>% 
  drop_na(Date)
index<-readRDS("data/master_name_match_df.rds")
index %>% 
  filter(duplicated(tm_name)|
           duplicated(tm_name,fromLast=T)|
           duplicated(fd_name)|
           duplicated(fd_name,fromLast=T)) -> duplicates
# preprocess  ---
# filtering the raw transfermkt records
tf_records %>%
  filter(position=="Manager") %>% # 1. filter on managers type 
  filter(Start>=first(match_dat$Date)) %>% # 2. filter to full odds record for spell
  filter(club %in% index$tm_name) %>% # 3. All clubs in index
  filter(!club %in% duplicates$tm_name) %>% # 4. remove clubs which are duplicated for tm_name
  filter(!club %in% duplicates$fd_name) %>% # 4. remove clubs which are duplicated for fd_name
  arrange(name,Start,Finish) %>%
  group_by(name) %>%
  mutate(spell_between_jobs=as.numeric(lead(Start)-Finish)) %>% 
  ungroup() %>%
  group_by(club,name) %>%
  mutate(spell_no_with_club=n()) %>%
  ungroup() %>%
  mutate(spell_between_jobs=if_else(spell_between_jobs>=-60 & spell_between_jobs<0,0,
                                    spell_between_jobs))-> tf_records
saveRDS(tf_records,"data/tf_records_raw.rds")
## Season ends per league and division
  match_dat %>%
  distinct(league,Div,Date) %>%
   group_by(league,Div) %>%
   mutate(days_between_games=as.numeric(Date-lag(Date))) %>%
   filter(days_between_games>60) %>%
   mutate(Year=year(Date)) %>%
   distinct(league,Div,Year,.keep_all = T) %>%
   rename(Season_Start=Date)-> Season_Ends
#### Season ####
 match_dat %>%
   mutate(Year=year(Date)) %>%
   left_join(Season_Ends, 
             by=c("league","Div","Year"))->match_dat
 match_dat %>% 
   ungroup() %>%
   mutate(Season=ifelse(Date<Season_Start,
                        paste0(year(Date)-1,"-",year(Date)),
                        paste0(year(Date),"-",year(Date)+1)))->match_dat
match_dat %>% {table(.$Season)}
match_dat %>% mutate(Season=if_else(is.na(Season) & Year==2000,"2000-2001",
                                    if_else(is.na(Season) & Year==2022,"2022-2023",Season)))->match_dat
#### merge index match to records #### 
#index %>% distinct(tm_name,.keep_all = T) %>% distinct(fd_name,.keep_all = T)->index1
index %>% filter(!tm_name %in% duplicates$tm_name) -> index1
tf_records %>% left_join(index,by = c("club"="tm_name"))->tf_records
saveRDS(tf_records,"data/tf_records_raw.rds")
tf_records<-readRDS("data/tf_records_raw.rds")
#### Sanity check for doubles ####
tf_records %>% 
  filter(is.na(fd_name)) %>% 
  arrange(club)  %>% 
  distinct(club,Start) %>%
  arrange(club,desc(Start))

### Sanity Check Management Teams ####
tf_records %>% 
  group_by(club,Start,name) %>%
  mutate(n=n()) %>%
  filter(n>1) %>%
  ungroup() %>%
  select(name,club,Start)
tf_records %>% distinct(name,club,Start,.keep_all = T)->tf_records
# saveRDS(manager_records_club_name_change,
#         file = "data/record_doubles.rds")
saveRDS(tf_records,file = "data/tf_records.rds")
saveRDS(tf_records,file = "~/R/football_app/data/tf_records.rds")
#### implied probabilities calculation ####
# match_dat %>% drop_na(HomeTeam)->match_dat
match_dat  %>%
  select(Div,Date,HomeTeam,AwayTeam,FTR,
                starts_with(c("B365","IW","GB","LB","SB",
                              "Avg","WH","SY","SO","BW",
                              "SJ","VC","BS","PS","GB")) &
                  ends_with(c("A","H","D"))) %>%
  select(!contains(c("AH","C")))->odds_HAD
## match data with home away and draw odds ##
odds_HAD %>%
  select(Div,Date,HomeTeam,AwayTeam,FTR,starts_with(c("IW","WH","B3","BW","LB"))) %>%
  pivot_longer(!Div&!Date&!HomeTeam&!AwayTeam&!FTR,names_to = c("Bookie","H|A|D"),
               names_sep =-1,values_to ="Odds") %>%
  mutate(Odds=as.numeric(Odds)) %>%
  drop_na() |>
  pivot_wider(names_from = "H|A|D",values_from = 'Odds') -> odds_HAD
odds_HAD %>% drop_na(H,D,A) %>%
  select(H,D,A) %>%
    filter(H>1 & D>1 & A>1)  %>%
  mutate(sum=1/H+1/D+1/A) %>%
  filter(sum>=1) %>%
  implied_probabilities(method = "shin")->shin_probs
save(shin_probs,odds_HAD,file = "data/shin_probs.RData")
load("data/shin_probs.RData")
shin_probs$probabilities %>% 
    as_tibble() %>% 
  transmute(Ex_pt_home=3*H+D,Ex_pt_away=3*A+D,
            Onesideness=abs(H-A),
            H_shin=H,D_shin=D,A_shin=A) %>% 
    bind_cols(
        odds_HAD %>%
        drop_na(H,D,A) %>%
        filter(H>1 & D>1 & A>1)  %>%
        mutate(sum=1/H+1/D+1/A) %>%
        filter(sum>=1))->relative_strength
  relative_strength %>% 
    mutate(RE_home=if_else(FTR=="H",3-Ex_pt_home,
                           if_else(FTR=="D",1-Ex_pt_home,-Ex_pt_home)),
           RE_away=if_else(FTR=="A",3-Ex_pt_away,
                           if_else(FTR=="D",1-Ex_pt_away,-Ex_pt_away)))->relative_strength

# RSI calculation aggregated to club data levels ####
relative_strength %>% 
  pivot_longer(cols = c(HomeTeam,AwayTeam),
               values_to = "Club",names_to = 'HorW') %>%
  mutate(RS=if_else(HorW=="HomeTeam",RE_home,RE_away),
         Ex_pts=if_else(HorW=="HomeTeam",Ex_pt_home,Ex_pt_away),
         RE_home=NULL,RE_away=NULL,Ex_pt_away=NULL,Ex_pt_home=NULL)->RS_long
RS_long |>
  group_by(Club,Date) %>%
  summarise(RS=mean(RS,na.rm=T),
            Ex_pts=mean(Ex_pts,na.rm=T),
            mean_sample_count=sum(!is.na(Bookie)),
            Div=first(Div),
            HomeWinImpliedProb=mean(H,na.rm=T),
            DrawImpliedProb=mean(D,na.rm=T),
            AwayWinImpliedProb=mean(D,na.rm=T),
            FTR=first(FTR),
            HorW=first(HorW)) %>%
  ungroup()->RS_long_club_date_sum
save(relative_strength,RS_long,file = "data/relative_strength.RData")
load("data/relative_strength.RData")
saveRDS(match_dat,"data/match_dat.rds")
#### match spells ####
matched_lists<-list()
for (i in 1:nrow(tf_records)) {
  tf_records %>% ungroup() %>% slice(i)->spell_manager
  cat(i,':',spell_manager$name," and ",spell_manager$club, "\n")
  RS_long %>%
    filter(Club==spell_manager$fd_name & 
             Date>=spell_manager$Start &
             Date<=spell_manager$Finish)->spell_club
  spell<-left_join(spell_club,spell_manager,
                   by=c("Club"="fd_name"))
  matched_lists[[i]]<-spell
}
df_anal<-bind_rows(matched_lists)
#### Sanity Check ####
df_anal %>% distinct(name,club,Start) %>% ungroup() %>% nrow()
print(tf_records %>% ungroup() %>% distinct(name,club,Start) %>% nrow())
# Which spells did not match?
tf_records %>% ungroup() %>%
  mutate(ID=paste(name,club,Start,sep = "-")) %>% 
  select(ID) %>% unlist(use.names = F)->master
df_raw %>% 
  mutate(ID=paste(name,club,Start,sep = "-")) %>% 
  distinct(ID) %>%
  unlist(use.names = F)->matched
df_raw %>% 
  mutate(ID=paste(name,club,Start,sep = "-")) %>% 
  filter((ID %in% master)) %>% 
  {unique(.$ID)}

#### RSI Calc per bookie ####
library(pracma)
df_anal %>%
  arrange(name,Club,Bookie,Date) %>%
  group_by(name,Club,Bookie) %>%
  mutate(games_in_charge=n(),
         RSI=cumsum(RS)/(3*n()),
         RSI_ma=ifelse(games_in_charge>5,
                      movavg(RS/3,5,type = "s"),NA)) %>% 
  ungroup() -> df_anal 
df_anal %>% distinct(name,Club,Date,.keep_all = T)-> df_match
# Win Ratio Calc ####
df_anal %>% 
  group_by(name,Club,Date) %>%
  summarise(sd_RSI=sd(RS,na.rm = T),
            no_of_bookies=sum(!is.na(Bookie)),
            RSI=mean(RSI,na.rm=T),
            RSI_ma=mean(RSI_ma,na.rm=T),
            Onesideness=mean(Onesideness,na.rm=T)) %>%
  ungroup() -> df_anal_calc
# Other predictors ####
df_match %>%
  arrange(name,Club,Date) %>%
  mutate(Win=if_else(HorW=="HomeTeam" & FTR=="H",1,0),
         Win=if_else(HorW=="AwayTeam" & FTR=="A",1,Win),
         Drawn=if_else(FTR=="D",1,0),
         Lost=1-Win) %>%
  group_by(name,Club) %>%
  mutate(games_in_charge=row_number(),
         Wins=cumsum(Win),
         Draws=cumsum(Drawn),
         Losses=cumsum(Lost),
         WinRatio=Wins/games_in_charge)->df_match
df_match %>% 
  arrange(name,Club,Date) %>% 
  group_by(name,Club) %>%
  mutate(grp_n=n(),grp_row=row_number()) %>%
  ungroup() %>%
  mutate(
    poach=if_else(spell_between_jobs<=10 & grp_n==grp_row,1,0),
    sack=if_else(spell_between_jobs>10 & grp_n==grp_row,1,0)) -> df_match
names(df_match)
df_match %>% select(!Onesideness&!RSI&!RSI_ma) %>%
  left_join(df_anal_calc, by=c('name','Club','Date')) -> df_match
saveRDS(df_anal, "data/rsi_for_all_bookies.rds")
saveRDS(df_match, "data/spells_with_rsi.rds")
saveRDS(df_match, "~/R/football_app/data/spells_with_rsi.rds")
