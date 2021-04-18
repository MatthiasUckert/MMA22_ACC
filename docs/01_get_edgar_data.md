---
title: "Getting Data from SEC's EDGAR"
author: "Matthias Uckert"
date: "18 April, 2021"
output: html_document
---

# Description

In this section we will retrieve information from the SEC EDGAR database.


```r
knitr::opts_chunk$set(fig.path='Figs/')
```



# Script Setup


```r
library(tidyverse); library(edgarWebR); library(lubridate); library(here)
library(furrr); library(stringi); library(textstem); library(tidytext)
library(janitor); library(tools); library(patchwork); library(scales)
library(summarytools); library(kableExtra)

source("1_code/00_functions/f-all.R")
source("1_code/00_functions/f-get_edgar_data.R")
```

# Code

## Paths


```r
lst_paths <- list(
  dir_main    = "2_output/01_get_edgar_data/",
  path_filing = "2_output/01_get_edgar_data/edgar_filings.rds",
  path_detail = "2_output/01_get_edgar_data/edgar_details.rds"
) %>% create_dirs()
```

## Get Fortune 500 Companies

Her we use an open source data repository 'datahub.io' to retrieve the [**fortune 500 companies**]{.ul} with some financial information. We won't use the complete data set, but filter for the top 100 companies (using less companies will let the code run faster) with the highest market capitalization. You can change the number of companies by changing the integer vector: **.n_companies** in the chunk below.

Throughout this script we will use custom functions to download and transform data. All the script specific functions are stored in this folder: **1_code/00_functions/f-get_edgar_data.R**

**Note:** Look at the function [**get_f500()**]{.ul}


```r
.n_companies <- 100
```


```r
# View(get_f500)
```


```r
  # browseURL("https://datahub.io/core/s-and-p-500-companies-financials#r")
tab_f500_all <- get_f500() %>%
  # Function from the janitor package, makes nice column names
  clean_names() %>%
  # Arrange, so that the highest market cap appears first in the dataframe
  arrange(desc(market_cap)) 

# Select only the firms with the highest market cap
tab_f500_t10 <- slice(tab_f500_all, 1:.n_companies)

# Quick look at the companies we use
select(tab_f500_t10, symbol, name, sector)
```

