# Japan codes manually cleaned and saved in public dropbox: http://www.customs.go.jp/toukei/sankou/code/country_e.htm
# BACI documentation: http://www.cepii.fr/PDF_PUB/wp/2010/wp2010-23.pdf
  # flows reported in FOB values, but they are sometimes imputed using gravity type regression
  # errors here shouldn't be a big deal, because I have independent cost data
# NZ data mannually requested from http://archive.stats.govt.nz/infoshare/TradeVariables.aspx?DataType=TIM
# Chile data sent from Central Bank, CIF/FOB sheets extracted from excel file and saved in public Dropbox

# Eurostat queries
# by country 0004: http://epp.eurostat.ec.europa.eu/newxtweb/getquery.do?queryID=100899378&queryName=/0004hs2bycountry&datasetID=DS-043327&keepsessionkey=true
# by country 0509: http://epp.eurostat.ec.europa.eu/newxtweb/getquery.do?queryID=100899462&queryName=/0509hs2bycountry&datasetID=DS-043327&keepsessionkey=true 
# by country 1012: http://epp.eurostat.ec.europa.eu/newxtweb/getquery.do?queryID=100899468&queryName=/1012hs2bycountry&datasetID=DS-043327&keepsessionkey=true

### TO-DOs ###

# Set parameters (e.g. year, directory names in txt file and source)
# verify HS system (BACI=1992, OECD=1988)
# formal COMEXT API query: https://ec.europa.eu/eurostat/documents/6842948/0/Easy+Comext+User+Guide/8bbee520-3d18-48eb-b222-6dfc21d2b52b

### Data Availability

# BACI: 1995-2016
# WIOD (2013 release): 1995-2011 
# WIOD (2016 release): 2000-2014
# SGP: 1995-2011
# OECD mtc: 1991-2007
# OECD iots: 1995-2011
# US: 1989-2017
# NZ: 1988-2017
# Japan: 1988-2018 (mode shares)
# Brazil: 1997-2018
# EU: 2000-2012 (bug in eurostat for 2013-2014)
# Chile: 2003-2017

### SETUP ###

# source helpers and get parameters
source("params.R")

libs <- c('tidyverse', 'OECD', 'readstata13', 'R.utils', 'openxlsx', 'googleway', 'revgeo', 'wbstats')
ipak(libs)

### setup directory system and get codebooks ###
mkdir(datadir)

# output dirs
wiotdir <- paste0(datadir, "wiot/")
mkdir(wiotdir)

### Add other IOTS
iotsdir <- paste0(datadir, "iots/")
mkdir(iotsdir)

ccodesOECD <- c("ARG", "CHL", "COL", "ISR", "MYS", "NZL", "PER", "PHL", "SGP", "THA", "VNM", "ZAF")

for (i in ccodesOECD) {
  idir <- paste0(iotsdir, i, "/")
  mkdir(idir)
}


# flows dirs
bacidir <- paste0(datadir, 'flows/')
mkdir(bacidir)

# modes dirs
mdir <- paste0(datadir, "modes/")
mkdir(mdir)

usdir <- paste0(mdir, "us/")
mkdir(usdir)

jpndir <- paste0(mdir, "jpn/")
mkdir(jpndir)

bradir <- paste0(mdir, 'bra/')
mkdir(bradir)

eudir <- paste0(mdir, "eu/")
mkdir(eudir)

# price dirs
pdir <- paste0(datadir, "prices/")
mkdir(pdir)

# baci codes
codesurl <- "http://www.cepii.fr/DATA_DOWNLOAD/baci/country_code_baci02.csv"
bacicodes <- read_csv(codesurl)
bacicodespath <- paste0(bacidir, "codes.csv")
checkwritecsv(bacicodes, bacicodespath)

