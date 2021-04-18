---
title: "Getting Data AnnualReport.com"
author: "Matthias Uckert"
date: "18 April, 2021"
output: 
  html_document
---

    # github_document:
    # toc: true
    # toc_depth: 2

# Description

In this section we will download information and documents from **https://www.annualreports.com**.



# Script Setup


```r
library(tidyverse); library(rvest); library(xml2); library(janitor); library(furrr)
library(openxlsx); library(fuzzyjoin); library(stringdist); library(ISOcodes)

source("1_code/00_functions/f-all.R")
source("1_code/00_functions/f-get_arcom_data.R")

.workers <- min(availableCores() / 2, 16)
```


# Code

## Paths


```r
lst_paths <- list(
  dir_main    = "2_output/02_get_arcom_data",
  path_orbis  = "0_data/orbis_listed.xlsx",
  path_firm_links = "2_output/02_get_arcom_data/arcom_firm_links.rds",
  dir_html = "2_output/02_get_arcom_data/html",
  path_report_links = "2_output/02_get_arcom_data/arcom_report_links.rds",
  path_matched_firms = "2_output/02_get_arcom_data/arcom_matched_firms.rds"
) %>% create_dirs()
```


## Read Orbis Firms
We use European large firm data retrieved from Orbis to match companies.

```r
tab_orbis <- read.xlsx(lst_paths$path_orbis, 2) %>%
  rename(Alpha_2 = Country.ISO.code) %>%
  left_join(
    x = select(ISO_3166_1, Alpha_2, country_code = Alpha_3, country = Name),
    by = "Alpha_2"
  ) %>%
  select(
    isin = ISIN.number, company = Company.name.Latin.alphabet,
    country_code, country
  ) %>%
  filter(!is.na(company))
```


## Get Annual Report Firms
We use a custom function: **get_company_table()** to retrieve company information from www.annualreport.com.
In contrast to the custom functions we used in 01_get_edgar_data, we don't explicitly make this function error proof, but wrap it into another function (purrr::safely()) that catches any error.
Again we use simple caching to not re-run results we already obtained.


```r
# View(get_company_table)
```



```r
if (!file.exists(lst_paths$path_firm_links)) {
  .prc <- tibble(id = character(), .rows = 0)
} else {
  .prc <- read_rds(lst_paths$path_firm_links)
}

base_url <- "https://www.annualreports.com/Companies?ind=i"
.urls <- set_names(paste0(base_url, 1:250), 1:250)

urls_use <- .urls[!names(.urls) %in% .prc$id]
length(urls_use)
```

```
## [1] 39
```

```r
if (length(urls_use) > 0) {
  safe_get_company_table <- safely(get_company_table)
  
  plan("multisession", workers = .workers)
  lst_firm_links <- future_map(
    .x = urls_use,
    .f = safe_get_company_table,
    .options = furrr_options(seed = TRUE),
    .progress = TRUE
  ) %>% transpose()
  plan("default")
  err <- compact(lst_firm_links$error)
  tab_firm_links <- bind_rows(.prc, bind_rows(lst_firm_links$result, .id = "id"))
  write_rds(tab_firm_links, lst_paths$path_firm_links)
} else {
  tab_firm_links <- .prc
}

# browseURL(urls_use[1])
rm(urls_use)
```


```r
glimpse(tab_firm_links, 100)
```

```
## Rows: 5,258
## Columns: 7
## $ id       <chr> "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "2", "~
## $ company  <chr> "American Vanguard Corp.", "Arcadia Biosciences", "CF Industries Holdings, Inc.",~
## $ industry <chr> "Agricultural Chemicals", "Agricultural Chemicals", "Agricultural Chemicals", "Ag~
## $ sector   <chr> "Basic Materials", "Basic Materials", "Basic Materials", "Basic Materials", "Basi~
## $ premium  <chr> "/img/ar/category_premiumBadge.png", "/img/ar/category_verifiedBadge.png", "/img/~
## $ request  <chr> "", "", "Request", "", "", "Request", "", "", "", "", "", "", "", "Request", "", ~
## $ link     <chr> "https://www.annualreports.com/Company/american-vanguard-corp", "https://www.annu~
```

```r
# View(tab_filings)
```


## Get Annual Report HTMLs
Before we download annual reports in PDF format, we first scrape the complete website. For most datasets it is best practice to have intermediate files (in this case .html files) locally, which can be scarped in exact the same manner as any other website, without the need of an active connection to the server. 

