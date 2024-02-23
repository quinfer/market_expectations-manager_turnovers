MyDeleteItems<-ls()
rm(list=MyDeleteItems)
library(tidyverse)
library(rio)

# Import data from Seasons 2000-2001 to  2019-2020 from http://www.football-data.co.uk

seasons<-c("0001","0102","0203","0304","0405",
           "0506","0607","0708","0809","0910",
           "1011","1112","1213","1314","1415",
           "1516","1617","1718","1819","1920",
           "2021","2122","2223")

leagues<-c("England","Scotland","Germany","Italy","Spain","France",
           "Netherlands","Belgium","Portugal","Turkey","Greece")

euro_matches<-vector("list",length =length(leagues) )
names(euro_matches)<-leagues
dlist<-list()
i=0
for (s in seasons) {
  for (l in c("E0","E1","E2","E3")) {
    i=i+1
    url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/",l,".csv")
    df<-read_csv(url)
    df %>% map_df(as.character)->df
    dlist[[i]]<-df
  }
}
euro_matches[['England']]<-bind_rows(dlist)

dlist<-list()
i=0
for (s in seasons) {
  for (l in c("SC0","SC1","SC2","SC3")) {
    i=i+1
    url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/",l,".csv")
    df<-read_csv(url)
    df %>% map_df(as.character)->df
    dlist[[i]]<-df
  }
}
euro_matches[['Scotland']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
  for (l in c("D1","D2")) {
    i=i+1
    url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/",l,".csv")
    df<-read_csv(url)
    df %>% map_df(as.character)->df
    dlist[[i]]<-df
  }
}
euro_matches[['Germany']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
  for (l in c("I1","I2")) {
    i=i+1
    url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/",l,".csv")
    df<-read_csv(url)
    df %>% map_df(as.character)->df
    dlist[[i]]<-df
  }
}
euro_matches[['Italy']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
  for (l in c("SP1","SP2")) {
    i=i+1
    url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/",l,".csv")
    df<-read_csv(url)
    df %>% map_df(as.character)->df
    dlist[[i]]<-df
  }
}
euro_matches[['Spain']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
  for (l in c("F1","F2")) {
    i=i+1
    url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/",l,".csv")
    df<-read_csv(url)
    df %>% map_df(as.character)->df
    dlist[[i]]<-df
  }
}
euro_matches[['France']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
    i=i+1
    url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/","N1",".csv")
    df<-read_csv(url)
    df %>% map_df(as.character)->df
    dlist[[i]]<-df
}
euro_matches[['Netherlands']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
  i=i+1
  url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/","P1",".csv")
  df<-read_csv(url)
  df %>% map_df(as.character)->df
  dlist[[i]]<-df
}
euro_matches[['Portugal']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
  i=i+1
  url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/","T1",".csv")
  df<-read_csv(url)
  df %>% map_df(as.character)->df
  dlist[[i]]<-df
}
euro_matches[['Turkey']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
  i=i+1
  url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/","G1",".csv")
  df<-read_csv(url)
  df %>% map_df(as.character)->df
  dlist[[i]]<-df
}
euro_matches[['Greece']]<-bind_rows(dlist)
dlist<-list()
i=0
for (s in seasons) {
  i=i+1
  url<-paste0('https://www.football-data.co.uk/mmz4281/',s,"/","B1",".csv")
  df<-read_csv(url)
  df %>% map_df(as.character)->df
  dlist[[i]]<-df
}
euro_matches[['Belgium']]<-bind_rows(dlist)

euro_matches %>%
  bind_rows(.id="league")->dat
# write data to csv with file encoding UTF-8
write.csv(dat,"data/euro_matches.csv",row.names = FALSE,fileEncoding = "UTF-8")