# transport codes
uscodes <- read_delim("https://www.census.gov/foreign-trade/schedules/c/country.txt", "|", skip=5, col_names = FALSE)
uscodes <- uscodes[1:241, ]  # drop trailing footnotes
colnames(uscodes) <- c("code", "name", "iso2")
uscodespath <- paste0(usdir, "codes.csv")
checkwritecsv(uscodes, uscodespath)

bratcodes <- read_delim('http://www.mdic.gov.br/balanca/bd/tabelas/VIA.csv', ";")
bratcodespath <- paste0(bradir, "tcodes.csv")
checkwritecsv(bratcodes, bratcodespath)

braccodes <- read_delim("http://www.mdic.gov.br/balanca/bd/tabelas/PAIS.csv", ";")
braccodespath <- paste0(bradir, "ccodes.csv")
checkwritecsv(braccodes, braccodespath)

brancmcodes <- read_delim("http://www.mdic.gov.br/balanca/bd/tabelas/NCM.csv", ";", col_types = list(CO_ISIC4=col_character(), CO_CUCI_ITEM=col_character(), CO_NCM=col_character(), CO_SH6=col_character()))
brancmcodespath <- paste0(bradir, "ncmcodes.csv")
checkwritecsv(brancmcodes, brancmcodespath)

jpncodesurl <- "https://www.dropbox.com/s/dakuwqza6aluhoa/codes.csv?dl=1"
jpncodes <- read_csv(jpncodesurl)
jpncodespath <- paste0(jpndir, "codes.csv")
checkwritecsv(jpncodes, jpncodespath)

# get WIOT
wtempdir <- datadir
wioturl <- "http://www.wiod.org/protected3/data13/update_sep12/wiot/wiot_stata_sep12.zip"
temp <- tempfile()
download.file(wioturl, temp)
unzip(temp, exdir=wtempdir)
wiot <- read.dta13(paste0(wtempdir, "wiot_full.dta"))
file.remove(paste0(wtempdir, "wiot_full.dta"))
file.remove(paste0(wtempdir, "stata_13_to_12_10.pdf"))

# get EU mode shares
eumodes0004url <- "https://www.dropbox.com/s/2a41t24x6poyx08/20002004.csv?dl=1"
eumodes0509url <- "https://www.dropbox.com/s/7xo273hbvnmphht/20052009.csv?dl=1"
eumodes1012url <- "https://www.dropbox.com/s/3wa1oi573vwy7xe/20102012.csv?dl=1"

eumodes0004 <- read_csv(eumodes0004url, col_types = list(INDICATOR_VALUE=col_double()))
eumodes0004$year <- substring(as.character(eumodes0004$PERIOD), 1 ,4) %>% as.integer()

eumodes0509 <- read_csv(eumodes0509url, col_types = list(INDICATOR_VALUE=col_double()))
eumodes0509$year <- substring(as.character(eumodes0509$PERIOD), 1 ,4) %>% as.integer()

eumodes1012 <- read_csv(eumodes1012url, col_types = list(INDICATOR_VALUE=col_double()))
eumodes1012$year <- substring(as.character(eumodes1012$PERIOD), 1 ,4) %>% as.integer()

dfs <- list(eumodes0004, eumodes0509, eumodes1012)
eumodes <- bind_rows(dfs)

# NZ temp dir
nzFiles <- "https://www.dropbox.com/sh/mvutu6bhps0lzm1/AADQfIkBkJK1m8-xI8ET84VWa?dl=1"
nzTemp <- tempfile()
download.file(nzFiles, nzTemp)
unzip(nzTemp, exdir="nzTemp")

# Chile raw data
chlFOB <- read_csv('https://www.dropbox.com/s/rfsfks12pc3o010/chileFOB.csv?dl=1')
chlCIF <- read_csv('https://www.dropbox.com/s/x5fj6vubg7zmqrh/chileCIF.csv?dl=1')

