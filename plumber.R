con <- url("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list", "rb") 
lego_movie <- read_html(con)

# plumber.R
#* @apiTitle BMS Jobs
#* @apiDescription API related to BMS_jobs operations

#* @preempt __first__
#* @get /
function(req, res) {
  res$status <- 302
  res$setHeader("Location", "./__docs__/")
  res$body <- "Redirecting..."
  res
}

#* @tag "Duplicated jobs"
#* Send slack message with duplicated jobs
#* @post /BMS_duplicated_jobs_slack
function() {
    required(slackr)
    
    slackr_setup(config_file = "C:/Users/vbinimelis/OneDrive - Hotelbeds Technology/Documents/Learning_R/BMS_jobs_plumber/slack_config")
    
    ##agafam el JSON de la URL i el convertim en dataframe
    URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
    jobs_data_frame <- as.data.frame(URL_jobs)
    
    ##accedim al segon nivell de JSON/dataframe
    jobs_data_frame <- do.call(data.frame, jobs_data_frame)
    
    ##eliminam els jobs de disney
    jobs_data_frame<-subset(jobs_data_frame, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB" & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
    
    
    ##convertir la columna del nom del CM en llista
    jobs_data_frame<-jobs_data_frame$jobInfos.properties.CM
    
    ##cercam els duplicats
    posicio<-which(duplicated(jobs_data_frame))
    
    ##contam els duplicats
    numb<-length(posicio)
    
    
    ##identificam el value dels duplicats
    jobs_data_frame[posicio]
    
    
    ##creame missatges i els enviam per slack
    my_message1 <- paste("There are", numb, "jobs duplicated")
    
    my_message2 <- paste (jobs_data_frame[posicio])
    
    
    slackr_msg(my_message1, channel ="#jobs_bms")
    slackr_msg(my_message2, channel ="#jobs_bms")
  
}


#* @tag "Duplicated jobs"
#* Send email with duplicated jobs
#* @post /BMS_duplicated_jobs_email
function() {
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
  jobs_data_frame <- as.data.frame(URL_jobs)
  
  ##accedim al segon nivell de JSON/dataframe
  jobs_data_frame <- do.call(data.frame, jobs_data_frame)
  
  ##eliminam els jobs de disney
  jobs_data_frame<-subset(jobs_data_frame, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB" & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
  
  
  ##convertir la columna del nom del CM en llista
  jobs_data_frame<-jobs_data_frame$jobInfos.properties.CM
  
  ##cercam els duplicats
  posicio<-which(duplicated(jobs_data_frame))
  
  ##contam els duplicats
  numb<-length(posicio)
  
  
  ##identificam el value dels duplicats
  jobs_data_frame[posicio]
  yourvector <- unlist(jobs_data_frame[posicio])
  vector<-paste(yourvector,collapse="\n")
  
  
  ##crear cos del correu
  blankLine<-(" ")
  body1<-("Good morning all,")
  body2<-paste("Today we have ", numb, " jobs duplicated. We’ll delete them now.")
  body3<-("Please find below the list of affected jobs: ")
  body4<-("Best regards,")
  body5<-("HotelConnect Technical")
  
  email_body<-paste(body1, blankLine, body2, body3, blankLine, vector, blankLine, body4, body5, sep="\n")

  
  
  ###ENVIAR EMAIL
  # Load the DCOM library
  library (RDCOMClient)
  
  # Open Outlook
  Outlook <- COMCreate("Outlook.Application")
  
  # Create a new message
  Email = Outlook$CreateItem(0)
  
  # Set the recipient, subject, and body
  Email[["SentOnBehalfOfName"]] = "hotelconnect-technical@hotelbeds.com"
  Email[["to"]] = "vbinimelis@hotelbeds.com"
  Email[["cc"]] = ""
  Email[["bcc"]] = ""
  Email[["subject"]] = "Duplicated JOBS"
  Email[["body"]] = 
    email_body
  
  # Send the message
  Email$Send()
  
  # Close Outlook, clear the message
  rm(Outlook, Email)
}

#* @tag "Charts by parameter"
#* Generate a chart with GVCC parameter
#* @get /BMS_jobs_GVCC
#* @serializer contentType list(type='image/png')
function() {
  require(jsonlite)
  require(ggplot2)
  require(dplyr)
  require(curl)
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
  jobs_data_frame <- as.data.frame(URL_jobs)
  
  ##accedim al segon nivell de JSON/dataframe
  jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
  
  ##eliminam els jobs de disney
  jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                            & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
  
  
  ##convertim els NA en FALSE
  jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
  
  #GVCC
  GVCC<-ggplot(jobs_data_frame_3, aes(x = factor (jobInfos.properties.GVCC)))+
    geom_bar(fill = "#3995e6", width = 0.5)+
    labs(x = "",y = "Count")+
    geom_text(aes(label = ..count..), stat = "count", vjust =-0.25, colour = "black", position=position_dodge(width=0.9))+
    ggtitle("GVCC")
  
  GVCC + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
               panel.background = element_blank(), axis.line = element_line(colour = "black"), plot.title = element_text(size=14, face="bold", hjust = 0.5)) + coord_cartesian(ylim = c(10, 200))

  
  
  file <- "plot.png"
  ggsave(file, GVCC)
  readBin(file, "raw", n = file.info(file)$size)

}

#* @tag "Charts by parameter"
#* Generate a chart with CBD parameter
#* @get /BMS_jobs_CBD
#* @serializer contentType list(type='image/png')
function() {
  require(jsonlite)
  require(ggplot2)
  require(dplyr)
  require(curl)
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
  jobs_data_frame <- as.data.frame(URL_jobs)
  
  ##accedim al segon nivell de JSON/dataframe
  jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
  
  ##eliminam els jobs de disney
  jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                            & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
  
  
  ##convertim els NA en FALSE
  jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
  #CBD
  CBD<-ggplot(jobs_data_frame_3, aes(x = factor (jobInfos.properties.Breakdown)))+
    geom_bar(fill = "#3995e6", width = 0.5)+
    labs(x = "",y = "Count")+
    geom_text(aes(label = ..count..), stat = "count", vjust =-0.25, colour = "black", position=position_dodge(width=0.9))+
    ggtitle("CBD")
  
  CBD + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
              panel.background = element_blank(), axis.line = element_line(colour = "black"), plot.title = element_text(size=14, face="bold", hjust = 0.5)) + coord_cartesian(ylim = c(10, 200))
  
  file <- "plot.png"
  ggsave(file, CBD)
  readBin(file, "raw", n = file.info(file)$size)
}