```
##     symbol                             name                     sector
## 1     AAPL                       Apple Inc.     Information Technology
## 2    GOOGL             Alphabet Inc Class A     Information Technology
## 3     GOOG             Alphabet Inc Class C     Information Technology
## 4     MSFT                  Microsoft Corp.     Information Technology
## 5     AMZN                   Amazon.com Inc     Consumer Discretionary
## 6       FB                   Facebook, Inc.     Information Technology
## 7      JPM             JPMorgan Chase & Co.                 Financials
## 8      JNJ                Johnson & Johnson                Health Care
## 9      XOM                Exxon Mobil Corp.                     Energy
## 10     BAC             Bank of America Corp                 Financials
## 11     WMT                  Wal-Mart Stores           Consumer Staples
## 12     WFC                      Wells Fargo                 Financials
## 13       V                        Visa Inc.     Information Technology
## 14   BRK.B               Berkshire Hathaway                 Financials
## 15       T                         AT&T Inc Telecommunication Services
## 16      HD                       Home Depot     Consumer Discretionary
## 17     CVX                    Chevron Corp.                     Energy
## 18     UNH         United Health Group Inc.                Health Care
## 19    INTC                      Intel Corp.     Information Technology
## 20     PFE                      Pfizer Inc.                Health Care
## 21      VZ           Verizon Communications Telecommunication Services
## 22      PG                 Procter & Gamble           Consumer Staples
## 23      BA                   Boeing Company                Industrials
## 24    ORCL                     Oracle Corp.     Information Technology
## 25    CSCO                    Cisco Systems     Information Technology
## 26       C                   Citigroup Inc.                 Financials
## 27      KO          Coca-Cola Company (The)           Consumer Staples
## 28      MA                  Mastercard Inc.     Information Technology
## 29   CMCSA                    Comcast Corp.     Consumer Discretionary
## 30    ABBV                      AbbVie Inc.                Health Care
## 31    DWDP                        DowDuPont                  Materials
## 32     PEP                     PepsiCo Inc.           Consumer Staples
## 33     DIS          The Walt Disney Company     Consumer Discretionary
## 34      PM      Philip Morris International           Consumer Staples
## 35     MRK                      Merck & Co.                Health Care
## 36     IBM  International Business Machines     Information Technology
## 37     MMM                       3M Company                Industrials
## 38    NVDA               Nvidia Corporation     Information Technology
## 39      GE                 General Electric                Industrials
## 40     MCD                 McDonald's Corp.     Consumer Discretionary
## 41    AMGN                        Amgen Inc                Health Care
## 42      MO                 Altria Group Inc           Consumer Staples
## 43    NFLX                     Netflix Inc.     Information Technology
## 44     HON             Honeywell Int'l Inc.                Industrials
## 45     MDT                    Medtronic plc                Health Care
## 46    GILD                  Gilead Sciences                Health Care
## 47     NKE                             Nike     Consumer Discretionary
## 48     UTX              United Technologies                Industrials
## 49     BMY             Bristol-Myers Squibb                Health Care
## 50     ABT              Abbott Laboratories                Health Care
## 51     UNP                    Union Pacific                Industrials
## 52     TXN                Texas Instruments     Information Technology
## 53     ACN                    Accenture plc     Information Technology
## 54     LMT            Lockheed Martin Corp.                Industrials
## 55      MS                   Morgan Stanley                 Financials
## 56      GS              Goldman Sachs Group                 Financials
## 57     SLB                Schlumberger Ltd.                     Energy
## 58     UPS            United Parcel Service                Industrials
## 59    QCOM                    QUALCOMM Inc.     Information Technology
## 60    ADBE                Adobe Systems Inc     Information Technology
## 61    AVGO                         Broadcom     Information Technology
## 62     CAT                 Caterpillar Inc.                Industrials
## 63    PCLN                Priceline.com Inc     Consumer Discretionary
## 64     USB                     U.S. Bancorp                 Financials
## 65    PYPL                           PayPal     Information Technology
## 66     KHC                   Kraft Heinz Co           Consumer Staples
## 67    CHTR           Charter Communications     Consumer Discretionary
## 68     BLK                        BlackRock                 Financials
## 69     LLY                Lilly (Eli) & Co.                Health Care
## 70     TMO         Thermo Fisher Scientific                Health Care
## 71     LOW                      Lowe's Cos.     Consumer Discretionary
## 72    COST           Costco Wholesale Corp.           Consumer Staples
## 73     AXP              American Express Co                 Financials
## 74     CRM                   Salesforce.com     Information Technology
## 75    SBUX                  Starbucks Corp.     Consumer Discretionary
## 76     CVS                       CVS Health           Consumer Staples
## 77    CELG                    Celgene Corp.                Health Care
## 78     TWX                 Time Warner Inc.     Consumer Discretionary
## 79     PNC           PNC Financial Services                 Financials
## 80     WBA         Walgreens Boots Alliance           Consumer Staples
## 81    SCHW       Charles Schwab Corporation                 Financials
## 82     NEE                   NextEra Energy                  Utilities
## 83    BIIB                      Biogen Inc.                Health Care
## 84      CB                    Chubb Limited                 Financials
## 85     FDX                FedEx Corporation                Industrials
## 86     DHR                    Danaher Corp.                Health Care
## 87     FOX Twenty-First Century Fox Class B     Consumer Discretionary
## 88    MDLZ           Mondelez International           Consumer Staples
## 89     COP                   ConocoPhillips                     Energy
## 90      GD                 General Dynamics                Industrials
## 91      CL                Colgate-Palmolive           Consumer Staples
## 92      GM                   General Motors     Consumer Discretionary
## 93    ANTM                      Anthem Inc.                Health Care
## 94     EOG                    EOG Resources                     Energy
## 95     AMT            American Tower Corp A                Real Estate
## 96     AET                        Aetna Inc                Health Care
## 97     RTN                     Raytheon Co.                Industrials
## 98     NOC           Northrop Grumman Corp.                Industrials
## 99     SYK                    Stryker Corp.                Health Care
## 100    AGN                    Allergan, Plc                Health Care
```

