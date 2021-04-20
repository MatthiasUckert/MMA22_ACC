source("1_code/00_functions/f-all.R")

if (!dir.exists("0_data")) dir.create("0_data")

if (!file.exists("0_data/data.zip")) {
  download_google_drive(
    .id = "1ztECROZ8uVYFdwKuUyQHHf1lFBHB8beI",
    .dir = "0_data/"
  )
  
  zip::unzip("0_data/data.zip", exdir = "0_data")
  
  message("data succesfully downloaded and extracted")
}