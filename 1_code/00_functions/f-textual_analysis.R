source("1_code/00_functions/f-all.R")

download_google_drive <- function(.id, .dir = NULL, .read_fun = NULL, .overwrite = FALSE) {
  suppressMessages(googledrive::drive_deauth())
  suppressMessages(googledrive::drive_user())
  pub_fil_ <- googledrive::drive_get(googledrive::as_id(.id))


  if (!is.null(.dir)) {
    dir.create(.dir, recursive = TRUE, showWarnings = FALSE)
    path_ <- file.path(.dir, pub_fil_$name)
  } else {
    path_ <- file.path(tempdir(), pub_fil_$name)
  }

  if (!file.exists(path_) | .overwrite) {
    googledrive::drive_download(pub_fil_, path_, NULL, .overwrite, FALSE)
  }


  if (is.null(.read_fun)) {
    return(NULL)
  } else {
    return(.read_fun(path_))
  }
}

get_lm_stop <- function() {
  urls <- c(
    "https://drive.google.com/file/d/0B4niqV00F3mseWZrUk1YMGxpVzQ/view?usp=sharing",
    "https://drive.google.com/file/d/0B4niqV00F3msV1h6N2RhLTNBZG8/view?usp=sharing",
    "https://drive.google.com/file/d/0B4niqV00F3msT18yTE42VWdLdVE/view?usp=sharing",
    "https://drive.google.com/file/d/0B4niqV00F3msVGc4NldrajhQbDg/view?usp=sharing",
    "https://drive.google.com/file/d/0B4niqV00F3msSktONVhfaElXeEk/view?usp=sharing",
    "https://drive.google.com/file/d/0B4niqV00F3msTXRiSmUxRmZWUFE/view?usp=sharing",
    "https://drive.google.com/file/d/0B4niqV00F3msYlZxTm5QaEQ1dTQ/view?usp=sharing"
  )
  ids <- unlist(stringi::stri_split_fixed(urls, "/"))
  ids <- ids[startsWith(ids, "0B4")]


  dir_ <- tempdir()
  tab_lm_stop <- purrr::map_dfr(
    .x = ids,
    .f = ~ download_google_drive(.x, dir_, function(.x) read_tsv(.x, FALSE, col_types = cols("c")))
  ) %>%
    dplyr::rename(word = X1) %>%
    mutate(
      word = word %>%
        stringi::stri_enc_toascii() %>%
        stringi::stri_replace_all_regex("\\|.*", "") %>%
        trimws() %>%
        tolower()
    ) %>%
    dplyr::distinct()
}

pdf_read_and_tokenize <- function(.path, .dir) {
  tab_ <- try(readtext::readtext(.path))
  if (inherits(tab_, "try-error")) {
    return(NULL)
  } else {
    tab_ %>%
      dplyr::select(-doc_id) %>%
      tidytext::unnest_tokens(word, text) %>%
      fst::write_fst(file.path(.dir, gsub("\\.pdf$", ".fst", basename(.path))))
  }
  
  
}

sec_read_and_tokenize <- function(.path, .dir) {
  tab_ <- try(readtext::readtext(.path))
  if (inherits(tab_, "try-error")) {
    return(NULL)
  } else {
    
    tab_ %>%
      dplyr::select(-doc_id) %>%
      dplyr::mutate(text = remove_html_tags(text)) %>%
      tidytext::unnest_tokens(word, text) %>%
      fst::write_fst(file.path(.dir, gsub("\\.zip$", ".fst", basename(.path))))
  }
}

get_ngrams <- function(.path, .ngram, .stop = tibble(word = "", .rows = 0), .rm_num = TRUE) {
  tab_ <- fst::read_fst(.path) %>%
    dplyr::anti_join(dplyr::mutate(.stop, word = tolower(word)), by = "word")
  
  if (.rm_num) {
    tab_ <- dplyr::filter(tab_, !grepl("\\d", word))
  }
  
  if (.ngram == 1) {
    tab_ <- tab_ %>%
      dplyr::count(word, sort = TRUE) %>%
      dplyr::mutate(p = n / sum(n))
  } else {
    tab_ <- tab_ %>%
      dplyr::summarise(word = paste(word, collapse = " ")) %>%
      tidytext::unnest_tokens(word, word, token = "ngrams", n = .ngram) %>%
      dplyr::count(word, sort = TRUE) %>%
      dplyr::mutate(p = n / sum(n))
  }
  
  return(tab_)
}


prep_top_n_by <- function(.tab_word, .tab_data, .col, .n = 10) {
  tab_data_ <- dplyr::select(.tab_data, doc_id, {{ .col }})
  .tab_word %>%
    dplyr::left_join(tab_data_, by = "doc_id") %>%
    dplyr::group_by({{ .col }}, word)  %>%
    dplyr::summarise(n = sum(n), .groups = "drop_last")  %>%
    dplyr::arrange(dplyr::desc(n), .by_group = TRUE) %>%
    dplyr::slice(1:.n) %>%
    dplyr::ungroup() 
}

display_top_n_by <- function(.tab, .col) {
  for (i in unique(dplyr::pull(.tab, {{ .col }}))) {
    print(
      .tab %>%
        dplyr::filter({{ .col }} == i) %>%
        dplyr::mutate(word = reorder(word, n)) %>%
        ggplot2::ggplot(aes(n, word)) +
        ggplot2::geom_col(fill = "blue", color = "grey") +
        ggplot2::scale_x_continuous(labels = scales::comma) +
        ggplot2::labs(x = NULL, y = NULL) +
        ggplot2::theme_bw() + 
        ggplot2::ggtitle(i)
    )
  }
}
