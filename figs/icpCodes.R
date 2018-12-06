icpCodes <- read_csv("estimation/data/prices/icpCodes.csv") %>% filter(aggregate==0) %>% select(Series, tradable)

icpCodes$tchar <- ifelse(icpCodes$tradable == 1, "\\checkmark", "") 
icpCodes <- icpCodes %>% select(Series, tchar)
icpCodes$Series <- icpCodes$Series %>% strsplit(" ") %>% lapply(function(x) x[2:length(x)]) %>% lapply(paste, collapse=" ") %>% unlist()
colnames(icpCodes) <- c("Expenditure Category", "Tradable?")