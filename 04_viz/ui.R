source("../01_code/params.R")

libs <- c('tidyverse', 'shiny')
ipak(libs)

tau_quantiles <- read_csv(tau_quantiles_path)
icpBHTAgg <- read_csv(paste0(cleandir, "icpBHTAgg.csv"))

ccodes <- tau_quantiles$j_iso3 %>% unique()

p_choices <- icpBHTAgg$Name %>% sort()

ui <- fluidPage(
  
  # Application title
  h3("Estimating Policy Barriers to Trade: Results"),
  p("Brendan Cooley, Ph.D. Candidate, Department of Politics, Princeton University"),
  p(icon("file-pdf", lib="font-awesome"), a(" Paper", href="http://brendancooley.com/docs/epbt.pdf"),
    HTML("&emsp;"),
    icon("github", lib="font-awesome"), a(" Code", href="https://github.com/brendancooley/epbt"),
    HTML("&emsp;"),
    icon("table", lib="font-awesome"), a(" Data", href="https://raw.githubusercontent.com/brendancooley/epbt/master/02_results/tau_quantiles.csv"),
    HTML("&emsp;"),
    icon("envelope", lib="font-awesome"), "bcooley (at) princeton.edu"),
  
  tabsetPanel(
    
    tabPanel("Policy Barriers (Country-Level)",
      p(),
      fluidRow(
        column(3, 
          radioButtons("trma", "TR/MA:", choices=c("Trade Restrictiveness"="tr", "Market Access"="ma")),
          selectInput("pbc_ccode", "Choose Country:", choices=ccodes, selected="USA")
        ),
        column(6, plotOutput("pbc_plot")),
        column(3,
          p("Notes go here")
        )
      )
    ),
    tabPanel("Policy Barriers (Economic Blocs)",
      fluidRow(
        
      )
    ),
    tabPanel("Prices",
      fluidRow(
        column(3, selectizeInput("p_categories", "Highlight Products:", p_choices, multiple=TRUE)),
        column(9, plotOutput("pricePlot"))
      )
    )
  )
)
