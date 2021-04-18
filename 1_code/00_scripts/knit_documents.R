rmarkdown::render(
  input = "1_code/01_get_edgar_data.Rmd",
  output_format = rmarkdown::github_document(
    toc = TRUE,
    toc_depth = 2,
    number_sections = FALSE
  ),
  output_dir = "3_docs/"
)
