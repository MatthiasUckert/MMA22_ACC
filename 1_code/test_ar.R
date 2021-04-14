# library(tidyverse); library(janitor); library(rvest); library(xml2)
# 
# .url <- "https://www.deutsche-boerse-cash-market.com/resource/blob/67858/fd4e9497bbd44a363e7cfd74009e81a6/data/Listed-companies.xlsx"
# .path <- paste0(tempfile(), ".xlsx")
# download.file(.url, .path, quiet = TRUE, mode = "wb")
# 
# sheets <- openxlsx::getSheetNames(.path)
# lst_companies <- map(sheets, ~ openxlsx::read.xlsx(.path, .x, colNames = FALSE))
# 
# tab <- openxlsx::read.xlsx(.path, 2, colNames = FALSE) %>%
#   slice(-(1:5)) %>%
#   janitor::row_to_names(1) %>%
#   janitor::clean_names() %>%
#   select(isin, symbol = trading_symbol, company:country)
# 
# urls <- paste0("https://www.annualreports.com/Companies?ind=i", 1:250)
# names(urls) <- 1:250
# 
# get_company_table <- function(.url) {
#   html_ <- read_html(.url) %>%
#     html_elements(xpath = "/html/body/div[1]/section[1]/div[2]/ul") %>%
#     html_nodes("li")
#   
#   html_ <- html_[-1]
#   headers_ <- c("company", "industry", "sector", "premium", "request")
#   
#   f_get_table <- function(.node) {
#     spans_ <- html_elements(.node, "span")
#     links_ <- url_absolute(html_attr(html_elements(spans_, "a"), "href"), "https://www.annualreports.com/Company/")[1]
#     
#     vals_ <- map_chr(spans_, html_text2)
#     vals_[4] <- html_attr(html_elements(spans_, "img"), "src")
#     
#     names(vals_) <- headers_
#     
#     mutate(pivot_wider(enframe(vals_)), link = links_)
#   }
#   
#   
#   map_dfr(seq_len(length(html_)), ~ f_get_table(html_[[.x]]))
#   
# }
# 
# 
# test <- map_dfr(urls[1:10], get_company_table, .id = "id")
# 
# 
# 
# lst_links <- map(
#   .x = urls,
#   .f = ~ {
#     Sys.sleep(1)
#     read_html(.x) %>%
#       html_elements(xpath = "/html/body/div[1]/section[1]/div[2]/ul") %>%
#       html_children() %>%
#       html_nodes("a") %>%
#       html_attr("href") %>%
#       `[`(!. == "") %>%
#       url_absolute(., "https://www.annualreports.com/Company/")
#     
#   }
# )
# 
# 
# browseURL(urls[7])
# 
# .url <- urls[3]
# 
# html <- read_html(.url) %>%
#   html_elements(xpath = "/html/body/div[1]/section[1]/div[2]/ul") %>%
#   html_children() %>%
#   html_nodes("a") %>%
#   html_attr("href") %>%
#   `[`(!. == "") %>%
#   url_absolute(., "https://www.annualreports.com/Company/")
# 
# %>%
#   html_text2()
# 
# RFAnnualReportCom::
#   
#   
#   ```{r}
# .url <- "https://www.deutsche-boerse-cash-market.com/resource/blob/67858/fd4e9497bbd44a363e7cfd74009e81a6/data/Listed-companies.xlsx"
# .path <- paste0(tempfile(), ".xlsx")
# download.file(.url, .path, quiet = TRUE, mode = "wb")
# 
# 
# tab_firms <- map_dfr(
#   .x = set_names(2:3, c("prime", "general")),
#   .f = ~ read.xlsx(.path, .x, colNames = FALSE, skipEmptyRows = FALSE, skipEmptyCols = TRUE) %>%
#     slice(-(1:7)) %>%
#     select(X1:X7) %>%
#     row_to_names(1) %>%
#     clean_names() %>%
#     select(isin, symbol = trading_symbol, company:country),
#   .id = "standard"
# ) %>% select(standard, everything())
# 
# 
# 
# 
# ```