#* @tag "Charts by parameter"
#* Generate a chart with isFinalStatus parameter
#* @get /BMS_jobs_isFinalStatus
#* @serializer contentType list(type='image/png')
function() {
  require(jsonlite)
  require(ggplot2)
  require(dplyr)
  require(curl)
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
  jobs_data_frame <- as.data.frame(URL_jobs)
  
  ##accedim al segon nivell de JSON/dataframe
  jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
  
  ##eliminam els jobs de disney
  jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                            & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
  
  
  ##convertim els NA en FALSE
  jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
  ##isFinalStatus
  isFinalStatus<-ggplot(jobs_data_frame_3, aes(x = factor (jobInfos.properties.isFinalStatus)))+
    geom_bar(fill = "#3995e6", width = 0.5)+
    labs(x = "",y = "Count")+
    geom_text(aes(label = ..count..), stat = "count", vjust =-0.25, colour = "black", position=position_dodge(width=0.9))+
    ggtitle("isFinalStatus")
  
  isFinalStatus + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                        panel.background = element_blank(), axis.line = element_line(colour = "black"), plot.title = element_text(size=14, face="bold", hjust = 0.5)) + coord_cartesian(ylim = c(10, 200))
  
  file <- "plot.png"
  ggsave(file, isFinalStatus)
  readBin(file, "raw", n = file.info(file)$size)
}

#* @tag "Charts by parameter"
#* Generate a chart with holderNameAllPax parameter
#* @get /BMS_jobs_holderNameAllPax
#* @serializer contentType list(type='image/png')
function() {
  require(jsonlite)
  require(ggplot2)
  require(dplyr)
  require(curl)
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
  jobs_data_frame <- as.data.frame(URL_jobs)
  
  ##accedim al segon nivell de JSON/dataframe
  jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
  
  ##eliminam els jobs de disney
  jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                            & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
  
  
  ##convertim els NA en FALSE
  jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
  ##holderNameAllPax
  holderNameAllPax<-ggplot(jobs_data_frame_3, aes(x = factor (jobInfos.properties.holderNameAllPax)))+
    geom_bar(fill = "#3995e6", width = 0.5)+
    labs(x = "",y = "Count")+
    geom_text(aes(label = ..count..), stat = "count", vjust =-0.25, colour = "black", position=position_dodge(width=0.9))+
    ggtitle("holderNameAllPax")
  
  holderNameAllPax + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                           panel.background = element_blank(), axis.line = element_line(colour = "black"), plot.title = element_text(size=14, face="bold", hjust = 0.5)) + coord_cartesian(ylim = c(10, 200))
  file <- "plot.png"
  ggsave(file, holderNameAllPax)
  readBin(file, "raw", n = file.info(file)$size)
  
}