## Get Company Index-Links

Retrieve EDGAR Index-Links for Fortune 500 company set. The first step is to retrieve the index-links for the fortune 500 companies we selected in the first step. Downloading data from the web is always tricky. We can run into request limits, client or server side issues. So thinking about how to set up a download is crucial in order to make the analysis

We use a custom function: **map_company_filings()** to retrieve the Index Links from EDGAR.


```r
# View(map_company_filings)
```

Here we use a really simple caching procedure so that we don't have to re-run the whole expression if we already extracted index-links.


```r
if (!file.exists(lst_paths$path_filing)) {
  .prc <- tibble(symbol = character(), .rows = 0)
} else {
  .prc <- read_rds(lst_paths$path_filing)
}

tab_f500_use <- filter(tab_f500_t10, !symbol %in% .prc$symbol)

if (nrow(tab_f500_use) > 0) {
  lst_filings <- map_company_filings(
    .tickers = tab_f500_use$symbol, .type = "10-K", .count = 100, .sleep = .2
    )
  tab_filings <- bind_rows(.prc, bind_rows(lst_filings$result, .id = "symbol"))
  write_rds(tab_filings, lst_paths$path_filing)
} else {
  tab_filings <- .prc
}
```

```
## [===================================>-------------------------------------------------------------------------------------------------------------] 25%
## [=====================================================>-------------------------------------------------------------------------------------------] 38%
## [=======================================================================>-------------------------------------------------------------------------] 50%
## [==========================================================================================>------------------------------------------------------] 62%
## [============================================================================================================>------------------------------------] 75%
## [==============================================================================================================================>------------------] 88%
## [=================================================================================================================================================] 100%
```

```
## [1] "Results: 0"
## [1] "Errors:  8"
```

```r
tab_filings <- tab_filings %>%
  mutate(id = stri_replace_all_fixed(
    basename(href), paste0(".", file_ext(href)), "")
    ) %>% distinct(id, .keep_all = TRUE)
```

In total we got 8 errors.


```r
filter(tab_f500_t10, !symbol %in% read_rds(lst_paths$path_filing)$symbol)
```

```
##   symbol                name                 sector   price price_earnings dividend_yield earnings_share x52_week_low x52_week_high   market_cap
## 1  BRK.B  Berkshire Hathaway             Financials  191.42          30.43       0.000000           9.76       217.62        160.93 261401203633
## 2   DWDP           DowDuPont              Materials   68.21          49.43       2.152975           1.59        77.08         64.01 165203312427
## 3    UTX United Technologies            Industrials  127.48          19.26       2.121694           5.70       139.24        107.05 105387272474
## 4   PCLN   Priceline.com Inc Consumer Discretionary 1806.06          24.26       0.000000          42.66      2067.99       1589.00  91817448863
## 5   CELG       Celgene Corp.            Health Care   91.02          13.27       0.000000           3.58       147.17         92.85  74921079154
## 6    TWX    Time Warner Inc. Consumer Discretionary   93.02          15.35       1.692777           6.62       103.90         85.88  74185800000
## 7    RTN        Raytheon Co.            Industrials  198.74          25.78       1.561276           6.95       213.45        147.86  59066255840
## 8    AGN       Allergan, Plc            Health Care  164.20          10.65       1.643289          38.35       256.80        160.07  56668833898
##        ebitda price_sales price_book                                                         sec_filings
## 1           0    1.432823       1.58 http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=BRK.B
## 2  5250000000    2.692239       1.54  http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=DWDP
## 3 10584000000    1.732412       3.40   http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=UTX
## 4  4803487000    9.176564       6.92  http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=PCLN
## 5  5233000000    5.830071       7.49  http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=CELG
## 6  7671000000    2.373599       2.73   http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=TWX
## 7  3868000000    2.293833       5.28   http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=RTN
## 8 -2888100000    4.820115       0.83   http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=AGN
```

