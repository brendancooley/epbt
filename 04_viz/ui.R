source("params.R")

libs <- c('tidyverse', 'shiny')
ipak(libs)

tau_quantiles <- read_csv("tau_quantiles.csv")
icpBHTAgg <- read_csv("icpBHTAgg.csv")

ccodes <- tau_quantiles$j_iso3 %>% unique()

p_choices <- icpBHTAgg$Name %>% sort()

ui <- fluidPage(
  
  tags$head(tags$style(HTML(paste0("a {color: ", bcOrange, "}")))),
  tags$head(tags$style(HTML(paste0("a:hover {color: ", bcOrange, "}")))),
  
  # Application title
  h3("Estimating Policy Barriers to Trade: Results"),
  p("Brendan Cooley"),
  p("Ph.D. Candidate, Department of Politics, Princeton University"),
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
          p("Plot shows point estimates and 95% confidence interval for estimated policy barrier 
            imposed by/on selected country's imports/exports with trading partners. 
            An estimate of one is consistent with no policy barriers (free trade)."),
          p(strong("TR/MA"), " toggles showing the selected country's estimated ", em("trade restrictiveness,"), 
            "the effective taxes it imposes on its imports, and it's estimated ", em("market access,"),
            "the effective taxes imposed on its exports.")
        )
      )
    ),
    tabPanel("Policy Barriers (Economic Blocs)",
      p(),
      fluidRow(
        column(3,
          radioButtons("eud", "Disaggregate EU?", choices=c("Yes"="yes", "No"="no"), selected="no"),
          radioButtons("cluster", "Cluster?", choices=c("Yes"="yes", "No"="no"), selected="no"),
          uiOutput("K")
        ),
        column(6, plotOutput("hm")),
        column(3,
          p("Plot shows point estimates for policy barriers imposed by ", em("row"), 
            "on imports from ", em("column. ")),
          p(strong("Disaggregate EU "),
            "controls whether or not European Union countries should be aggregated into a single
            unit or not. "),
          p(strong("Cluster "), "controls whether or not countries should be clustered
            into economic blocs based on policy similarity (using k-means)."),
          p("If ", strong("Cluster "),
            "is ", em("yes "), "a numeric input box will appear, allowing the user to choose the 
            number of clusters (2-10).")
        )
      )
    ),
    tabPanel("Prices",
      p(),
      fluidRow(
        column(3, selectizeInput("p_categories", "Highlight Products:", p_choices, multiple=TRUE)),
        column(6, plotOutput("pricePlot")),
        column(3,
          p("Plot shows ICP-sampled price levels for tradable goods, 
            used to construct tradable price indices in the paper."),
          p(strong("Highlight Products"), "allows the user to
            and compare product-level prices across countries. 
            Countries ordered by estimated tradable price index (top: most expensive).")
        )
      )
    )
  )
)
