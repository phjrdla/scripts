library(dplyr)
library(lubridate)
library(ggplot2)
library(ggfortify)
library(reshape2)


# Load cvs files
sysmetrics = NULL
list.files('./dataPROD')
getwd()
setwd('./dataPROD')
for ( f in list.files() ) {
  if (  ! is.null(sysmetrics) ) {
      sysmetrics2append <- read.csv(f, header=T, stringsAsFactors = F)
      sysmetrics <- rbind(sysmetrics,sysmetrics2append)
      dim(sysmetrics)
  } else {
      print('first cvs iz loaded')
      sysmetrics <- read.csv(f, header=T, stringsAsFactors = F)
  }
}
setwd('..')
dim(sysmetrics)
head(sysmetrics)
names(sysmetrics)
summary(sysmetrics)

# convert begintime to time

df <- sysmetrics %>% mutate( BEGINTIME = ymd_hms(BEGINTIME) )
names(df);

#dfMelted <- melt( df[, c("beginTime","hostcpupct","dbcputimratio","LOAD","avgactsess" )], id="beginTime")
#dfMelted <- melt( df[, c("BEGINTIME","HOSTCUPCT", "DBCPUTIMRATIO", "AVGACTSESS","LOAD","RESPTPTXN"  )], id="BEGINTIME")
#dfMelted <- melt( df[, c("BEGINTIME","LOAD","RESPTPTXN"  )], id="BEGINTIME")

dfMelted <- melt( df[, c("BEGINTIME","HOSTCUPCT", "SESSCNT","LOAD" ,"DBCPUTIMRATIO" )], id="BEGINTIME")
#dfMelted <- melt( df[, c("BEGINTIME","HOSTCUPCT", "LOAD" ,"DBCPUTIMRATIO" )], id="BEGINTIME")

#dfMelted <- melt(df[,c("BEGINTIME","HOSTCUPSEC","HOSTCUPCT","CUPSEC","DBCPUTIMRATIO","LOAD","EXECPSEC","EXECPTXN","RESPTPTXN","SQLRESPT","USERCALLSPSEC","USERCALLSPTXN","USERTXNPSEC","ENQRPTXN","PARSEPTXN")], id="BEGINTIME")
names(dfMelted)
head(dfMelted)
dfMelted

ggplot(dfMelted) + geom_line(aes(x=BEGINTIME, y=value, color=variable)) + labs(title="Metrics") 

names(sysmetrics)
summary(sysmetrics)
sysmetrics[1-5,"begin_time"]