```r
browseURL("https://www.sec.gov/cgi-bin/browse-edgar?company=BRK.B&match=&filenum=&State=&Country=&SIC=&myowner=exclude&action=getcompany")
```

Let's quickly look at the result. (There are several ways to do this. For small Dataframes we can simply use the RStudio build-in viewer)


```r
glimpse(tab_filings, 100)
```

```
## Rows: 2,364
## Columns: 13
## $ symbol           <chr> "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "~
## $ accession_number <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N~
## $ act              <chr> "34", "34", "34", "34", "34", "34", "34", "34", "34", "34", "34", "34", "~
## $ file_number      <chr> "001-36743", "001-36743", "001-36743", "001-36743", "001-36743", "001-367~
## $ filing_date      <dttm> 2020-10-30, 2019-10-31, 2018-11-05, 2017-11-03, 2016-10-26, 2015-10-28, ~
## $ accepted_date    <dttm> 2020-10-29, 2019-10-30, 2018-11-05, 2017-11-03, 2016-10-26, 2015-10-28, ~
## $ href             <chr> "https://www.sec.gov/Archives/edgar/data/320193/000032019320000096/000032~
## $ type             <chr> "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "~
## $ film_number      <chr> "201273977", "191181423", "181158788", "171174673", "161953070", "1511806~
## $ form_name        <chr> "Annual report [Section 13 and 15(d), not S-K Item 405]", "Annual report ~
## $ description      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N~
## $ size             <chr> "12 MB", "12 MB", "12 MB", "14 MB", "13 MB", "9 MB", "12 MB", "11 MB", "9~
## $ id               <chr> "0000320193-20-000096-index", "0000320193-19-000119-index", "0000320193-1~
```

```r
# View(tab_filings)
```

## Get Company Details

After we got the index links from EDGAR, we proceed by scraping filing details. Again, we use a custom function to do this **map_filing_details()** and use a simple caching algorithm.


```r
if (!file.exists(lst_paths$path_detail)) {
  .prc <- tibble(id = character(), .rows = 0)
} else {
  .prc <- read_rds(lst_paths$path_detail)
}
tab_filings_use <- filter(tab_filings, !id %in% .prc$id)

if (nrow(tab_filings_use) > 0) {
  lst_details <- map_filing_details(
    .id = tab_filings_use$id, .hrefs = tab_filings_use$href, .sleep = 1
    )
  lst_details <- transpose(lst_details$result)
  lst_details <- map(lst_details, ~ bind_rows(.x, .id = "id"))
  tab_details <- reduce(lst_details, left_join, by = "id")
  
  tab_details <- bind_rows(.prc, .tab_details)
  write_rds(.tab_details, lst_paths$path_detail)
} else {
  tab_details <- .prc
}
rm(tab_filings_use)
```


From the 2,364 index links we retrieved in the last step, we got 89,302 different document links.
It's important to notice, that such data retrieval tasks often result in very large datasets.

```r
glimpse(tab_details, 100)
```