# get annual data
for (i in seq(startY, endY, 1)) {
  
  y <- i
  print(y)
  
  ### WIOT ###
  
  # 2016 release version
  # wiotY <- getWIOT(period=year, format='long', as.DT = FALSE) %>% as_tibble()

  wiotpath <- paste0(wiotdir, y, ".csv")
  
  # 1995-1999
  if (y %in% seq(1995, 2011)) {
    if (!file.exists(wiotpath)) {
      wiotY <- wiot %>% filter(year==y)
      write_csv(wiotY, wiotpath)
    }
  }
  
  # wiotpath2016 <- paste0(wiotdir, y, "_v2016", ".csv")
  # 
  # # 2000-2014
  # if (y %in% seq(2000, 2014)){
  #   if (!file.exists(wiotpath2016)) {
  #     wiotY <- getWIOT(period=y, format='long', as.DT = FALSE) %>% as_tibble()
  #     write_csv(wiotY, wiotpath2016)
  #   }
  # }
  
  # if (!file.exists(wiotpath)) {
  #   wiotY <- wiot %>% filter(year==y)
  #   checkwritecsv(wiotY, wiotpath)
  # }
  
  # IOTS from OECD
  for (i in ccodesOECD) {
    
    iotpath <- paste0(iotsdir, i, "/", y, ".csv")
    
    if (!file.exists(iotpath)) {
      
      iotsFilter <- paste0("TTL.", i, ".TTL_C01T05+TTL_C10T14+TTL_C15T16+TTL_C17T19+TTL_C20+TTL_C21T22+TTL_C23+TTL_C24+TTL_C25+TTL_C26+TTL_C27+TTL_C28+TTL_C29+TTL_C30T33X+TTL_C31+TTL_C34+TTL_C35+TTL_C36T37+TTL_C40T41+TTL_C45+TTL_C50T52+TTL_C55+TTL_C60T63+TTL_C64+TTL_C65T67+TTL_C70+TTL_C71+TTL_C72+TTL_C73T74+TTL_C75+TTL_C80+TTL_C85+TTL_C90T93+TTL_C95+DOM_C01T05+DOM_C10T14+DOM_C15T16+DOM_C17T19+DOM_C20+DOM_C21T22+DOM_C23+DOM_C24+DOM_C25+DOM_C26+DOM_C27+DOM_C28+DOM_C29+DOM_C30T33X+DOM_C31+DOM_C34+DOM_C35+DOM_C36T37+DOM_C40T41+DOM_C45+DOM_C50T52+DOM_C55+DOM_C60T63+DOM_C64+DOM_C65T67+DOM_C70+DOM_C71+DOM_C72+DOM_C73T74+DOM_C75+DOM_C80+DOM_C85+DOM_C90T93+DOM_C95+IMP_C01T05+IMP_C10T14+IMP_C15T16+IMP_C17T19+IMP_C20+IMP_C21T22+IMP_C23+IMP_C24+IMP_C25+IMP_C26+IMP_C27+IMP_C28+IMP_C29+IMP_C30T33X+IMP_C31+IMP_C34+IMP_C35+IMP_C36T37+IMP_C40T41+IMP_C45+IMP_C50T52+IMP_C55+IMP_C60T63+IMP_C64+IMP_C65T67+IMP_C70+IMP_C71+IMP_C72+IMP_C73T74+IMP_C75+IMP_C80+IMP_C85+IMP_C90T93+IMP_C95+TXS_INT_FNL+TTL_INT_FNL+VALU+LABR+OTXS+GOPS+CFC+NOPS+OUTPUT+TOTAL+CTOTAL+DISC.C01T05+C10T14+C15T16+C17T19+C20+C21T22+C23+C24+C25+C26+C27+C28+C29+C30T33X+C31+C34+C35+C36T37+C40T41+C45+C50T52+C55+C60T63+C64+C65T67+C70+C71+C72+C73T74+C75+C80+C85+C90T93+C95+HFCE+NPISH+GGFC+GFCF+INVNT+CONS_ABR+CONS_NONRES+EXPO+IMPO+ICESHR")
      
      iot <- get_dataset("IOTS",
                         filter = iotsFilter, 
                         start_time = y,
                         end_time = y,
                         pre_formatted = TRUE)
      
      write_csv(iot, iotpath)
      
    }
    
  }
  
  
  ### TRADE FLOWS ###
  
  # use HS92
  flowsorigin <- paste0("baci92_", y)
  flowspath <- paste0(bacidir, y, ".csv")
  
  # get flows data from baci
  if (!file.exists(flowspath)) {
    baciYurl <- paste0("http://www.cepii.fr/DATA_DOWNLOAD/baci/", flowsorigin, ".zip")
    temp <- tempfile()
    download.file(baciYurl, temp)
    originpath <- paste0(bacidir, flowsorigin, ".csv")
    unzip(temp, exdir=bacidir)
    file.rename(originpath, flowspath)
  }
  
  ### TRANSPORT COSTS AND MODES ###
  
  ### United States
  year2d <- substring(as.character(y), 3, 4)
  year2d <- ifelse(year2d > 88, year2d, paste0("1", year2d))

  usorigin <- paste0("imp_detl_yearly_", year2d, "n")
  uspath <- paste0(usdir, y, ".csv")
  
  # note: 2009-2011 have different structure
  if (!file.exists(uspath)) {
    usYurl <- paste0("http://faculty.som.yale.edu/peterschott/files/research/data/", usorigin, ".zip")
    temp <- tempfile()
    download.file(usYurl, temp)
    unzip(temp, exdir=usdir)
    
    usmodes <- read.dta13(paste0(usdir, usorigin, ".dta"))
    if (y >= 2009) {
      usmodes$scommodity <- ifelse(nchar(as.character(usmodes$commodity)) < 10, paste0(0, usmodes$commodity), as.character(usmodes$commodity))
    }
    write_csv(usmodes, uspath)
    
    originpath <- paste0(usdir, usorigin, ".dta")
    file.remove(originpath)
  }
  
  ### Japan
  
  jpnmodes <- list()
  
  # make new directory for each year
  jpnydir <- paste0(jpndir, y, "/")
  
  if (!dir.exists(jpnydir)) {
    
    mkdir(jpnydir)
    
    tick <- 1
    
    base <- "https://www.e-stat.go.jp/"
    
    # jpn air cargo
    jpnairurl <- paste0(base, "en/stat-search/files?page=1&layout=datalist&toukei=00350300&tstat=000001013142&cycle=1&year=", y, "0&month=24101212&tclass1=000001013205&tclass2=000001013207")
    jpnairpg <- readLines(jpnairurl)
    for (i in jpnairpg) {
      if (grepl("file-download", i) & grepl("fileKind=1", i)) {
        line <- scan(text=i, what="character", quiet=T)
        url <-  substring(line[2], 8, nchar(line[2]) - 1)
        jpnmodes[[tick]] <- read_csv(paste0(base, url), col_types = list(`Quantity1-Year`=col_double(), `Quantity2-Year`=col_double()))
        checkwritecsv(jpnmodes[[tick]], paste0(jpnydir, "air", tick, ".csv"))
        tick <- tick + 1
      }
    }
    
    # jpn sea cargo
    jpnseaurl <- paste0(base, "en/stat-search/files?page=1&layout=datalist&toukei=00350300&tstat=000001013142&cycle=1&year=", y, "0&month=24101212&tclass1=000001013217&tclass2=000001013219")
    jpnseapg <- readLines(jpnseaurl)
    for (i in jpnseapg) {
      if (grepl("file-download", i) & grepl("fileKind=1", i)) {
        line <- scan(text=i, what="character", quiet=T)
        url <-  substring(line[2], 8, nchar(line[2]) - 1)
        jpnmodes[[tick]] <- read_csv(paste0(base, url), col_types = list(`Quantity1-Year`=col_double(), `Quantity2-Year`=col_double()))
        checkwritecsv(jpnmodes[[tick]], paste0(jpnydir, "sea", tick, ".csv"))
        tick <- tick + 1
      }
    }
  }
  
  ### European Union
  euypath <- paste0(eudir, y, ".csv")
  
  if (!file.exists(euypath)) {
    if (y %in% unique(eumodes$year)) {
      
      eumodesY <- eumodes %>% filter(year == y)
      
      if (nrow(eumodesY) > 0) {
        checkwritecsv(eumodesY, euypath)
      }
    }
  }
  
  ### Brazil
  brapath <- paste0(bradir, y, ".csv")
  if (!file.exists(brapath)) {
    if (y >= 1997) {
      bramodesurl <- paste0("http://www.mdic.gov.br/balanca/bd/comexstat-bd/ncm/IMP_", y, ".csv")
      bramodes <- read_delim(bramodesurl, ";")
      checkwritecsv(bramodes, brapath)
    }
  }
  
  ### New Zealand
  nzdir <- paste0(datadir, "nz/")
  mkdir(nzdir)
  nzypath <- paste0(nzdir, y, ".csv")
  
  if (!file.exists(nzypath)) {
    # parsing failures ok, just problems with trailing metadata
    nzY <- read_csv(paste0("nzTemp/", y, ".csv"), skip=1)
    nzY <- nzY[!(rowSums(is.na(nzY))==6), ]  # drop trailing metadata
    colnames(nzY) <- c("year", "cname", "hsname", "quantity", "cif", "vfd")
    nzYclean <- fill(nzY, year, cname, .direction="down")
    write_csv(nzYclean, nzypath)
  }
  
  ### Chile
  chldir <- paste0(datadir, "chl/")
  mkdir(chldir)
  chlypath <- paste0(chldir, y, ".csv")
  
  if (!file.exists(chlypath)) {
    if (y %in% seq(2003, 2017)) {
      fobY <- chlFOB %>% select(Importer, as.character(y))
      cifY <- chlCIF %>% select(Importer, as.character(y))
      
      chlY <- left_join(fobY, cifY, by="Importer")
      colnames(chlY) <- c("Importer", "fob", "cif")
      
      write_csv(chlY, chlypath)
    }
  }
  
}

