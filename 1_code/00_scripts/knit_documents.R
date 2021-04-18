rmarkdown::render(
  input = "1_code/01_get_edgar_data.Rmd",
  output_format = rmarkdown::html_document(
    toc = TRUE,
    toc_depth = 2,
    toc_float = TRUE,
    keep_md = TRUE,
    self_contained = TRUE
  ),
  output_dir = "docs/"
  
)
