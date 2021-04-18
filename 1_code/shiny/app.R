library(shiny); library(shinyWidgets); library(tidyverse)
options(shiny.autoreload = TRUE) 

.path_data <- "data/firm_ratios.rds"
tab_data <- read_rds(.path_data)
firms_ <- unique(tab_data[["doc_id"]])
industry_ <- c("ALL", unique(tab_data[["industry"]]))
ratios_ <- unique(tab_data[["Ratio"]])


ui <- fluidPage(
  title = "Ratio Analysis",
  sidebarLayout(
    sidebarPanel(
      width = 3,
      pickerInput("pI_firms", "Firms", firms_, multiple = TRUE, selected = firms_[1], 
                  options = list(`actions-box` = TRUE, liveSearch = TRUE, size = 5)),
      pickerInput("pI_industry", "Industry", industry_, selected = NULL,
                  options = list(`actions-box` = TRUE, `liveSearch` = TRUE, size = 5)),
      radioGroupButtons(
        inputId = "rGB_ratio",
        label = "Ratios", 
        choices = ratios_,
        justified = TRUE,
        direction = "vertical"
      )
    ),
    mainPanel(
      h2("Ratio Analysis"),
      htmlOutput("hO_industry"),
      plotOutput("pO_time_series")
    )
  )
)

server <- function(input, output, session) {
  observeEvent({input$pI_industry}, {
    if (!input$pI_industry == "ALL") {
      .choices <- tab_data %>%
        filter(industry %in% input[["pI_industry"]]) %>%
        pull(doc_id) %>%
        unique()
      updatePickerInput(session, "pI_firms", "Firms", .choices[1], .choices)
    }
   
  })
  
  r_data <- reactive({
    tab_data %>%
      filter(doc_id %in% input[["pI_firms"]])
  })

  r_plot <- reactive({
    r_data() %>%
      filter(Ratio == input[["rGB_ratio"]]) %>%
      ggplot(aes(year, value, group = doc_id, color = doc_id)) + 
      geom_line(size = 1) + 
      geom_point(size = 4, shape = 18) + 
      facet_wrap(~ doc_id) + 
      theme_bw() + 
      scale_x_discrete(breaks = c(2011, 2015, 2019)) + 
      theme(legend.position = "none")
  })
  
  output[["pO_time_series"]] <- renderPlot(r_plot())
  output[["hO_industry"]] <- function() {
    paste0(strong("Industry: "), input$pI_industry)
  }
  
  
}

shinyApp(ui, server)