# drop nz temp dir
unlink("nzTemp", recursive = TRUE)

### DISTANCES ###
distdir <- paste0(datadir, "dists/")
mkdir(distdir)

cepiidist <- read.dta13("http://www.cepii.fr/distance/dist_cepii.dta") %>% as_tibble()
cepiidistpath <- paste0(distdir, "dist_cepii.csv")
checkwritecsv(cepiidist, cepiidistpath)

cepiigeo <- read.dta13("http://www.cepii.fr/distance/geo_cepii.dta") %>% as_tibble()
cepiigeopath <- paste0(distdir, "geo_cepii.csv")
checkwritecsv(cepiigeo, cepiigeopath)

seadist <- read.dta13("https://zenodo.org/record/46822/files/CERDI-seadistance.dta?download=1") %>% as_tibble()
seadistpath <- paste0(distdir, "CERDI-seadistance.csv")
checkwritecsv(seadist, seadistpath)


### MARITIME TRANSPORT COSTS ###
# note: pinging oecd takes a while
mtcdir <- paste0(datadir, "mtc/")
mkdir(mtcdir)

# # OECD API version
# mtcfilters <- "AUS+JPN+KOR+MEX+NZL+USA+EU15+NMEC+DZA+ARG+BGD+BOL+BRA+CHN+COL+ECU+EGY+HKG+IND+IDN+IRN+JOR+LBY+MYS+MAR+PAK+PRY+PER+PHL+RUS+SAU+SGP+ZAF+LKA+SDN+TWN+THA+TUN+ARE+URY+VEN+VNM+YEM.AUS+CAN+CHL+CZE+HUN+ISL+ISR+JPN+KOR+LVA+LTU+MEX+NZL+NOR+POL+SVK+SVN+CHE+TUR+USA+EU15+NMEC+AFG+ALB+DZA+ASM+AND+AGO+AIA+ATA+ATG+ARG+ARM+ABW+AZE+BHS+BHR+BGD+BRB+BLR+BLZ+BEN+BMU+BTN+BOL+BIH+BWA+BRA+IOT+VGB+BRN+BGR+BFA+BDI+KHM+CMR+CPV+CYM+CAF+TCD+CHN+CXR+CCK+COL+COM+COG+COD+COK+CRI+CIV+HRV+CUB+CYP+DJI+DMA+DOM+ECU+EGY+SLV+GNQ+ERI+EST+ETH+FRO+FLK+FJI+GUF+PYF+ATF+GAB+GMB+GEO+GHA+GIB+GRL+GRD+GLP+GUM+GTM+GIN+GNB+GUY+HTI+VAT+HND+HKG+IND+IDN+IRN+IRQ+JAM+JOR+KAZ+KEN+PRK+KIR+KWT+KGZ+LAO+LBN+LSO+LBR+LBY+LIE+MAC+MKD+MDG+MWI+MYS+MDV+MLI+MLT+MHL+MTQ+MRT+MUS+MYT+FSM+MDA+MCO+MNG+MNE+MSR+MAR+MOZ+MMR+NAM+NRU+NPL+ANT+NCL+NIC+NER+NGA+NIU+NFK+MNP+OMN+PAK+PLW+PAN+PNG+PRY+PER+PHL+PCN+PRI+QAT+REU+ROU+RUS+RWA+SHN+KNA+LCA+SPM+VCT+WSM+SMR+STP+SAU+SEN+SCG+SRB+SYC+SLE+SGP+SLB+SOM+ZAF+LKA+SDN+SUR+SWZ+SYR+TWN+TJK+TZA+THA+TLS+TGO+TKL+TON+TTO+TUN+TKM+TCA+TUV+UGA+UKR+ARE+UMI+URY+UZB+VUT+VEN+VNM+VIR+WLF+YEM+ZMB+ZWE+FRME+CSK+YUG+GRPS+ESH+XXX.1+2+3+4.1+2+3+0.TR_COST+TR_UNIT+TR_ADVA.01+02+03+04+05+06+07+08+09+10+11+12+13+14+15+16+17+18+19+20+21+22+23+24+25+26+27+28+29+30+31+32+33+34+35+36+37+38+39+40+41+42+43+44+45+46+47+48+49+50+51+52+53+54+55+56+57+58+59+60+61+62+63+64+65+66+67+68+69+70+71+72+73+74+75+76+78+79+80+81+82+83+84+85+86+87+88+89+90+91+92+93+94+95+96+97+99"
# 
# mtc <- get_dataset("MTC", 
#                    filter = mtcfilters, 
#                    start_time = 2003,
#                    end_time = 2007,
#                    pre_formatted=TRUE)