Here we don't write a custom function explicitly. Nonetheless, we implicitly wrap it into our walk function.


```r
.prc <- list_files_tab(lst_paths$dir_html)
tab_firm_links <- mutate(tab_firm_links, doc_id = basename(link))
tab_links_use  <- filter(tab_firm_links, !doc_id %in% .prc$doc_id)
nrow(tab_links_use)
```

```
## [1] 0
```

```r
if (nrow(tab_links_use) > 0) {
  plan("multisession", workers = .workers)
  future_walk(
    .x = tab_links_use$link,
    .f = ~ .x %>%
      read_html() %>%
      write_html(file.path(lst_paths$dir_html, paste0(basename(.x), ".html"))),
    .options = furrr_options(seed = TRUE),
    .progress = TRUE
  )
  plan("default")
}
rm(tab_links_use)
```

## Get Annual Report Links
After retrieving the all the html files on a firm level, we extract the actual documents links to the PDF we will download in the next step. Here we use the custom function: **get_infos()**


```r
if (!file.exists(lst_paths$path_report_links)) {
  plan("multisession", workers = .workers)
  tab_report_links <- future_map_dfr(
    .x = list_files_tab(.dir_html)[["path"]],
    .f = get_infos,
    .options = furrr_options(seed = TRUE),
    .progress = TRUE
  )
  plan("default")
  write_rds(tab_report_links, lst_paths$path_report_links)
} else {
  tab_report_links <- read_rds(lst_paths$path_report_links)
}

nrow(tab_report_links)
```

```
## [1] 54477
```


## Match Firms
To not artifically increase the number of PDFs we download, we restrict our set to companies that we can match to the Orbis file. 
Note: Company name matching between databases is a non-trivial task. For those who are interested, I dedicated a whole package to this task: **https://github.com/MatthiasUckert/RFirmMatch**. We won't use this library here. Rather we restrict our adjustments to a few simple Regular Expressions and functions.

### FUll Matches

```r
tab0 <- mutate(tab_firm_links, match = standardize_name(company)) %>%
  filter(!is.na(match))
tab1 <- mutate(tab_orbis, match = standardize_name(company)) %>%
  filter(!is.na(match))

tab_match_full <- inner_join(tab0, tab1, by = "match", suffix = c("_0", "_1"))

tab0 <- filter(tab0, !match %in% tab_match_full$match)
tab1 <- filter(tab1, !match %in% tab_match_full$match)
```

### Fuzzy Matches

```r
tab_match_fuzzy <- stringdist_inner_join(
  x = tab0,
  y = tab1,
  by = "match",
  max_dist = 2
) %>% mutate(sim = stringsim(match.x, match.y)) %>%
  arrange(match.x, desc(sim)) %>%
  distinct(match.x, .keep_all = TRUE) %>%
  select(-match.x, -match.y) %>%
  rename(company_0 = company.x, company_1 = company.y)

select(tab_match_fuzzy, sim, company_0, company_1) %>%
  arrange(desc(sim)) %>%
  mutate(row = row_number())
```

```
## # A tibble: 64 x 4
##      sim company_0                            company_1                            row
##    <dbl> <chr>                                <chr>                              <int>
##  1 0.971 Millicom International Cellular S.A. MILLICOM INTERNATIONAL CELLULAR SA     1
##  2 0.969 Corporacion America Airports SA      CORPORACION AMERICA AIRPORTS S.A.      2
##  3 0.969 Turkcell Iletisim Hizmetleri AS      TURKCELL ILETISIM HIZMETLERI A.S.      3
##  4 0.938 Ardagh Group Sa                      ARDAGH GROUP S.A.                      4
##  5 0.929 Akzo Nobel N.V.                      AKZO NOBEL NV                          5
##  6 0.923 Iberdrola S.A.                       IBERDROLA SA                           6
##  7 0.923 Inter Parfums                        INTERPARFUMS                           7
##  8 0.923 WSP Group plc                        SSP GROUP PLC                          8
##  9 0.917 Heineken N.V.                        HEINEKEN NV                            9
## 10 0.917 Intelsat SA                          INTELSAT S.A.                         10
## # ... with 54 more rows
```


```r
tab_match_fuzzy <- tab_match_fuzzy %>%
  slice(c(1,2,3,4,5,6,7,9,10,11,12,14,15,18,21,24,29)) %>%
  select(-sim)
```


## Select Companies

