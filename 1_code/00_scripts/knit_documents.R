rmarkdown::render(
  input = "1_code/01_get_edgar_data.Rmd",
  output_dir = "docs/"
)

rmarkdown::render(
  input = "1_code/02_get_arcom_data.Rmd",
  output_dir = "docs/"
)

# rmarkdown::render(
#   input = "1_code/03_textual_analysis.nb.html",
#   output_format = rmarkdown::html_document(
#     toc = TRUE,
#     toc_depth = 2,
#     toc_float = TRUE,
#     keep_md = TRUE,
#     self_contained = TRUE
#   ),
#   output_dir = "docs/"
#   
# )

# rmarkdown::render(
#   input = "1_code/05_excel_ratio_analysis.Rmd",
#   output_format = rmarkdown::html_document(
#     toc = TRUE,
#     toc_depth = 2,
#     toc_float = TRUE,
#     keep_md = TRUE,
#     self_contained = TRUE
#   ),
#   output_dir = "docs/"
#   
# )

# rmarkdown::render(
#   input = "1_code/05_excel_ratio_analysis.Rmd",
#   output_format = rmarkdown::html_document(
#     toc = TRUE,
#     toc_depth = 2,
#     toc_float = TRUE,
#     keep_md = TRUE,
#     self_contained = TRUE
#   ),
#   output_dir = "docs/"
#   
# )

# distill::create_website("docs/", "Test")
rmarkdown::render_site("docs/")
# rmarkdown::clean_site("docs/", preview = FALSE)