# Cooley dropbox version
# url: https://stats.oecd.org/Index.aspx?DataSetCode=MTC#
mtcurl <- "https://www.dropbox.com/s/n9uuy1lpuqyxbn7/mtc.csv?dl=1"
mtc <- read_csv(mtcurl)

mtcpath <- paste0(mtcdir, "mtc.csv")
checkwritecsv(mtc, mtcpath)

### PROTECTION ###

# tariff barriers

# macmap
tardir <- paste0(datadir, "tar/")
mkdir(tardir)

mmap2001url <- "http://www.cepii.fr/DATA_DOWNLOAD/macmap/download/mmhs2_2001.zip"
mmap2004url <- "http://www.cepii.fr/DATA_DOWNLOAD/macmap/download/mmhs2_2004.zip"
mmap2007url <- "http://www.cepii.fr/DATA_DOWNLOAD/macmap/download/mmhs2_2007.zip"

mmap <- list(mmap2001url, mmap2004url, mmap2007url)
years <- c(2001, 2004, 2007)

for (i in 1:length(mmap)) {
  url <- mmap[[i]]
  y <- years[i]
  temp <- tempfile()
  download.file(url, temp)
  unzip(temp, exdir=tardir)
  file.rename(paste0(tardir, "mmhs2_", y, ".txt"), paste0(tardir, y, ".txt"))
  file.remove(paste0(tardir, "README_MMHS2.txt"))
}

