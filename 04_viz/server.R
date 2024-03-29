# NOTE: run doit prep_shiny before running to get update dependencies

shiny <- TRUE
source("params.R", local=TRUE)

library(tidyverse)
library(shiny)
library(countrycode)

tauHMY <- read_csv("tauHMY.csv")
tauHMYEUD <- read_csv("tauY.csv")

tau_quantiles <- read_csv("tau_quantiles.csv")
tau_quantiles_EUD <- read_csv("tau_quantiles_EUD.csv")
icpBHTAgg <- read_csv("icpBHTAgg.csv")
priceIndex <- read_csv("priceIndex.csv") %>% select(iso3, priceIndex)
colnames(priceIndex) <- c("ccode", "priceIndex")

icpBHTAgg <- icpBHTAgg %>% left_join(priceIndex)

pos <- position_jitter(height=.15, seed=5)
icpBHTreordered <- icpBHTAgg %>% filter(ccode != "USA") %>% arrange(priceIndex)
ints <- rep(1:length(unique(icpBHTreordered$ccode)), each=length(unique(icpBHTreordered$Name)))
icpBHTreordered$ccodeInt <- ints
icpBHTreordered$ccodeIntJit <- jitter(icpBHTreordered$ccodeInt, factor=.75)

highlight <- bcOrange
background <- "#77C3FA"
grid.col <- "#E8E8E8"

ccodes_base <- tau_quantiles$j_iso3 %>% unique()
ccodes_EUD <- tau_quantiles_EUD$j_iso3 %>% unique()

ccodes <- c(tau_quantiles$j_iso3, tau_quantiles_EUD$j_iso3) %>% unique()
ccodes_df <- data.frame(ccodes)
colnames(ccodes_df) <- c("iso3")
ccodes_df$country.name <- countrycode(ccodes_df$iso3, "iso3c", "country.name")
ccodes_df$country.name[ccodes_df$iso3=="EU"] <- "European Union"
ccodes_df$country.name[ccodes_df$iso3==ROWname] <- "Rest of World"
ccodes_df$country.name[ccodes_df$iso3=="MYSG"] <- "Malaysia/Singapore"
ccodes_df$country.name[ccodes_df$iso3=="BNL"] <- "Belgium/Netherlands/Luxembourg"
ccodes_df$country.name[ccodes_df$iso3=="ELL"] <- "Estonia/Latvia/Lithuania"

server <- function(input, output, session) {
  
  paper_link <- a("brendancooley.com/docs/epbt.pdf", href="brendancooley.com")
  output$web_link <- renderUI({
    tagList(web_link)
  })
  
  output$K <- renderUI({
    if (input$cluster=="yes") {
      out <- numericInput("K_val", "K:", 3, min=2, max=10, step=1)
    } else {
      out <- textOutput(" ")
    }
    out
  })
  
  ### BARRIERS (COUNTRY LEVEL) ###
  
  observeEvent(input$eud_pp, {
    if (input$eud_pp=="no") {
      ccodes_out <- ccodes_base
    } else {
      ccodes_out <- ccodes_EUD
    }
    updateSelectInput(session, "pbc_ccode", choices=ccodes_out, selected=input$pbc_ccode)
  })
  
  data_pbc <- reactive({
    if (input$eud_pp=="no") {
      tq_pbc <- tau_quantiles
    } else {
      tq_pbc <- tau_quantiles_EUD
    }
    if (input$trma=="tr") {
      out <- tq_pbc %>% filter(j_iso3==input$pbc_ccode)
      out$y <- out$i_iso3
    } else {
      out <- tq_pbc %>% filter(i_iso3==input$pbc_ccode)
      out$y <- out$j_iso3
    }
    out
  })
  
  plot_pbc_title <- reactive({
    if (input$trma=="tr") {
      out <- paste0("Importer: ", ccodes_df$country.name[ccodes_df$iso3==input$pbc_ccode])
    } else {
      out <- paste0("Exporter: ", ccodes_df$country.name[ccodes_df$iso3==input$pbc_ccode])
    }
    out
  })
  
  output$pbc_plot <- renderPlot({
    dpbc <- data_pbc() %>% mutate(y=fct_reorder(y, desc(q500)))
    dpbc %>% ggplot(aes(x=q500, y=y)) + 
      geom_point() +
      geom_segment(aes(x=q025, xend=q975, y=y, yend=y)) +
      geom_vline(xintercept=1, lty=2) +
      theme_classic() +
      theme(legend.position="none") +
      theme(panel.grid.major.x=element_line(c(2, 4, 6), color=grid.col),
            panel.grid.major.y=element_line(rev(levels(tau_quantiles$i_iso3)), color=grid.col)
      ) +
      labs(x="Policy Barrier", y="Trade Partner", title=plot_pbc_title())
  })
  
  ### HM ###
  
  output$hm <- renderPlot({
    EUHM <- ifelse(input$eud_hm=="yes", T, F)
    highlight <- NULL
    cluster <- ifelse(input$cluster=="yes", T, F)
    Kmeans <- KmeansEUD <- ifelse(is.null(input$K_val), 3, input$K_val)
    source("hm.R", local=T)
    hm
  })
    
  ### PRICES ###
  
  dataBackground <- reactive({
    icpBHTreordered %>% filter(!(icpBHTreordered$Name %in% input$p_categories))
  })
  
  dataHighlight <- reactive({
    icpBHTreordered %>% filter(icpBHTreordered$Name %in% input$p_categories)
  })
  
  output$pricePlot <- renderPlot({
    
    ggplot() +
      geom_vline(xintercept = 1, lty=2) +
      geom_point(data=dataBackground(), aes(x=pppReal, y=ccodeIntJit, size=expShareT), alpha=.25, fill=background,
                 color="black", pch=21) +
      geom_point(data=dataHighlight(), aes(x=pppReal, y=ccodeIntJit, size=expShareT), alpha=1, fill=highlight, 
                 color="black", pch=21) +
      scale_y_discrete(breaks=unique(icpBHTreordered$ccodeInt), labels=unique(icpBHTreordered$ccode), 
                       limits=seq(1, length(unique(icpBHTreordered$ccode)))) +
      scale_size_area() +
      lims(x=c(0,5)) +
      labs(title="Prices by Product", subtitle="Relative to United States (1). Data from World Bank, ICP. Size indicates consumers' relative expenditure.", x="Price Index", y="Country") +
      theme_classic() +
      guides(size=FALSE)
    
  })

}