```
## Rows: 89,302
## Columns: 38
## $ id                          <chr> "0000320193-20-000096-index", "0000320193-20-000096-index", "0~
## $ type.x                      <chr> "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K"~
## $ description.x               <chr> "Annual report [Section 13 and 15(d), not S-K Item 405]:", "An~
## $ accession_number            <chr> "0000320193-20-000096", "0000320193-20-000096", "0000320193-20~
## $ filing_date                 <dttm> 2020-10-30, 2020-10-30, 2020-10-30, 2020-10-30, 2020-10-30, 2~
## $ accepted_date               <dttm> 2020-10-29 18:06:25, 2020-10-29 18:06:25, 2020-10-29 18:06:25~
## $ documents                   <int> 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99~
## $ period_date                 <dttm> 2020-09-26, 2020-09-26, 2020-09-26, 2020-09-26, 2020-09-26, 2~
## $ changed_date                <dttm> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N~
## $ effective_date              <dttm> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N~
## $ bytes                       <int> 12502600, 12502600, 12502600, 12502600, 12502600, 12502600, 12~
## $ seq                         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 15, 16, NA, 10, 11, 12, 13, 14, 17,~
## $ description.y               <chr> "10-K", "EX-4.1", "EX-10.16", "EX-10.17", "EX-21.1", "EX-23.1"~
## $ document                    <chr> "aapl-20200926.htm", "a10-kexhibit419262020.htm", "a10-kexhibi~
## $ href                        <chr> "https://www.sec.gov/Archives/edgar/data/320193/00003201932000~
## $ type.y                      <chr> "10-K", "EX-4.1", "EX-10.16", "EX-10.17", "EX-21.1", "EX-23.1"~
## $ size                        <int> 2467306, 123356, 56918, 74685, 9230, 5991, 10582, 10618, 8476,~
## $ mailing_address_1           <chr> "ONE APPLE PARK WAY", "ONE APPLE PARK WAY", "ONE APPLE PARK WA~
## $ mailing_address_2           <chr> "CUPERTINO CA 95014", "CUPERTINO CA 95014", "CUPERTINO CA 9501~
## $ mailing_address_3           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA~
## $ mailing_address_4           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA~
## $ business_address_1          <chr> "ONE APPLE PARK WAY", "ONE APPLE PARK WAY", "ONE APPLE PARK WA~
## $ business_address_2          <chr> "CUPERTINO CA 95014", "CUPERTINO CA 95014", "CUPERTINO CA 9501~
## $ business_address_3          <chr> "(408) 996-1010", "(408) 996-1010", "(408) 996-1010", "(408) 9~
## $ business_address_4          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA~
## $ company_name                <chr> "Apple Inc.", "Apple Inc.", "Apple Inc.", "Apple Inc.", "Apple~
## $ company_cik                 <chr> "0000320193", "0000320193", "0000320193", "0000320193", "00003~
## $ company_filings_href        <chr> "https://www.sec.gov/cgi-bin/browse-edgar?CIK=0000320193&actio~
## $ company_irs_number          <chr> "942404110", "942404110", "942404110", "942404110", "942404110~
## $ company_incorporation_state <chr> "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA", "C~
## $ company_fiscal_year_end     <chr> "0926", "0926", "0926", "0926", "0926", "0926", "0926", "0926"~
## $ filing_type                 <chr> "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K"~
## $ filing_act                  <chr> "34", "34", "34", "34", "34", "34", "34", "34", "34", "34", "3~
## $ file_number_href            <chr> "https://www.sec.gov/cgi-bin/browse-edgar?filenum=001-36743&ac~
## $ file_number                 <chr> "001-36743", "001-36743", "001-36743", "001-36743", "001-36743~
## $ film_number                 <chr> "201273977", "201273977", "201273977", "201273977", "201273977~
## $ sic_code                    <chr> "3571", "3571", "3571", "3571", "3571", "3571", "3571", "3571"~
## $ sic_href                    <chr> "https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&SI~
```

```r
# View(tab_details)
tab_details %>%
  mutate(year = year(period_date)) %>%
  group_by(type.x, year) %>%
  count() %>%
  pivot_wider(
    names_from = type.x, 
    values_from = n, 
    names_sort = TRUE,
    values_fill = 0
    )
```