# unctad tariffs (2011)
unctad2011url <- "https://www.dropbox.com/s/o1k0rgd3nrm2amt/wtar2011.csv?dl=1"
unctad2011 <- read_csv(unctad2011url)
unctad2011 <- unctad2011[seq(1, nrow(unctad2011) - 5), ] # drop trailing rows

write_csv(unctad2011, paste0(tardir, "2011.csv"))

# non tariff measures
ntmdir <- paste0(datadir, "ntm/")
mkdir(ntmdir)

file <- "ntm_hs6_2016_cleanV12.dta"
zip <- "ntm_hs6_2016_cleanV12.zip"
url <- paste0("http://trains.unctad.org/content/", zip)
temp <- tempfile()
download.file(url, temp)
unzip(temp, exdir=ntmdir)
ntm <- read.dta13(paste0(ntmdir, file))
write_csv(ntm, paste0(ntmdir, "ntm.csv"))
file.remove(paste0(ntmdir, file))

# preferential trade agreements
ptadir <- paste0(datadir, "pta/")
mkdir(ptadir)

url <- "https://www.designoftradeagreements.org/media/filer_public/86/0b/860befbd-f984-4dd9-8ea1-1e5c2c2de1b0/list_of_treaties_dyadic_01_03.csv"
pta <- read_csv(url, col_types=list(number=col_character()))
write_csv(pta, paste0(ptadir, "pta.csv"))

