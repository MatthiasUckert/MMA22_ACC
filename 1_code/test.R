library(tidyverse); library(stringi); library(RDCOMClient)

source("1_code/00_functions/f-all.R")
.dir <- "E:/R/R_projects/MMA22_ACC/0_data/financial_statements"
tab_files <- list_files_tab(.dir, "xlsx") %>%
  mutate(
    year = stri_extract_last_regex(doc_id, "\\d{4}"),
    firm = stri_replace_last_fixed(doc_id, paste0(".", year), "")
  ) 
lst_files <- split(tab_files$path, tab_files$firm)
lst_files <- split(tab_files$path, tab_files$firm)


# .paths <- lst_files[[26]]
.path_map1 <- "E:/R/R_projects/MMA22_ACC/0_data/map_name_to_name_stand.xlsx"
.path_map2 <- "E:/R/R_projects/MMA22_ACC/0_data/map_name_stand_to_id.xlsx"
# .type = "cf"
# # .tab <- tab1



test <- map(lst_files[1:20], ~ get_stand_statement(.x, .path_map1, .path_map2))
iwalk(test[1:20], ~ write_to_excel2(
  .tab = .x, 
  .name = .y, 
  .dir = "E:/R/R_projects/MMA22_ACC/0_data/test", 
  .template = "E:/R/R_projects/MMA22_ACC/0_data/template.xlsx")
  )


files <- list_files_tab("E:/R/R_projects/MMA22_ACC/0_data/test")
tab0 <- map_dfr(
  .x = set_names(files$path, files$doc_id), 
  .f = ~ openxlsx::read.xlsx(.x, colNames = FALSE, sheet = 3), 
  .id = "doc_id"
  ) %>% `colnames<-`(c("doc_id", "Ratio", 2019:2011)) %>%
  filter(!is.na(Ratio), !startsWith(Ratio, "Ratio"), !is.na(`2019`))

tab1 <- tab0 %>%
  pivot_longer(matches("\\d{4}"))