```
## # A tibble: 29 x 5
## # Groups:   year [29]
##     year `10-K` `10-K/A` `10-K405` `10-K405/A`
##    <dbl>  <int>    <int>     <int>       <int>
##  1  1993    780      124         0           0
##  2  1994    855      185       347          28
##  3  1995    900      142       469          28
##  4  1996    938      106       491         109
##  5  1997    929       74       696         149
##  6  1998   1020      111       464          72
##  7  1999   1056       92       572          42
##  8  2000   1058       80       611          97
##  9  2001    875      147       812          10
## 10  2002   2258      232         0           0
## # ... with 19 more rows
```


## Select Documents for Download

In order to reduce the amount of documents we download, we pre-select specific documents.


```r
tab_download <- tab_details %>%
  distinct() %>%
  left_join(select(tab_filings, symbol, id), by = "id") %>%
  mutate(
    file_ext = tools::file_ext(href),
    year = year(period_date),
    size = size / 1e6,
    across(where(is.character), ~ stri_replace_all_regex(., "[[:blank:]]+", " ")),
    across(c(type.y, description.y), ~ if_else(. %in% c("", " "), NA_character_, .))
    ) %>%
  select(id, document, state = company_incorporation_state, 
         sic = sic_code, year, symbol, company_name, company_cik, 
         type1 = type.x, type2 = type.y, desc = description.y, 
         period_date, href, size, file_ext) %>%
  filter(between(year, 2005, 2020))
```



```r
glimpse(tab_download, 100)
```

```
## Rows: 31,736
## Columns: 15
## $ id           <chr> "0000320193-20-000096-index", "0000320193-20-000096-index", "0000320193-20-00~
## $ document     <chr> "aapl-20200926.htm", "a10-kexhibit419262020.htm", "a10-kexhibit10169262020.ht~
## $ state        <chr> "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA", "CA",~
## $ sic          <chr> "3571", "3571", "3571", "3571", "3571", "3571", "3571", "3571", "3571", "3571~
## $ year         <dbl> 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020,~
## $ symbol       <chr> "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL", "AAPL~
## $ company_name <chr> "Apple Inc.", "Apple Inc.", "Apple Inc.", "Apple Inc.", "Apple Inc.", "Apple ~
## $ company_cik  <chr> "0000320193", "0000320193", "0000320193", "0000320193", "0000320193", "000032~
## $ type1        <chr> "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K", "10-K~
## $ type2        <chr> "10-K", "EX-4.1", "EX-10.16", "EX-10.17", "EX-21.1", "EX-23.1", "EX-31.1", "E~
## $ desc         <chr> "10-K", "EX-4.1", "EX-10.16", "EX-10.17", "EX-21.1", "EX-23.1", "EX-31.1", "E~
## $ period_date  <dttm> 2020-09-26, 2020-09-26, 2020-09-26, 2020-09-26, 2020-09-26, 2020-09-26, 2020~
## $ href         <chr> "https://www.sec.gov/Archives/edgar/data/320193/000032019320000096/aapl-20200~
## $ size         <dbl> 2.467306, 0.123356, 0.056918, 0.074685, 0.009230, 0.005991, 0.010582, 0.01061~
## $ file_ext     <chr> "htm", "htm", "htm", "htm", "htm", "htm", "htm", "htm", "htm", "jpg", "jpg", ~
```

```r
tab_download %>%
  group_by(type1, year) %>%
  count() %>%
  pivot_wider(
    names_from = type1, 
    values_from = n, 
    names_sort = TRUE,
    values_fill = 0
  )
```

```
## # A tibble: 16 x 3
## # Groups:   year [16]
##     year `10-K` `10-K/A`
##    <dbl>  <int>    <int>
##  1  2005   1357       62
##  2  2006   1455       63
##  3  2007   1401      124
##  4  2008   1629       87
##  5  2009   1844       31
##  6  2010   1896       58
##  7  2011   1969       22
##  8  2012   1950       74
##  9  2013   1970       15
## 10  2014   1907       24
## 11  2015   2326       28
## 12  2016   2268       18
## 13  2017   2200       58
## 14  2018   2193       22
## 15  2019   2308       22
## 16  2020   2337       18
```



