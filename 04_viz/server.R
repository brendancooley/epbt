source("../01_code/params.R")

libs <- c('tidyverse', 'shiny', 'countrycode')
ipak(libs)

tau_quantiles <- read_csv(tau_quantiles_path)
icpBHTAgg <- read_csv(paste0(cleandir, "icpBHTAgg.csv"))
priceIndex <- read_csv(paste0(cleandir, "priceIndex.csv")) %>% select(iso3, priceIndex)
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

ccodes <- tau_quantiles$j_iso3 %>% unique()
ccodes_df <- data.frame(ccodes)
colnames(ccodes_df) <- c("iso3")
ccodes_df$country.name <- countrycode(ccodes_df$iso3, "iso3c", "country.name")
ccodes_df$country.name[ccodes_df$iso3=="EU"] <- "European Union"
ccodes_df$country.name[ccodes_df$iso3==ROWname] <- "Rest of World"
ccodes_df$country.name[ccodes_df$iso3=="MYSG"] <- "Malaysia/Singapore"

tq_test <- tau_quantiles %>% filter(j_iso3=="AUS")
fct_reorder(tq_test$i_iso3, tq_test$q500)

server <- function(input, output) {
  
  paper_link <- a("brendancooley.com/docs/epbt.pdf", href="brendancooley.com")
  output$web_link <- renderUI({
    tagList(web_link)
  })
  
  ### BARRIERS (COUNTRY LEVEL) ###
  
  data_pbc <- reactive({
    if (input$trma=="tr") {
      out <- tau_quantiles %>% filter(j_iso3==input$pbc_ccode)
      out$y <- out$i_iso3
    } else {
      out <- tau_quantiles %>% filter(i_iso3==input$pbc_ccode)
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
