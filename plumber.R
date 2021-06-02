library(plumber)

#* @apiTitle BMS Jobs

#* send slack message with duplicated jobs
#* @post /BMS_duplicated_jobs_slack
function() {
  library(slackr)
  
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



#* send email with duplicated jobs
#* @post /BMS_duplicated_jobs_email
function() {
  
  
  ##agafam el JSON de la URL i el convertim en dataframe
  URL_jobs <- jsonlite::fromJSON("http://hotelconnect-scheduler.int.service/hotelconnect-scheduler/scheduler/list")
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
  vector<-paste(yourvector,collapse=", ")
  
  
  ##crear cos del correu
  email_body1<-paste("There are", numb, "jobs duplicated: ")
  email_body<-paste(email_body1, vector)
  
  
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