```r
.tmp <- tab_download %>%
  group_by(year) %>%
  summarise(size = sum(size), n = n(), .groups = "drop")


.geom_size <- .tmp %>%
  ggplot(aes(x = year, y = size)) +
  geom_line(color = "blue") + 
  geom_point() + 
  labs(x = NULL, y = NULL) + 
  scale_y_continuous(labels = scales::comma) + 
  theme_bw() + 
  ggtitle("Size per Year (in MB)")

.geom_n <- .tmp %>%
  ggplot(aes(x = year, y = n)) +
  geom_col(fill = "blue") + 
  labs(x = NULL, y = NULL) + 
  scale_y_continuous(labels = scales::comma) + 
  theme_bw() + 
  ggtitle("Number of Documents per year")

.geom_size / .geom_n
```

![](Figs/unnamed-chunk-11-1.png)<!-- -->


```r
tab_download_txt <- tab_download %>%
  filter(file_ext == "txt", desc == "Complete submission text file") %>%
  arrange(symbol, desc(year), desc(period_date)) %>%
  distinct(symbol, year, .keep_all = TRUE) %>%
  distinct(document, .keep_all = TRUE)

cat(paste0(
  "Docs: ", comma(nrow(tab_download_txt)), "\n",
  "Size: ", comma(sum(tab_download_txt$size)), " MB")
  )
```

```
## Docs: 1,327
## Size: 28,347 MB
```


```r
tab_download_htm <- tab_download %>%
  filter(startsWith(file_ext, "htm"), grepl("10-K", desc)) %>%
  arrange(symbol, desc(year), desc(period_date)) %>%
  distinct(symbol, year, .keep_all = TRUE) %>%
  distinct(document, .keep_all = TRUE)

cat(paste0(
  "Docs: ", comma(nrow(tab_download_htm)), "\n",
  "Size: ", comma(sum(tab_download_htm$size)), " MB")
  )
```

```
## Docs: 967
## Size: 3,728 MB
```


```r
tab_download_xxx <- tab_download %>%
  filter(startsWith(file_ext, "x")) %>%
  arrange(symbol, desc(year), desc(period_date)) %>%
  distinct(document, .keep_all = TRUE)

cat(paste0(
  "Docs: ", comma(nrow(tab_download_xxx)), "\n",
  "Size: ", comma(sum(tab_download_xxx$size)), " MB")
  )
```

```
## Docs: 6,049
## Size: 9,511 MB
```

## Download Documents

Again we use a custom function **download_edgar_files()** to download the documents.


```r
.dir_docs <- "2_output/01_get_edgar_data/documents/"
tab_xxx <- download_edgar_files(tab_download_xxx, .dir_docs, 10, 2)
tab_htm <- download_edgar_files(tab_download_htm, .dir_docs, 10, 2)
tab_txt <- download_edgar_files(tab_download_txt, .dir_docs, 10, 2)

tab_zip_files <- list_files_tab(.dir_docs, info = TRUE) %>%
  select(doc_id, file_ext, path, size) %>%
  mutate(size = size / 1e6)
```



```r
cat(paste0(
  "Docs: ", comma(nrow(tab_zip_files)), "\n",
  "Size: ", comma(sum(tab_zip_files$size)), " MB")
  )
```

```
## Docs: 3,298
## Size: 3,768 MB
```

## Save Files


```r
write_rds(tab_download_htm, "2_output/01_get_edgar_data/htm_download.rds")
write_rds(tab_download_txt, "2_output/01_get_edgar_data/txt_download.rds")
write_rds(tab_download_xxx, "2_output/01_get_edgar_data/xxx_download.rds")
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
