library(tidyverse); library(stringi); library(openxlsx); library(furrr)
options(scipen = 999)
source("1_code/00_functions/f-all.R")

.path_fs_map <- "0_data/map_name_to_name_stand.xlsx"

get_map <- function(.sheet) {
  openxlsx::read.xlsx(.path_fs_map, sheet = .sheet) %>%
    expand_grid(tibble(year = 2011:2019)) %>%
    select(id:name_stand, year, formula)
}
f_prep_table <- function(.path, .map) {
  a <- openxlsx::read.xlsx(.path, 2) %>%
    janitor::clean_names() %>%
    select(-x1) %>%
    mutate(across(everything(), as.character)) %>%
    pivot_longer(cols = !matches("company_name_latin_alphabet")) %>%
    filter(!value == "n.a.") %>%
    mutate(
      year = as.integer(stri_extract_last_regex(name, "\\d{4}")),
      unit = stri_extract_last_regex(name, "\\w_eur"),
      name = stri_replace_all_fixed(name, paste0("_m_eur_", year), "")
    ) %>%
    select(firm = company_name_latin_alphabet, year, name, value) %>%
    mutate(value = as.numeric(value)) %>%
    filter(between(year, 2011, 2019)) %>%
    left_join(.map, by = c("name", "year")) %>%
    arrange(firm, year, id) %>%
    select(firm, year, name, name_disp, everything()) %>%
    filter(!startsWith(name, "number_of"))
}
f_prep_statement <- function(.tab) {
  years <- unique(.tab$year)
  lst_years <- map(years, ~ c(.x, .x + 1))
  lst_years <- lst_years[map_lgl(lst_years, ~all(.x %in% 2011:2019))]
  names(lst_years) <- unlist(map(lst_years, ~ .x[2]))
  map(
    .x = lst_years,
    .f = ~ .tab %>%
      filter(year %in% .x) %>%
      filter(!is.na(value), value != 0) %>%
      select(-firm) %>%
      arrange(desc(year)) %>%
      pivot_wider(names_from = year, values_from = value) %>%
      arrange(id) %>%
      select(-id)
  )
  
}
f_write_excel <- function(.tab_row, .dir) {
  wb <- openxlsx::createWorkbook()
  
  openxlsx::addWorksheet(wb, "Overview")
  openxlsx::addWorksheet(wb, "Income Statement")
  openxlsx::addWorksheet(wb, "Balance Sheet - Asset")
  openxlsx::addWorksheet(wb, "Balance Sheet - Liability")
  openxlsx::addWorksheet(wb, "Cash Flow Statement")
  
  tab_overview <- tribble(
    ~ desc, ~ val,
    "", "",
    "Information", "",
    "Company Name:", stri_replace_last_regex(.tab_row$name, "\\.\\d{4}", ""),
    "Year:", stri_extract_last_regex(.tab_row$name, "\\d{4}"),
    "", "",
    "Available Statements", "",
    "Income Statement", "Sheet 2",
    "Balance Sheet: Assets", "Sheet 3",
    "Balance Sheet: Liabilities & Equity", "Sheet 4",
    "Cash-Flow Statement", "Sheet 5"
  )
  
  writeData(wb, "Overview", tab_overview, rowNames = FALSE, colNames = FALSE)
  mergeCells(wb, "Overview", 1:2, rows = c(2))
  mergeCells(wb, "Overview", 1:2, rows = c(6))
  setColWidths(wb, "Overview", cols = 1:ncol(tab_overview), widths = "auto")
  
  writeDataTable(wb, "Income Statement", .tab_row$is[[1]], rowNames = FALSE, tableName = "income_statement")
  setColWidths(wb, "Income Statement", cols = 1:ncol(.tab_row$is[[1]]), widths = "auto")
  
  writeDataTable(wb, "Balance Sheet - Asset", .tab_row$bsa[[1]], rowNames = FALSE, tableName = "balance_sheet_asset")
  setColWidths(wb, "Balance Sheet - Asset", cols = 1:ncol(.tab_row$bsa[[1]]), widths = "auto")
  
  writeDataTable(wb, "Balance Sheet - Liability", .tab_row$bsl[[1]], rowNames = FALSE, tableName = "balance_sheet_liability")
  setColWidths(wb, "Balance Sheet - Liability", cols = 1:ncol(.tab_row$bsl[[1]]), widths = "auto")
  
  writeDataTable(wb, "Cash Flow Statement", .tab_row$cf[[1]], rowNames = FALSE, tableName = "cash_flow_statement")
  setColWidths(wb, "Cash Flow Statement", cols = 1:ncol(.tab_row$cf[[1]]), widths = "auto")
  
  path_ <- file.path(.dir, paste0(.tab_row$name, ".xlsx"))
  
  openxlsx::saveWorkbook(wb, path_, overwrite = TRUE)
}
check_values <- function(.tab) {
  .tab <- mutate(.tab, check_num = NA_integer_)
  
  f <- na.omit(unique(.tab$formula))
  for(i in seq_len(length(f))) {
    int <- as.integer(trimws(unlist(stri_split_regex(f[i], "\\=|\\+"))))
    val0 <- .tab$value[which(.tab$id == int[1])]
    val1 <- .tab$value[which(.tab$id %in% int[-1])]
    
    if (length(val1) > 0) {
      .tab$check_num[which(.tab$id == int[1])] <- sum(val1)
    } else {
      .tab$check_num[which(.tab$id == int[1])] <- sum(val0)
    }
    
    
  }
  
  .tab %>%
    mutate(
      diff = abs(value - check_num),
      check = between(diff, -1, 1)
    )
}