```r
tab_match <- bind_rows(tab_match_full, tab_match_fuzzy) %>%
  mutate(doc_id = basename(link)) %>%
  select(doc_id, isin, company = company_1) %>%
  left_join(select(tab_report_links, doc_id, link, year), by = "doc_id") %>%
  filter(between(year, 2005, 2020)) %>%
  select(isin, year, company, link) %>%
  mutate(doc_id = gsub("\\.pdf$", "", basename(link)))

write_rds(tab_match, lst_paths$path_matched_firms)
```

## Download Annual Reports
For downloading the annual reports we use a custom function **downlad_ar()**


```r
.dir_ar <- "2_output/02_get_arcom_data/documents"
if (!dir.exists(.dir_ar)) dir.create(.dir_ar, recursive = TRUE)

.prc <- list_files_tab(.dir_ar)

tab_download_use <- filter(tab_match, !doc_id %in% .prc$doc_id)

# walk(tab_download_use$link, ~ downlad_ar(.x, .dir_ar))
```


## Save Output

```r
tab_data <- tab_match %>%
  left_join(tab_orbis, by = c("isin", "company")) %>%
  select(doc_id, isin, year, company, country_code, country)

write_rds(tab_data, "2_output/02_get_arcom_data/arcom_firm_data.rds")
```


# Own Function Calls

```r
lsf.str()
```

```
## create_dirs : function (.dirs)  
## downlad_ar : function (.url, .dir)  
## download_edgar_files : function (.tab, .dir, .retry = 5, .sleep = 1)  
## get_company_table : function (.url)  
## get_f500 : function ()  
## get_infos : function (.path)  
## list_files_tab : function (dirs, reg = "*", id = "doc_id", rec = FALSE, info = FALSE)  
## map_company_filings : function (.tickers, .ownership = FALSE, .type = "", .before = "", .count = 100, .page = 1, .progress = TRUE, .sleep = 0, .retry = 5)  
## map_filing_details : function (.id, .hrefs, .progress = TRUE, .sleep = 0, .retry = 5)  
## remove_html_tags : function (.string, rm_linebreaks = TRUE)  
## safe_get_company_table : function (...)  
## standardize_name : function (.name)
```


# Session Info

```r
sessioninfo::session_info()
```