### PRICES ###

# ICP 2005
url <- "https://www.dropbox.com/s/2pju94ivpurcwc6/icp2005.csv?dl=1"
icp2005 <- read_csv(url, col_types = list(`Classification Code`=col_character()))

# drop last five trailing rows
trailS <- nrow(icp2005) - 5
icp2005 <- icp2005[1:trailS, ]
icp2005[nrow(icp2005), ]

write_csv(icp2005, paste0(pdir, "prices2005ICP.csv"))

# ICP 2011
url <- "https://www.dropbox.com/s/or248s7k3avz5ea/icp2011.csv?dl=1"
icp2011 <- read_csv(url)

# drop last five trailing rows
trailS <- nrow(icp2011) - 5
icp2011 <- icp2011[1:trailS, ]
icp2011[nrow(icp2011), ]

write_csv(icp2011, paste0(pdir, "prices2011ICP.csv"))

# ICP codes
url <- "https://www.dropbox.com/s/7icpsfxtc7gavfj/icpCodes.csv?dl=1"
icpCodes <- read_csv(url)

write_csv(icpCodes, paste0(pdir, "icpCodes.csv"))

# EIU Consumer Expenditure
conExpFname <- "conExp.xlsx"
url <- 'https://www.dropbox.com/s/m9v656x2ey6ews0/cons_exp.xlsx?dl=1'
download.file(url, conExpFname)

ceSheetNames <- getSheetNames(conExpFname)
ceClean <- list()

tick <- 1
years <- seq(1990, 2017) %>% as.character()
for (i in ceSheetNames) {
  sheet <- read.xlsx(conExpFname, sheet=i, rows=seq(4,14)) %>% as_tibble()
  sheet$iso2 <- i
  sheet[ , years] <- sheet[ , years] %>% mutate_all(function(x) as.numeric(as.character(x)))
  ceClean[[tick]] <- sheet
  tick <- tick + 1
}