plan("multisession", workers = 8)
# BSA ---------------------------------------------------------------------
.path_bsa <- "0_data/orbis_financial_data/bs-asset.xlsx"
tab_bsa <- f_prep_table(.path_bsa, get_map(2))
tab_bsa <- future_map_dfr(split(tab_bsa, paste0(tab_bsa$firm, tab_bsa$year)), check_values) %>%
  group_by(firm, year) %>%
  mutate(check = all(check | is.na(check))) %>%
  ungroup()
tab_bsa_check <- filter(tab_bsa, !check)


# BSL ---------------------------------------------------------------------
.path_bsl <- "0_data/orbis_financial_data/bs-iabilities.xlsx"
tab_bsl <- f_prep_table(.path_bsl, get_map(3))
tab_bsl <- future_map_dfr(split(tab_bsl, paste0(tab_bsl$firm, tab_bsl$year)), check_values) %>%
  group_by(firm, year) %>%
  mutate(check = all(check | is.na(check))) %>%
  ungroup()
tab_bsl_check <- filter(tab_bsl, !check)


# CF ----------------------------------------------------------------------
.path_cf <- "0_data/orbis_financial_data/cf-statement.xlsx"
tab_cf <- f_prep_table(.path_cf, get_map(4))
tab_cf <- future_map_dfr(split(tab_cf, paste0(tab_cf$firm, tab_cf$year)), check_values) %>%
  group_by(firm, year) %>%
  mutate(check = all(check | is.na(check))) %>%
  ungroup()
tab_cf_check <- filter(tab_cf, !check)



# IS ----------------------------------------------------------------------
.path_is <- "0_data/orbis_financial_data/is-statement.xlsx"
tab_is <- f_prep_table(.path_is, get_map(1))
tab_is <- future_map_dfr(split(tab_is, paste0(tab_is$firm, tab_is$year)), check_values) %>%
  group_by(firm, year) %>%
  mutate(check = all(check | is.na(check))) %>%
  ungroup()
tab_is_check <- filter(tab_is, !check)

chr_rm <- unique(c(tab_bsa_check$firm, tab_bsl_check$firm, tab_cf_check$firm, tab_is_check$firm))


# IS ----------------------------------------------------------------------
tab_is  <- tab_is %>%
  filter(!firm %in% chr_rm) %>%
  select(firm, year, id, name = name_disp, value)
lst_is <- split(tab_is, tab_is$firm)
lst_is <- future_map(lst_is, f_prep_statement)
tab_is  <- enframe(unlist(lst_is, FALSE), value = "is")


# BSA ---------------------------------------------------------------------
tab_bsa <- filter(tab_bsa, !firm %in% chr_rm) %>%
  filter(!firm %in% chr_rm) %>%
  select(firm, year, id, name = name_disp, value)
lst_bsa <- split(tab_bsa, tab_bsa$firm)
lst_bsa <- future_map(lst_bsa, f_prep_statement)
tab_bsa <- enframe(unlist(lst_bsa, FALSE), value = "bsa")


# BSL ---------------------------------------------------------------------
tab_bsl <- filter(tab_bsl, !firm %in% chr_rm) %>%
  filter(!firm %in% chr_rm) %>%
  select(firm, year, id, name = name_disp, value)
lst_bsl <- split(tab_bsl, tab_bsl$firm)
lst_bsl <- future_map(lst_bsl, f_prep_statement)
tab_bsl <- enframe(unlist(lst_bsl, FALSE), value = "bsl")


# CF ----------------------------------------------------------------------
tab_cf  <- filter(tab_cf , !firm %in% chr_rm) %>%
  filter(!firm %in% chr_rm) %>%
  select(firm, year, id, name = name_disp, value)
lst_cf <- split(tab_cf, tab_cf$firm)
lst_cf <- future_map(lst_cf, f_prep_statement)
tab_cf <- enframe(unlist(lst_cf, FALSE), value = "cf")

plan("default")

write.table(tab, "clipboard", sep="\t", row.names=FALSE)


# ALL ----------------------------------------------------------------------

tab <- tab_is %>%
  left_join(tab_bsa, by = "name") %>%
  left_join(tab_bsl, by = "name") %>%
  left_join(tab_cf, by = "name") %>%
  mutate(
    year = as.integer(stri_extract_last_regex(name, "\\d{4}")),
    firm = stri_replace_all_fixed(name, paste0(".", year), "")
    ) %>%
  mutate(
    l = lengths(is) + lengths(bsa) + lengths(bsl) + lengths(cf)
  ) %>%
  filter(l == 12) %>%
  group_by(firm) %>%
  filter(all(2012:2019 %in% year)) %>%
  ungroup()


.dir_xlsx <- "0_data/financial_statements"
plan("multisession", workers = 8)
future_walk(split(tab, 1:nrow(tab)), ~ f_write_excel(.x, .dir_xlsx))
plan("default")