#* @tag "Charts by parameter"
#* Generate a chart with pmsRoomCode parameter
#* @get /BMS_jobs_pmsRoomCode
#* @serializer contentType list(type='image/png')
function() {
  require(jsonlite)
  require(ggplot2)
  require(dplyr)
  require(curl)
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
  jobs_data_frame <- as.data.frame(URL_jobs)
  
  ##accedim al segon nivell de JSON/dataframe
  jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
  
  ##eliminam els jobs de disney
  jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                            & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
  
  
  ##convertim els NA en FALSE
  jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
  ##pmsRoomCode
  pmsRoomCode<-ggplot(jobs_data_frame_3, aes(x = factor (jobInfos.properties.pmsRoomCode)))+
    geom_bar(fill = "#3995e6", width = 0.5)+
    labs(x = "",y = "Count")+
    geom_text(aes(label = ..count..), stat = "count", vjust =-0.25, colour = "black", position=position_dodge(width=0.9))+
    ggtitle("pmsRoomCode")
  
  pmsRoomCode + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                      panel.background = element_blank(), axis.line = element_line(colour = "black"), plot.title = element_text(size=14, face="bold", hjust = 0.5)) + coord_cartesian(ylim = c(10, 200))
  file <- "plot.png"
  ggsave(file, pmsRoomCode)
  readBin(file, "raw", n = file.info(file)$size)
  
}


#* @tag "Channels by parameter"
#* Get channels with GVCC
#* @get /Channels_GVCC
function() {
    ##agafam el JSON de la URL i el convertim en dataframe
    URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
    jobs_data_frame <- as.data.frame(URL_jobs)
    
    ##accedim al segon nivell de JSON/dataframe
    jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
    
    ##eliminam els jobs de disney
    jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                              & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
    
    
    ##convertim els NA en FALSE
    jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
    
    
    
    df<-jobs_data_frame_3$jobInfos.properties.CM[which(jobs_data_frame_3$jobInfos.properties.GVCC==TRUE)]
    df

}

#* @tag "Channels by parameter"
#* Get channels with CBD
#* @get /Channels_CBD
function() {
    ##agafam el JSON de la URL i el convertim en dataframe
    URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
    jobs_data_frame <- as.data.frame(URL_jobs)
    
    ##accedim al segon nivell de JSON/dataframe
    jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
    
    ##eliminam els jobs de disney
    jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                              & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
    
    
    ##convertim els NA en FALSE
    jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
    
    
    
    df<-jobs_data_frame_3$jobInfos.properties.CM[which(jobs_data_frame_3$jobInfos.properties.Breakdown==TRUE)]
    df
    
}

#* @tag "Channels by parameter"
#* Get channels with isFinalStatus
#* @get /Channels_isFinalStatus
function() {
    ##agafam el JSON de la URL i el convertim en dataframe
    URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
    jobs_data_frame <- as.data.frame(URL_jobs)
    
    ##accedim al segon nivell de JSON/dataframe
    jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
    
    ##eliminam els jobs de disney
    jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                              & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
    
    
    ##convertim els NA en FALSE
    jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
    
    
    
    df<-jobs_data_frame_3$jobInfos.properties.CM[which(jobs_data_frame_3$jobInfos.properties.isFinalStatus==TRUE)]
    df
}

#* @tag "Channels by parameter"
#* Get channels with holderNameAllPax
#* @get /Channels_holderNameAllPax
function() {
    ##agafam el JSON de la URL i el convertim en dataframe
    URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
    jobs_data_frame <- as.data.frame(URL_jobs)
    
    ##accedim al segon nivell de JSON/dataframe
    jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
    
    ##eliminam els jobs de disney
    jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                              & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
    
    
    ##convertim els NA en FALSE
    jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
    
    
    
    df<-jobs_data_frame_3$jobInfos.properties.CM[which(jobs_data_frame_3$jobInfos.properties.holderNameAllPax==TRUE)]
    df
}

