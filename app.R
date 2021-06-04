library(plumber)

port <- Sys.getenv('PORT')

server <- plumb("plumber.R")

server$run(
	host = '0.0.0.0',
	port = as.numeric(port),
	swagger=TRUE
)

con <- url("http://hotelconnect-scheduler.live.service/hotelconnect-scheduler/scheduler/list", "rb") 
lego_movie <- read_html(con)