```
## - Session info -----------------------------------------------------------------------------------------------------------------------------------------
##  setting  value                       
##  version  R version 4.0.3 (2020-10-10)
##  os       Windows 10 x64              
##  system   x86_64, mingw32             
##  ui       RStudio                     
##  language (EN)                        
##  collate  English_Germany.1252        
##  ctype    English_Germany.1252        
##  tz       Europe/Berlin               
##  date     2021-04-18                  
## 
## - Packages ---------------------------------------------------------------------------------------------------------------------------------------------
##  ! package        * version    date       lib source        
##  P assertthat       0.2.1      2019-03-21 [?] CRAN (R 4.0.0)
##  P backports        1.2.1      2020-12-09 [?] CRAN (R 4.0.3)
##  P base64enc        0.1-3      2015-07-28 [?] CRAN (R 4.0.0)
##  P broom            0.7.6      2021-04-05 [?] CRAN (R 4.0.3)
##  P bslib            0.2.4      2021-01-25 [?] CRAN (R 4.0.4)
##  P cellranger       1.1.0      2016-07-27 [?] CRAN (R 4.0.0)
##  P checkmate        2.0.0      2020-02-06 [?] CRAN (R 4.0.0)
##  P cli              2.4.0      2021-04-05 [?] CRAN (R 4.0.3)
##  P codetools        0.2-16     2018-12-24 [?] CRAN (R 4.0.3)
##  P colorspace       2.0-0      2020-11-11 [?] CRAN (R 4.0.3)
##  P crayon           1.4.1      2021-02-08 [?] CRAN (R 4.0.4)
##  P curl             4.3        2019-12-02 [?] CRAN (R 4.0.0)
##  P data.table       1.14.0     2021-02-21 [?] CRAN (R 4.0.4)
##  P DBI              1.1.1      2021-01-15 [?] CRAN (R 4.0.3)
##  P dbplyr           2.1.1      2021-04-06 [?] CRAN (R 4.0.3)
##  P digest           0.6.27     2020-10-24 [?] CRAN (R 4.0.3)
##  P dplyr          * 1.0.5      2021-03-05 [?] CRAN (R 4.0.4)
##  P edgarWebR      * 1.0.3      2020-09-28 [?] CRAN (R 4.0.5)
##  P ellipsis         0.3.1      2020-05-15 [?] CRAN (R 4.0.0)
##  P evaluate         0.14       2019-05-28 [?] CRAN (R 4.0.0)
##  P fansi            0.4.2      2021-01-15 [?] CRAN (R 4.0.3)
##  P farver           2.1.0      2021-02-28 [?] CRAN (R 4.0.4)
##  P forcats        * 0.5.1      2021-01-27 [?] CRAN (R 4.0.4)
##  P fs               1.5.0      2020-07-31 [?] CRAN (R 4.0.2)
##  P furrr          * 0.2.2      2021-01-29 [?] CRAN (R 4.0.4)
##  P future         * 1.21.0     2020-12-10 [?] CRAN (R 4.0.3)
##  P fuzzyjoin      * 0.1.6      2020-05-15 [?] CRAN (R 4.0.2)
##  P generics         0.1.0      2020-10-31 [?] CRAN (R 4.0.3)
##  P ggplot2        * 3.3.3      2020-12-30 [?] CRAN (R 4.0.3)
##  P globals          0.14.0     2020-11-22 [?] CRAN (R 4.0.3)
##  P glue             1.4.2      2020-08-27 [?] CRAN (R 4.0.2)
##  P gtable           0.3.0      2019-03-25 [?] CRAN (R 4.0.0)
##  P haven            2.3.1      2020-06-01 [?] CRAN (R 4.0.0)
##  P here           * 1.0.1      2020-12-13 [?] CRAN (R 4.0.3)
##  P highr            0.8        2019-03-20 [?] CRAN (R 4.0.0)
##  P hms              1.0.0      2021-01-13 [?] CRAN (R 4.0.3)
##  P htmltools        0.5.1.1    2021-01-22 [?] CRAN (R 4.0.4)
##  P httr             1.4.2      2020-07-20 [?] CRAN (R 4.0.2)
##  P ISOcodes       * 2021.02.24 2021-02-24 [?] CRAN (R 4.0.4)
##  P janeaustenr      0.1.5      2017-06-10 [?] CRAN (R 4.0.0)
##  P janitor        * 2.1.0      2021-01-05 [?] CRAN (R 4.0.3)
##  P jquerylib        0.1.3      2020-12-17 [?] CRAN (R 4.0.4)
##  P jsonlite         1.7.2      2020-12-09 [?] CRAN (R 4.0.3)
##  P kableExtra     * 1.3.4      2021-02-20 [?] CRAN (R 4.0.4)
##  P knitr            1.31       2021-01-27 [?] CRAN (R 4.0.4)
##  P koRpus         * 0.13-5     2021-02-02 [?] CRAN (R 4.0.5)
##  P koRpus.lang.en * 0.1-4      2020-10-24 [?] CRAN (R 4.0.5)
##  P labeling         0.4.2      2020-10-20 [?] CRAN (R 4.0.3)
##  P lattice          0.20-41    2020-04-02 [?] CRAN (R 4.0.3)
##  P lifecycle        1.0.0      2021-02-15 [?] CRAN (R 4.0.4)
##  P listenv          0.8.0      2019-12-05 [?] CRAN (R 4.0.0)
##  P lubridate      * 1.7.10     2021-02-26 [?] CRAN (R 4.0.4)
##  P magick           2.7.1      2021-03-20 [?] CRAN (R 4.0.5)
##  P magrittr         2.0.1      2020-11-17 [?] CRAN (R 4.0.3)
##  P Matrix           1.2-18     2019-11-27 [?] CRAN (R 4.0.3)
##  P matrixStats      0.58.0     2021-01-29 [?] CRAN (R 4.0.4)
##  P modelr           0.1.8      2020-05-19 [?] CRAN (R 4.0.0)
##  P munsell          0.5.0      2018-06-12 [?] CRAN (R 4.0.0)
##  P openxlsx       * 4.2.3      2020-10-27 [?] CRAN (R 4.0.3)
##  P pander           0.6.3      2018-11-06 [?] CRAN (R 4.0.0)
##  P parallelly       1.24.0     2021-03-14 [?] CRAN (R 4.0.4)
##  P patchwork      * 1.1.1      2020-12-17 [?] CRAN (R 4.0.3)
##  P pillar           1.5.1      2021-03-05 [?] CRAN (R 4.0.4)
##  P pkgconfig        2.0.3      2019-09-22 [?] CRAN (R 4.0.0)
##  P plyr             1.8.6      2020-03-03 [?] CRAN (R 4.0.0)
##  P prettyunits      1.1.1      2020-01-24 [?] CRAN (R 4.0.0)
##  P progress         1.2.2      2019-05-16 [?] CRAN (R 4.0.0)
##  P pryr             0.1.4      2018-02-18 [?] CRAN (R 4.0.2)
##  P purrr          * 0.3.4      2020-04-17 [?] CRAN (R 4.0.0)
##  P R6               2.5.0      2020-10-28 [?] CRAN (R 4.0.3)
##  P rapportools      1.0        2014-01-07 [?] CRAN (R 4.0.2)
##  P Rcpp             1.0.6      2021-01-15 [?] CRAN (R 4.0.3)
##  P readr          * 1.4.0      2020-10-05 [?] CRAN (R 4.0.3)
##  P readxl           1.3.1      2019-03-13 [?] CRAN (R 4.0.0)
##    renv             0.13.1     2021-03-18 [1] CRAN (R 4.0.3)
##  P reprex           2.0.0      2021-04-02 [?] CRAN (R 4.0.5)
##  P rlang            0.4.10     2020-12-30 [?] CRAN (R 4.0.3)
##  P rmarkdown        2.7        2021-02-19 [?] CRAN (R 4.0.4)
##  P rprojroot        2.0.2      2020-11-15 [?] CRAN (R 4.0.3)
##  P rstudioapi       0.13       2020-11-12 [?] CRAN (R 4.0.3)
##  P rvest          * 1.0.0      2021-03-09 [?] CRAN (R 4.0.4)
##  P sass             0.3.1      2021-01-24 [?] CRAN (R 4.0.4)
##  P scales         * 1.1.1      2020-05-11 [?] CRAN (R 4.0.0)
##  P sessioninfo      1.1.1      2018-11-05 [?] CRAN (R 4.0.0)
##  P snakecase        0.11.0     2019-05-25 [?] CRAN (R 4.0.0)
##  P SnowballC        0.7.0      2020-04-01 [?] CRAN (R 4.0.0)
##  P stringdist     * 0.9.6.3    2020-10-09 [?] CRAN (R 4.0.3)
##  P stringi        * 1.5.3      2020-09-09 [?] CRAN (R 4.0.2)
##  P stringr        * 1.4.0      2019-02-10 [?] CRAN (R 4.0.2)
##  P summarytools   * 0.9.9      2021-03-19 [?] CRAN (R 4.0.5)
##  P svglite          2.0.0      2021-02-20 [?] CRAN (R 4.0.4)
##  P sylly          * 0.1-6      2020-09-20 [?] CRAN (R 4.0.5)
##  P sylly.en         0.1-3      2018-03-19 [?] CRAN (R 4.0.5)
##  P systemfonts      1.0.1      2021-02-09 [?] CRAN (R 4.0.4)
##  P textstem       * 0.1.4      2018-04-09 [?] CRAN (R 4.0.5)
##  P tibble         * 3.1.0      2021-02-25 [?] CRAN (R 4.0.4)
##  P tidyr          * 1.1.3      2021-03-03 [?] CRAN (R 4.0.4)
##  P tidyselect       1.1.0      2020-05-11 [?] CRAN (R 4.0.0)
##  P tidytext       * 0.3.0      2021-01-06 [?] CRAN (R 4.0.3)
##  P tidyverse      * 1.3.0      2019-11-21 [?] CRAN (R 4.0.0)
##  P tokenizers       0.2.1      2018-03-29 [?] CRAN (R 4.0.0)
##  P utf8             1.2.1      2021-03-12 [?] CRAN (R 4.0.3)
##  P vctrs            0.3.7      2021-03-29 [?] CRAN (R 4.0.5)
##  P viridisLite      0.3.0      2018-02-01 [?] CRAN (R 4.0.0)
##  P webshot          0.5.2      2019-11-22 [?] CRAN (R 4.0.0)
##  P withr            2.4.1      2021-01-26 [?] CRAN (R 4.0.4)
##  P xfun             0.22       2021-03-11 [?] CRAN (R 4.0.4)
##  P xml2           * 1.3.2      2020-04-23 [?] CRAN (R 4.0.0)
##  P yaml             2.2.1      2020-02-01 [?] CRAN (R 4.0.0)
##  P zip              2.1.1      2020-08-27 [?] CRAN (R 4.0.2)
## 
## [1] E:/R/R_projects/MMA22_ACC/renv/library/R-4.0/x86_64-w64-mingw32
## [2] C:/Users/MUcke/AppData/Local/Temp/Rtmp0uTiZW/renv-system-library
## 
##  P -- Loaded and on-disk path mismatch.
```
