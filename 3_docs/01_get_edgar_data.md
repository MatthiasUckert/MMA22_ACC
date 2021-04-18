Getting Data from SEC’s EDGAR
================
Matthias Uckert
18 April, 2021

-   [Description](#description)
-   [Script Setup](#script-setup)
-   [Code](#code)
    -   [Paths](#paths)
    -   [Get Fortune 500 Companies](#get-fortune-500-companies)
    -   [Get Company Index-Links](#get-company-index-links)
    -   [Get Company Details](#get-company-details)
    -   [Select Documents for Download](#select-documents-for-download)
    -   [Download Documents](#download-documents)
    -   [Save Files](#save-files)

# Description

This script

# Script Setup

``` r
library(tidyverse); library(edgarWebR); library(lubridate); library(here)
library(furrr); library(stringi); library(textstem); library(tidytext)
library(janitor); library(tools); library(patchwork); library(scales)
library(summarytools); library(kableExtra)

source("1_code/00_functions/f-all.R")
source("1_code/00_functions/f-get_edgar_data.R")
```

# Code

## Paths

``` r
lst_paths <- list(
  dir_main    = "2_output/01_get_edgar_data/",
  path_filing = "2_output/01_get_edgar_data/edgar_filings.rds",
  path_detail = "2_output/01_get_edgar_data/edgar_details.rds"
) %>% create_dirs()
```

## Get Fortune 500 Companies

Her we use an open source data repository ‘datahub.io’ to retrieve the
<u>**fortune 500 companies**</u> with some financial information. We
won’t use the complete data set, but filter for the top 100 companies
(using less companies will let the code run faster) with the highest
market capitalization. You can change the number of companies by
changing the integer vector: **.n\_companies** in the chunk below.

Throughout this script we will use custom functions to download and
transform data. All the script specific functions are stored in this
folder: **1\_code/00\_functions/f-get\_edgar\_data.R**

**Note:** Look at the function <u>**get\_f500()**</u>

``` r
.n_companies <- 100
```

``` r
# View(get_f500)
```

``` r
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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["symbol"],"name":[1],"type":["chr"],"align":["left"]},{"label":["name"],"name":[2],"type":["chr"],"align":["left"]},{"label":["sector"],"name":[3],"type":["chr"],"align":["left"]}],"data":[{"1":"AAPL","2":"Apple Inc.","3":"Information Technology"},{"1":"GOOGL","2":"Alphabet Inc Class A","3":"Information Technology"},{"1":"GOOG","2":"Alphabet Inc Class C","3":"Information Technology"},{"1":"MSFT","2":"Microsoft Corp.","3":"Information Technology"},{"1":"AMZN","2":"Amazon.com Inc","3":"Consumer Discretionary"},{"1":"FB","2":"Facebook, Inc.","3":"Information Technology"},{"1":"JPM","2":"JPMorgan Chase & Co.","3":"Financials"},{"1":"JNJ","2":"Johnson & Johnson","3":"Health Care"},{"1":"XOM","2":"Exxon Mobil Corp.","3":"Energy"},{"1":"BAC","2":"Bank of America Corp","3":"Financials"},{"1":"WMT","2":"Wal-Mart Stores","3":"Consumer Staples"},{"1":"WFC","2":"Wells Fargo","3":"Financials"},{"1":"V","2":"Visa Inc.","3":"Information Technology"},{"1":"BRK.B","2":"Berkshire Hathaway","3":"Financials"},{"1":"T","2":"AT&T Inc","3":"Telecommunication Services"},{"1":"HD","2":"Home Depot","3":"Consumer Discretionary"},{"1":"CVX","2":"Chevron Corp.","3":"Energy"},{"1":"UNH","2":"United Health Group Inc.","3":"Health Care"},{"1":"INTC","2":"Intel Corp.","3":"Information Technology"},{"1":"PFE","2":"Pfizer Inc.","3":"Health Care"},{"1":"VZ","2":"Verizon Communications","3":"Telecommunication Services"},{"1":"PG","2":"Procter & Gamble","3":"Consumer Staples"},{"1":"BA","2":"Boeing Company","3":"Industrials"},{"1":"ORCL","2":"Oracle Corp.","3":"Information Technology"},{"1":"CSCO","2":"Cisco Systems","3":"Information Technology"},{"1":"C","2":"Citigroup Inc.","3":"Financials"},{"1":"KO","2":"Coca-Cola Company (The)","3":"Consumer Staples"},{"1":"MA","2":"Mastercard Inc.","3":"Information Technology"},{"1":"CMCSA","2":"Comcast Corp.","3":"Consumer Discretionary"},{"1":"ABBV","2":"AbbVie Inc.","3":"Health Care"},{"1":"DWDP","2":"DowDuPont","3":"Materials"},{"1":"PEP","2":"PepsiCo Inc.","3":"Consumer Staples"},{"1":"DIS","2":"The Walt Disney Company","3":"Consumer Discretionary"},{"1":"PM","2":"Philip Morris International","3":"Consumer Staples"},{"1":"MRK","2":"Merck & Co.","3":"Health Care"},{"1":"IBM","2":"International Business Machines","3":"Information Technology"},{"1":"MMM","2":"3M Company","3":"Industrials"},{"1":"NVDA","2":"Nvidia Corporation","3":"Information Technology"},{"1":"GE","2":"General Electric","3":"Industrials"},{"1":"MCD","2":"McDonald's Corp.","3":"Consumer Discretionary"},{"1":"AMGN","2":"Amgen Inc","3":"Health Care"},{"1":"MO","2":"Altria Group Inc","3":"Consumer Staples"},{"1":"NFLX","2":"Netflix Inc.","3":"Information Technology"},{"1":"HON","2":"Honeywell Int'l Inc.","3":"Industrials"},{"1":"MDT","2":"Medtronic plc","3":"Health Care"},{"1":"GILD","2":"Gilead Sciences","3":"Health Care"},{"1":"NKE","2":"Nike","3":"Consumer Discretionary"},{"1":"UTX","2":"United Technologies","3":"Industrials"},{"1":"BMY","2":"Bristol-Myers Squibb","3":"Health Care"},{"1":"ABT","2":"Abbott Laboratories","3":"Health Care"},{"1":"UNP","2":"Union Pacific","3":"Industrials"},{"1":"TXN","2":"Texas Instruments","3":"Information Technology"},{"1":"ACN","2":"Accenture plc","3":"Information Technology"},{"1":"LMT","2":"Lockheed Martin Corp.","3":"Industrials"},{"1":"MS","2":"Morgan Stanley","3":"Financials"},{"1":"GS","2":"Goldman Sachs Group","3":"Financials"},{"1":"SLB","2":"Schlumberger Ltd.","3":"Energy"},{"1":"UPS","2":"United Parcel Service","3":"Industrials"},{"1":"QCOM","2":"QUALCOMM Inc.","3":"Information Technology"},{"1":"ADBE","2":"Adobe Systems Inc","3":"Information Technology"},{"1":"AVGO","2":"Broadcom","3":"Information Technology"},{"1":"CAT","2":"Caterpillar Inc.","3":"Industrials"},{"1":"PCLN","2":"Priceline.com Inc","3":"Consumer Discretionary"},{"1":"USB","2":"U.S. Bancorp","3":"Financials"},{"1":"PYPL","2":"PayPal","3":"Information Technology"},{"1":"KHC","2":"Kraft Heinz Co","3":"Consumer Staples"},{"1":"CHTR","2":"Charter Communications","3":"Consumer Discretionary"},{"1":"BLK","2":"BlackRock","3":"Financials"},{"1":"LLY","2":"Lilly (Eli) & Co.","3":"Health Care"},{"1":"TMO","2":"Thermo Fisher Scientific","3":"Health Care"},{"1":"LOW","2":"Lowe's Cos.","3":"Consumer Discretionary"},{"1":"COST","2":"Costco Wholesale Corp.","3":"Consumer Staples"},{"1":"AXP","2":"American Express Co","3":"Financials"},{"1":"CRM","2":"Salesforce.com","3":"Information Technology"},{"1":"SBUX","2":"Starbucks Corp.","3":"Consumer Discretionary"},{"1":"CVS","2":"CVS Health","3":"Consumer Staples"},{"1":"CELG","2":"Celgene Corp.","3":"Health Care"},{"1":"TWX","2":"Time Warner Inc.","3":"Consumer Discretionary"},{"1":"PNC","2":"PNC Financial Services","3":"Financials"},{"1":"WBA","2":"Walgreens Boots Alliance","3":"Consumer Staples"},{"1":"SCHW","2":"Charles Schwab Corporation","3":"Financials"},{"1":"NEE","2":"NextEra Energy","3":"Utilities"},{"1":"BIIB","2":"Biogen Inc.","3":"Health Care"},{"1":"CB","2":"Chubb Limited","3":"Financials"},{"1":"FDX","2":"FedEx Corporation","3":"Industrials"},{"1":"DHR","2":"Danaher Corp.","3":"Health Care"},{"1":"FOX","2":"Twenty-First Century Fox Class B","3":"Consumer Discretionary"},{"1":"MDLZ","2":"Mondelez International","3":"Consumer Staples"},{"1":"COP","2":"ConocoPhillips","3":"Energy"},{"1":"GD","2":"General Dynamics","3":"Industrials"},{"1":"CL","2":"Colgate-Palmolive","3":"Consumer Staples"},{"1":"GM","2":"General Motors","3":"Consumer Discretionary"},{"1":"ANTM","2":"Anthem Inc.","3":"Health Care"},{"1":"EOG","2":"EOG Resources","3":"Energy"},{"1":"AMT","2":"American Tower Corp A","3":"Real Estate"},{"1":"AET","2":"Aetna Inc","3":"Health Care"},{"1":"RTN","2":"Raytheon Co.","3":"Industrials"},{"1":"NOC","2":"Northrop Grumman Corp.","3":"Industrials"},{"1":"SYK","2":"Stryker Corp.","3":"Health Care"},{"1":"AGN","2":"Allergan, Plc","3":"Health Care"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>

## Get Company Index-Links

Retrieve EDGAR Index-Links for Fortune 500 company set. The first step
is to retrieve the index-links for the fortune 500 companies we selected
in the first step. Downloading data from the web is always tricky. We
can run into request limits, client or server side issues. So thinking
about how to set up a download is crucial in order to make the analysis

We use a custom function: **map\_company\_filings()** to retrieve the
Index Links from EDGAR.

``` r
# View(map_company_filings)
```

Here we use a really simple caching procedure so that we don’t have to
re-run the whole expression if we already extracted index-links.

``` r
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

    ## [=======================>-----------------------------------------------------------------------] 25%
    ## [===================================>-----------------------------------------------------------] 38%
    ## [===============================================>-----------------------------------------------] 50%
    ## [==========================================================>------------------------------------] 62%
    ## [======================================================================>------------------------] 75%
    ## [==================================================================================>------------] 88%
    ## [===============================================================================================] 100%

    ## [1] "Results: 0"
    ## [1] "Errors:  8"

``` r
tab_filings <- tab_filings %>%
  mutate(id = stri_replace_all_fixed(
    basename(href), paste0(".", file_ext(href)), "")
    ) %>% distinct(id, .keep_all = TRUE)
```

In total we got 8 errors.

``` r
filter(tab_f500_t10, !symbol %in% read_rds(lst_paths$path_filing)$symbol)
```

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["symbol"],"name":[1],"type":["chr"],"align":["left"]},{"label":["name"],"name":[2],"type":["chr"],"align":["left"]},{"label":["sector"],"name":[3],"type":["chr"],"align":["left"]},{"label":["price"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["price_earnings"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["dividend_yield"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["earnings_share"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["x52_week_low"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["x52_week_high"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["market_cap"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["ebitda"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["price_sales"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["price_book"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["sec_filings"],"name":[14],"type":["chr"],"align":["left"]}],"data":[{"1":"BRK.B","2":"Berkshire Hathaway","3":"Financials","4":"191.42","5":"30.43","6":"0.000000","7":"9.76","8":"217.62","9":"160.93","10":"261401203633","11":"0","12":"1.432823","13":"1.58","14":"http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=BRK.B"},{"1":"DWDP","2":"DowDuPont","3":"Materials","4":"68.21","5":"49.43","6":"2.152975","7":"1.59","8":"77.08","9":"64.01","10":"165203312427","11":"5250000000","12":"2.692239","13":"1.54","14":"http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=DWDP"},{"1":"UTX","2":"United Technologies","3":"Industrials","4":"127.48","5":"19.26","6":"2.121694","7":"5.70","8":"139.24","9":"107.05","10":"105387272474","11":"10584000000","12":"1.732412","13":"3.40","14":"http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=UTX"},{"1":"PCLN","2":"Priceline.com Inc","3":"Consumer Discretionary","4":"1806.06","5":"24.26","6":"0.000000","7":"42.66","8":"2067.99","9":"1589.00","10":"91817448863","11":"4803487000","12":"9.176564","13":"6.92","14":"http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=PCLN"},{"1":"CELG","2":"Celgene Corp.","3":"Health Care","4":"91.02","5":"13.27","6":"0.000000","7":"3.58","8":"147.17","9":"92.85","10":"74921079154","11":"5233000000","12":"5.830071","13":"7.49","14":"http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=CELG"},{"1":"TWX","2":"Time Warner Inc.","3":"Consumer Discretionary","4":"93.02","5":"15.35","6":"1.692777","7":"6.62","8":"103.90","9":"85.88","10":"74185800000","11":"7671000000","12":"2.373599","13":"2.73","14":"http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=TWX"},{"1":"RTN","2":"Raytheon Co.","3":"Industrials","4":"198.74","5":"25.78","6":"1.561276","7":"6.95","8":"213.45","9":"147.86","10":"59066255840","11":"3868000000","12":"2.293833","13":"5.28","14":"http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=RTN"},{"1":"AGN","2":"Allergan, Plc","3":"Health Care","4":"164.20","5":"10.65","6":"1.643289","7":"38.35","8":"256.80","9":"160.07","10":"56668833898","11":"-2888100000","12":"4.820115","13":"0.83","14":"http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=AGN"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>

``` r
browseURL("https://www.sec.gov/cgi-bin/browse-edgar?company=BRK.B&match=&filenum=&State=&Country=&SIC=&myowner=exclude&action=getcompany")
```

Let’s quickly look at the result. (There are several ways to do this.
For small Dataframes we can simply use the RStudio build-in viewer)

``` r
glimpse(tab_filings, 100)
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

``` r
# View(tab_filings)
```

## Get Company Details

After we got the index links from EDGAR, we proceed by scraping filing
details. Again, we use a custom function to do this
**map\_filing\_details()** and use a simple caching algorithm.

``` r
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

From the 2,364 index links we retrieved in the last step, we got 89,302
different document links. It’s important to notice, that such data
retrieval tasks often result in very large datasets.

``` r
glimpse(tab_details, 100)
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

``` r
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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["year"],"name":[1],"type":["dbl"],"align":["right"]},{"label":["10-K"],"name":[2],"type":["int"],"align":["right"]},{"label":["10-K/A"],"name":[3],"type":["int"],"align":["right"]},{"label":["10-K405"],"name":[4],"type":["int"],"align":["right"]},{"label":["10-K405/A"],"name":[5],"type":["int"],"align":["right"]}],"data":[{"1":"1993","2":"780","3":"124","4":"0","5":"0"},{"1":"1994","2":"855","3":"185","4":"347","5":"28"},{"1":"1995","2":"900","3":"142","4":"469","5":"28"},{"1":"1996","2":"938","3":"106","4":"491","5":"109"},{"1":"1997","2":"929","3":"74","4":"696","5":"149"},{"1":"1998","2":"1020","3":"111","4":"464","5":"72"},{"1":"1999","2":"1056","3":"92","4":"572","5":"42"},{"1":"2000","2":"1058","3":"80","4":"611","5":"97"},{"1":"2001","2":"875","3":"147","4":"812","5":"10"},{"1":"2002","2":"2258","3":"232","4":"0","5":"0"},{"1":"2003","2":"2629","3":"170","4":"0","5":"0"},{"1":"2004","2":"2666","3":"150","4":"0","5":"0"},{"1":"2005","2":"2843","3":"140","4":"0","5":"0"},{"1":"2006","2":"3037","3":"126","4":"0","5":"0"},{"1":"2007","2":"2932","3":"248","4":"0","5":"0"},{"1":"2008","2":"3400","3":"174","4":"0","5":"0"},{"1":"2009","2":"3855","3":"75","4":"0","5":"0"},{"1":"2010","2":"3965","3":"141","4":"0","5":"0"},{"1":"2011","2":"4116","3":"44","4":"0","5":"0"},{"1":"2012","2":"4117","3":"148","4":"0","5":"0"},{"1":"2013","2":"4124","3":"30","4":"0","5":"0"},{"1":"2014","2":"4008","3":"53","4":"0","5":"0"},{"1":"2015","2":"4863","3":"76","4":"0","5":"0"},{"1":"2016","2":"4744","3":"36","4":"0","5":"0"},{"1":"2017","2":"4626","3":"116","4":"0","5":"0"},{"1":"2018","2":"4586","3":"47","4":"0","5":"0"},{"1":"2019","2":"4830","3":"44","4":"0","5":"0"},{"1":"2020","2":"4868","3":"36","4":"0","5":"0"},{"1":"2021","2":"280","3":"0","4":"0","5":"0"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>

## Select Documents for Download

In order to reduce the amount of documents we download, we pre-select
specific documents.

``` r
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

``` r
glimpse(tab_download, 100)
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

``` r
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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["year"],"name":[1],"type":["dbl"],"align":["right"]},{"label":["10-K"],"name":[2],"type":["int"],"align":["right"]},{"label":["10-K/A"],"name":[3],"type":["int"],"align":["right"]}],"data":[{"1":"2005","2":"1357","3":"62"},{"1":"2006","2":"1455","3":"63"},{"1":"2007","2":"1401","3":"124"},{"1":"2008","2":"1629","3":"87"},{"1":"2009","2":"1844","3":"31"},{"1":"2010","2":"1896","3":"58"},{"1":"2011","2":"1969","3":"22"},{"1":"2012","2":"1950","3":"74"},{"1":"2013","2":"1970","3":"15"},{"1":"2014","2":"1907","3":"24"},{"1":"2015","2":"2326","3":"28"},{"1":"2016","2":"2268","3":"18"},{"1":"2017","2":"2200","3":"58"},{"1":"2018","2":"2193","3":"22"},{"1":"2019","2":"2308","3":"22"},{"1":"2020","2":"2337","3":"18"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>

``` r
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

![](E:/R/R_projects/MMA22_ACC/3_docs/01_get_edgar_data_files/figure-gfm/unnamed-chunk-13-1.png)<!-- -->

``` r
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

    ## Docs: 1,327
    ## Size: 28,347 MB

``` r
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

    ## Docs: 967
    ## Size: 3,728 MB

``` r
tab_download_xxx <- tab_download %>%
  filter(startsWith(file_ext, "x")) %>%
  arrange(symbol, desc(year), desc(period_date)) %>%
  distinct(document, .keep_all = TRUE)

cat(paste0(
  "Docs: ", comma(nrow(tab_download_xxx)), "\n",
  "Size: ", comma(sum(tab_download_xxx$size)), " MB")
  )
```

    ## Docs: 6,049
    ## Size: 9,511 MB

## Download Documents

Again we use a custom function **download\_edgar\_files()** to download
the documents.

``` r
.dir_docs <- "2_output/01_get_edgar_data/documents/"
tab_xxx <- download_edgar_files(tab_download_xxx, .dir_docs, 10, 2)
tab_htm <- download_edgar_files(tab_download_htm, .dir_docs, 10, 2)
tab_txt <- download_edgar_files(tab_download_txt, .dir_docs, 10, 2)

tab_zip_files <- list_files_tab(.dir_docs, info = TRUE) %>%
  select(doc_id, file_ext, path, size) %>%
  mutate(size = size / 1e6)
```

``` r
cat(paste0(
  "Docs: ", comma(nrow(tab_zip_files)), "\n",
  "Size: ", comma(sum(tab_zip_files$size)), " MB")
  )
```

    ## Docs: 3,298
    ## Size: 3,768 MB

## Save Files

``` r
write_rds(tab_download_htm, "2_output/01_get_edgar_data/htm_download.rds")
write_rds(tab_download_txt, "2_output/01_get_edgar_data/txt_download.rds")
write_rds(tab_download_xxx, "2_output/01_get_edgar_data/xxx_download.rds")
```
