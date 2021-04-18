list_files_tab <- function(dirs, reg = "*", id = "doc_id", rec = FALSE, info = FALSE) {
  path <- file_ext <- NULL
  
  tab_fil <- purrr::map_dfr(
    .x = dirs,
    .f = ~ tibble::tibble(path = list.files(.x, reg, F, T, rec))
  ) %>%
    dplyr::mutate(
      file_ext = paste0(".", tools::file_ext(path)),
      !!dplyr::sym(id) := stringi::stri_replace_last_fixed(basename(path), file_ext, "")
    ) %>%
    dplyr::select(!!dplyr::sym(id), file_ext, path)
  
  if (info) {
    tab_fil <- dplyr::bind_cols(tab_fil, tibble::as_tibble(file.info(tab_fil$path)))
  }
  
  return(tab_fil)
}


remove_html_tags <- function(.string, rm_linebreaks = TRUE) {
  string_ <- .string %>%
    stringi::stri_replace_all_regex(., "<script.*?>.*?</script>", "") %>%
    stringi::stri_replace_all_regex(., "<xbrl.*?>.*?</xbrl.*?>", "") %>%
    stringi::stri_replace_all_regex(., "<.*?>|&#.+?;|&lt;.*?&gt;", "") %>%
    stringi::stri_replace_all_fixed(., "&nbsp;", " ") %>%
    stringi::stri_replace_all_regex(., "&amp;", "&") 
  
  if (rm_linebreaks) {
    string_ <- stringi::stri_replace_all_regex(string_, "([[:blank:]]|[[:space:]])+", " ")  
  }
    trimws(string_)
}

create_dirs <- function(.dirs) {
  dirs0_ <- unlist(.dirs)
  file_ext_ <- tools::file_ext(dirs0_)
  dirs1_ <- dplyr::if_else(file_ext_ == "", dirs0_, dirname(dirs0_))

  purrr::walk(
    .x = unique(dirs1_),
    .f = ~ {
      if (!dir.exists(.x)) {
        dir.create(.x, showWarnings = FALSE, recursive = TRUE)
      }
    }
  )
  return(.dirs)
  
}