#* @tag "Channels by parameter"
#* Get channels with pmsRoomCode
#* @get /Channels_pmsRoomCode
function() {
    ##agafam el JSON de la URL i el convertim en dataframe
    URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
    jobs_data_frame <- as.data.frame(URL_jobs)
    
    ##accedim al segon nivell de JSON/dataframe
    jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
    
    ##eliminam els jobs de disney
    jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                              & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
    
    
    ##convertim els NA en FALSE
    jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
    jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
    
    
    
    df<-jobs_data_frame_3$jobInfos.properties.CM[which(jobs_data_frame_3$jobInfos.properties.pmsRoomCode==TRUE)]
    df
}

#* @tag "..."
#* Get job configuration for a specific channel manage
#* @get /job_configuration
#* @param Channel
function(Channel) {
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
  jobs_data_frame <- as.data.frame(URL_jobs)
  
  ##accedim al segon nivell de JSON/dataframe
  jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
  
  ##eliminam els jobs de disney
  jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                            & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
  
  
  ##convertim els NA en FALSE
  jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE

  Channel="SINERGIA"
  
  CM<-jobs_data_frame_3$jobInfos.properties.CM[which(jobs_data_frame_3$jobInfos.properties.CM==Channel)]
  CM<-paste("CM:", CM)
  
  cronExpression<-jobs_data_frame_3$jobInfos.cronExpression[which(jobs_data_frame_3$jobInfos.properties.CM==Channel)]
  cronExpression<-paste("cronExpression: ", cronExpression)
  
  GVCC<-jobs_data_frame_3$jobInfos.properties.GVCC[which(jobs_data_frame_3$jobInfos.properties.CM==Channel)]
  GVCC<-paste("GVCC: ", GVCC)
  
  pmsRoomCode<-jobs_data_frame_3$jobInfos.properties.pmsRoomCode[which(jobs_data_frame_3$jobInfos.properties.CM==Channel)]
  pmsRoomCode<-paste("pmsRoomCode: ", pmsRoomCode)
  
  Breakdown<-jobs_data_frame_3$jobInfos.properties.Breakdown[which(jobs_data_frame_3$jobInfos.properties.CM==Channel)]
  Breakdown<-paste("Breakdown: ", Breakdown)
  
  holderNameAllPax<-jobs_data_frame_3$jobInfos.properties.holderNameAllPax[which(jobs_data_frame_3$jobInfos.properties.CM==Channel)]
  holderNameAllPax<-paste("holderNameAllPax: ", holderNameAllPax)
  
  Retry<-jobs_data_frame_3$jobInfos.properties.Retry[which(jobs_data_frame_3$jobInfos.properties.CM==Channel)]
  Retry<-paste("Retry: ", Retry)
  
  isFinalStatus<-jobs_data_frame_3$jobInfos.properties.isFinalStatus[which(jobs_data_frame_3$jobInfos.properties.CM==Channel)]
  isFinalStatus<-paste("isFinalStatus: ", isFinalStatus)
  
  rs<-paste(CM, cronExpression, GVCC, pmsRoomCode, Breakdown, holderNameAllPax, Retry, isFinalStatus, collapse ="\n")
  rs

}


#* @tag "..."
#* Get job for a specific channel manage
#* @serializer unboxedJSON
#* @get /job_channel
#* @param Channel
function(Channel) {
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list")
  
  jobs_data_frame <- as.data.frame(URL_jobs)
  
  ##accedim al segon nivell de JSON/dataframe
  jobs_data_frame_2 <- do.call(data.frame, jobs_data_frame)
  
  ##eliminam els jobs de disney
  jobs_data_frame_3<-subset(jobs_data_frame_2, jobInfos.jobName!="disneyBMSJob" & jobInfos.jobName!="disneyCalendarJobHB"
                            & jobInfos.jobName!="disneyCalendarJobLB" & jobInfos.jobName!="disneyCalendarJobWB")
  
  
  ##convertim els NA en FALSE
  jobs_data_frame_3["jobInfos.properties.GVCC"][is.na(jobs_data_frame_3["jobInfos.properties.GVCC"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.Breakdown"][is.na(jobs_data_frame_3["jobInfos.properties.Breakdown"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.isFinalStatus"][is.na(jobs_data_frame_3["jobInfos.properties.isFinalStatus"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.holderNameAllPax"][is.na(jobs_data_frame_3["jobInfos.properties.holderNameAllPax"])]<-FALSE
  jobs_data_frame_3["jobInfos.properties.pmsRoomCode"][is.na(jobs_data_frame_3["jobInfos.properties.pmsRoomCode"])]<-FALSE
  

  js<-filter(jobs_data_frame_3, jobInfos.properties.CM==Channel)
  js2<-jsonlite::toJSON(js)
  js3<-prettify(js2)
  return(js3)
  
}


