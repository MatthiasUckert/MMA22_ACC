# urls <- list(
#   dei = "https://xbrl.sec.gov//dei/{.year}/dei-{.year}-01-31.xsd"),
# srt = "http://xbrl.fasb.org/srt/{.year}/elts/srt-{.year}-01-31.xsd"),
# ctr = "https://xbrl.sec.gov/country/{.year}/country-{.year}-01-31.xsd"),
# stre = glue::glue("http://xbrl.fasb.org/srt/{.year}/elts/srt-eedm1-def-{.year}-01-31.xml"),
# num1 = "https://www.xbrl.org/dtr/type/numeric-2012-06-30.xsd",
# num2 = "https://www.xbrl.org/dtr/type/numeric-2009-12-16.xsd",
# nnum = "https://www.xbrl.org/dtr/type/nonnumeric-2009-12-16.xsd",
# enum = "https://www.xbrl.org/dtr/type/enumeration-2013-06-30.xsd",
# ref = "https://www.xbrl.org/2006/ref-2006-02-27.xsd",
# cur = "https://xbrl.sec.gov/currency/2019/currency-2019-01-31.xsd",
# exch = "https://xbrl.sec.gov/exch/2019/exch-2019-01-31.xsd"
# )

download_xbrl <- function(.dir) {
  if (!dir.exists(.dir)) dir.create(.dir, recursive = TRUE)
  urls_ <- c(
    "https://xbrl.sec.gov//dei/2020/dei-2020-01-31.xsd",
    "http://xbrl.fasb.org/srt/2020/elts/srt-2020-01-31.xsd",
    "https://xbrl.sec.gov/country/2020/country-2020-01-31.xsd",
    "https://www.xbrl.org/dtr/type/numeric-2012-06-30.xsd",
    "https://www.xbrl.org/dtr/type/numeric-2009-12-16.xsd",
    "https://www.xbrl.org/dtr/type/nonnumeric-2009-12-16.xsd",
    "https://www.xbrl.org/dtr/type/enumeration-2013-06-30.xsd"
  )
  files_ <- purrr::map_chr(urls_, ~ file.path(.dir, basename(.x)))
  avail_ <- list.files(.dir, recursive = TRUE)
  files_ <- files_[!basename(files_) %in% basename(avail_)]
  
  purrr::map2(urls_, files_, ~ try(download.file(.x, .y, mode = "wb", quiet = TRUE), silent = TRUE))
}

download_xbrl <- function(.dir, .urls) {
  if (!dir.exists(.dir)) dir.create(.dir, recursive = TRUE)
  urls_ <- tolower(.urls)
  files_ <- purrr::map_chr(urls_, ~ file.path(.dir, basename(.x)))
  avail_ <- list.files(.dir, recursive = TRUE)
  urls_ <- .urls[!basename(files_) %in% basename(avail_)]
  files_ <- files_[!basename(files_) %in% basename(avail_)]
  
  purrr::map2(urls_, files_, ~ try(download.file(.x, .y, mode = "wb", quiet = TRUE)))
}


XBRL::xbrlDoAll()


cache.dir <- .dir <- "E:/R/R_projects/MMA22_ACC/2_output/01_get_edgar_data/documents/AAPL/tax/2020"
.url <- "https://www.sec.gov/Archives/edgar/data/320193/000032019320000096/aapl-20200926_htm.xml"
download_xbrl(.dir)


# xbrl_data_aapl2020 <- XBRL::xbrlDoAll(.url, verbose = TRUE, delete.cached.inst = FALSE, cache.dir = .dir)

library(XBRL); library(tidyverse); library(xml2)

file.inst <- "https://www.sec.gov/Archives/edgar/data/320193/000032019319000119/a10-k20199282019_htm.xml"
cache.dir <- "E:/R/R_projects/MMA22_ACC/2_output/01_get_edgar_data/documents/AAPL/tax/2019"
prefix.out = NULL 
verbose = TRUE
delete.cached.inst = FALSE