conExp <- bind_rows(ceClean)
file.remove(conExpFname)
write_csv(conExp, paste0(pdir, "conexpEIU.csv"))

# EIU City Prices
url1 <- 'https://www.dropbox.com/s/8ziuoy0uarpvez0/prices9004.xlsx?dl=1'
url2 <- 'https://www.dropbox.com/s/1fimkkms858cxen/prices0518.xlsx?dl=1'
pricesFname1 <- "prices9004.xlsx"
pricesFname2 <- "prices0518.xlsx"
download.file(url1, pricesFname1)
download.file(url2, pricesFname2)

pricesSheetNames1 <- getSheetNames(pricesFname1)
pricesSheetNames2 <- getSheetNames(pricesFname2)
pricesL1 <- list()
pricesL2 <- list()

extractPrices <- function(sheetSet, sheetName, years) {
  
  # extract city name and code country
  cityNameRow <- read.xlsx(sheetSet, sheet=sheetName, rows=3, colNames = FALSE)
  cityNameSplit <- cityNameRow[ , 2] %>% strsplit(" \\(")
  city <- cityNameSplit[[1]][1]
  country <- cityNameSplit[[1]][2] %>% substring(1, 2)
  
  # coordinate version
  # cityCoords <- geocode(city, source="dsk")
  # address <- revgeo(cityCoords$lon, cityCoords$lat) %>% as.character()
  # country <- strsplit(address, ", ")[[1]][length(strsplit(address, ", ")[[1]])]
  
  # get data
  sheet <- read.xlsx(sheetSet, sheet=sheetName, rows=seq(4, 331))
  sheet[ , years] <- sheet[ , years] %>% mutate_all(function(x) as.numeric(as.character(x)))
  sheet$iso2 <- country
  sheet$city <- city
  return(sheet)
}

tick <- 1
for (i in pricesSheetNames1) {
  years <- seq(1990, 2004) %>% as.character()
  sheet <- extractPrices(pricesFname1, i, years)
  pricesL1[[tick]] <- sheet
  tick <- tick + 1
}
tick <- 1
for (i in pricesSheetNames2) {
  years <- seq(2005, 2018) %>% as.character()
  sheet <- extractPrices(pricesFname2, i, years)
  pricesL2[[tick]] <- sheet
  tick <- tick + 1
}

prices1 <- bind_rows(pricesL1) %>% as_tibble()
prices2 <- bind_rows(pricesL2) %>% as_tibble()

prices2 <- prices2 %>% select(-one_of(c("Long.name", "Source", "Series.name", "Unit")))

prices <- left_join(prices1, prices2)

file.remove(pricesFname1)
file.remove(pricesFname2)

write_csv(prices, paste0(pdir, "pricesEIU.csv"))

# get price categories
tcodesurl <- "https://www.dropbox.com/s/lpelo7biuekpo1z/tradable_codes.txt?dl=1"
ntcodesurl <- "https://www.dropbox.com/s/go9w457amrdu8cz/nontradable_codes.txt?dl=1"
ocodesurl <- "https://www.dropbox.com/s/oo45pfqlqzr6rm9/other_codes.txt?dl=1"

download.file(tcodesurl, paste0(pdir, "tradable_codes.txt"))
download.file(ntcodesurl, paste0(pdir, "nontradable_codes.txt"))
download.file(ocodesurl, paste0(pdir, "other_codes.txt"))

### POPULATION ###

# pop <- wb(country='countries_only', indicator="SP.POP.TOTL", 
#            startdate=startY, enddate=endY, return_wide = TRUE, POSIXct = TRUE) %>% as_tibble()
# pop <- pop %>% select(iso3c, date, SP.POP.TOTL)
# colnames(pop) <- c("iso3", "year", "pop")
# write_csv(pop, paste0(datadir, "pop.csv"))
