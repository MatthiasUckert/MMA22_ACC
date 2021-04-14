# 
# 
# 
# ```{r}
# .dir_files <- file.path(.dir_main, "documents")
# .prc       <- list.files(.dir_files, recursive = TRUE)
# 
# tab_download_use <- filter(tab_download, !save_name %in% basename(.prc))
# if (nrow(tab_download_use) > 0) {
#   plan("multisession", workers = 8)
#   future_pmap(
#     .l = list(tab_download_use$href, tab_download_use$symbol, tab_download_use$year, tab_download_use$save_name),
#     .f = ~ download_edgar_files(..1, ..2, ..3, ..4, .dir_files),
#     .options = furrr_options(seed = TRUE),
#     .progress = TRUE
#   )
#   plan("default")
# }
# tab_download_use <- filter(tab_download, !save_name %in% basename(.prc))
# nrow(tab_download_use)
# rm(tab_download_use)
# ```
# 
# ```{r}
# tab_files <- list_files_tab(.dir_files, rec = TRUE)
# tab_files_txt <- filter(tab_files, file_ext == ".txt")
# tab_files_htm <- filter(tab_files, file_ext == ".htm")
# 
# 
# 
# test <- own_get_fs(
#   .url = "https://www.sec.gov/Archives/edgar/data/320193/000032019318000145/aapl-20180929.xml",
#   .dir_cache = "test"
# )
# 
# 
# a <- finreportr::GetIncome("GOOG", 2018)
# finreportr::CompanyInfo("GOOG")
# 
# a <- XBRL::xbrlDoAll("E:/R/R_projects/MMA22_ACC/2_output/01_get_edgar_data/documents/AAPL/tax/2020/aapl-20200926_htm.xml")
# 
# b <- XBRL::xbrlDoAll("E:/R/R_projects/MMA22_ACC/test.xml")
# 
# ```
# 
# <https://stackoverflow.com/questions/5068951/what-do-lt-and-gt-stand-for> <https://stackoverflow.com/questions/60060043/clean-tags-from-sec-edgar-filings-in-readtext-and-quanteda>
#   
#   ```{r}
# urls <- c(
#   "https://drive.google.com/file/d/0B4niqV00F3mseWZrUk1YMGxpVzQ/view?usp=sharing",
#   "https://drive.google.com/file/d/0B4niqV00F3msV1h6N2RhLTNBZG8/view?usp=sharing",
#   "https://drive.google.com/file/d/0B4niqV00F3msT18yTE42VWdLdVE/view?usp=sharing",
#   "https://drive.google.com/file/d/0B4niqV00F3msVGc4NldrajhQbDg/view?usp=sharing",
#   "https://drive.google.com/file/d/0B4niqV00F3msSktONVhfaElXeEk/view?usp=sharing",
#   "https://drive.google.com/file/d/0B4niqV00F3msTXRiSmUxRmZWUFE/view?usp=sharing",
#   "https://drive.google.com/file/d/0B4niqV00F3msYlZxTm5QaEQ1dTQ/view?usp=sharing"
# )
# ids <- unlist(stri_split_fixed(urls, "/"))
# ids <- ids[startsWith(ids, "0B4")]
# 
# 
# .dir_lm_stop <- file.path(.dir_main, "lm_stop")
# tab_lm_stop <- map_dfr(
#   .x = ids,
#   .f = ~ download_google_drive(
#     .x, .dir_lm_stop, function(.x) read_tsv(.x, FALSE, col_types = cols("c"))
#   )
# ) %>% rename(stop = X1) %>%
#   mutate(
#     stop = stop %>%
#       stri_enc_toascii() %>%
#       stri_replace_all_regex("\\|.*", "") %>%
#       trimws() %>%
#       tolower()
#   ) %>%
#   distinct()
# ```
# 
# ```{r}
# test <- readtext::readtext(tab_files_txt$path[1]) %>%
#   mutate(
#     text = gsub("<.*?>|&#\\d+;|&lt;.*?&gt;", "", text),
#     text = gsub("&amp;", "&", text)
#   ) %>%
#   tidytext::unnest_tokens(word, text, token = "ngrams", n = 1) %>%
#   anti_join(tab_lm_stop, by = c("word" = "stop")) %>%
#   filter(!grepl("\\d", word)) %>%
#   mutate(tmp = lemmatize_words(word)) %>%
#   count(tmp, word, sort = TRUE) %>%
#   group_by(tmp) %>%
#   summarise(
#     words = paste(sort(word), collapse = " | "),
#     n = sum(n),
#     .groups = "drop"
#   ) %>%
#   arrange(desc(n)) %>%
#   rename(word = tmp) %>%
#   mutate(p = n / sum(n))
# ```
# 
# ```{r}
# test <- readtext::readtext(tab_files_txt$path[1:4]) %>%
#   mutate(
#     text = gsub("<.*?>|&#\\d+;|&lt;.*?&gt;", "", text),
#     text = gsub("&amp;", "&", text)
#   ) %>%
#   unnest_tokens(text, text, token = stri_split_lines) %>%
#   group_by(doc_id) %>%
#   mutate(index = row_number() %/% 200) %>%
#   filter(max(index) >= 100) %>%
#   ungroup() %>%
#   unnest_tokens(word, text, token = "ngrams", n = 1) %>%
#   anti_join(tab_lm_stop, by = c("word" = "stop")) %>%
#   count(doc_id, index, word, sort = TRUE) %>%
#   inner_join(get_sentiments("loughran"), by = "word") %>%
#   pivot_wider(names_from = sentiment, values_from = n, values_fill = 0) %>% 
#   mutate(sentiment = positive - negative)
# 
# ggplot(test, aes(index, sentiment, fill = doc_id)) +
#   geom_col(show.legend = FALSE) +
#   facet_wrap(~doc_id, ncol = 2, scales = "free_x")
# ```
# 
# ```{r}
# 
# ```
# 
# ```{r}
# inst <- "https://www.sec.gov/Archives/edgar/data/21344/000002134413000050/ko-20130927.xml"
# 
# xbrl.vars <- xbrlDoAll(inst, cache.dir="XBRLcache", prefix.out="out", verbose=TRUE)
# ```
# 
# ```{r}
# download.file(
#   url = "https://www.sec.gov/Archives/edgar/data/4515/000119312516474605/aal-20151231.xml",
#   destfile = "test.xml"
# )
# ```
# 
# ```{r}
# %>%
#   filter(n > 3000) %>%
#   mutate(word = reorder(word, n)) %>%
#   ggplot(aes(n, word)) +
#   geom_col() +
#   labs(y = NULL)
# 
# test %>%
#   count(doc_id, word, sort = TRUE) %>%
#   group_by(doc_id) %>%
#   mutate(proportion = n() / sum(n())) %>%
#   ungroup() %>%
#   ggplot(aes(x = proportion, y = doc_id)) +
#   geom_abline(color = "gray40", lty = 2) +
#   geom_jitter(alpha = 0.1, size = 2.5, width = 0.3, height = 0.3) +
#   geom_text(aes(label = word), check_overlap = TRUE, vjust = 1.5) +
#   scale_x_log10(labels = percent_format()) +
#   scale_y_log10(labels = percent_format()) +
#   # scale_color_gradient(limits = c(0, 0.001), low = "darkslategray4", high = "gray75") +
#   facet_wrap(~ doc_id, ncol = 2) +
#   theme(legend.position="none") +
#   labs(y = "Jane Austen", x = NULL)
# 
# ```
# 
# ```{r}
# test <- trimws(gsub("<.*?>|&#\\d+;", "", test))
# 
# edgar::getSentiment()
# 
# start  <- grep("<HTML>", test)
# finish <- grep("</HTML>", test)
# 
# test <- readtext::readtext(tab_files_txt$path[6])
# test <- edgarWebR::parse_text_filing(test)
# test <- parse_filing(tab_files_htm$path[1])
# 
# ```
