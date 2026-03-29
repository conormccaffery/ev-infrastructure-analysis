---
title: "Optimizing EV Charging Infastructure at California Cinemas"
author: "Conor McCaffery"
date: "`r Sys.Date()`"
output:
  html_document:
    theme: flatly
    toc: true
    toc_float: true
---

```{r setup, include = FALSE}
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
```

## Introduction
My goal for this project is to answer the following question:  "Based on current EV registrations, demographic income, and existing infrastructure, which 50 zip codes present the most underserved and profitable markets for new charging station development?"
Electric vehicles are a very interesting technological breakthrough. The demand continues to be high, EVs made up over 20% of new global car sales in 2025. The expansion in market share is attributed to lower battery costs, greater charging infrastructure, and government incentives. For the purposes of this project, I am going to focus on the US market. 

I examined three datasets and wrote a join statement to match the data by zip code. Dataset 1 has the locations of alternative fueling stations, dataset 2 shows California EV registrations by zip code, and dataset 3 should contain the median income by ZIP code.

Finding the third dataset proved to be a challenge. I looked at complex census bureau data and IRS AGI data by zip code. To identify the answer to maximizing revenue and charging station, utilization, I had to find data that showcases user behavior. Census data has income bracket percentages. However, I assume that people in this bracket invest in private charging solutions. The most frequent users of EV chargers are those who typically live in apartments, have long commutes, and drivers with frequent long-distance trips. ZIP codes with high housing densities and large EV markets will have the highest utilizations. Another consideration is the type of commercial locations to install EV chargers. Companies like to install chargers in high-activity areas where people are present for long periods. Examples include cinemas, shopping malls, and other retail centers.

After some careful research, I decided to find data focused on commercial density and potential points of interest because it is the best fit for analyzing more ZIP code data and examining charging station ratios. Consumer behavior factors are more important than income data for the purposes of this report. I discovered a tool called OverPass Turbo, which shows real-time mapping data. I thought it would be great to map commercial areas like theaters, shopping malls, and supermarkets. The query request was too much for the system to process. I felt that focusing on potential theater locations would make this report more authentic, given my knowledge as an AMC associate.

## Process
I now need to choose what type of join function is most applicable. It should be beneficial to do an outer join so I keep enough columns. Every table has a zip code component as a primary key. 
I renamed every column related to zip code as zip_code so that there is a standardized primary key. For my electric vehicle registration zip code data, I am filtering it to only show vehicles that are plug-in hybrid or electric battery types. 

Some data cleaning steps were especially challenging. In my California cinemas dataset, some theater locations do not have a zip code because Overpass Turbo is a crowd-source platform. I intend to keep the unclean data because it has the location cities and states. This will be helpful for creating a mapping component to show potential user insights.


## Executive Summary
The spatial aggregation of DMV vehicle registrations and alternative fueling data reveals a stark infrastructure gap in California. While EV adoption is highly concentrated in specific zip codes, commercial entertainment venues—specifically cinemas, which offer the ideal 2-to-3 hour customer dwell time for Level 2 charging—are vastly underserved. This analysis identifies localized monopolies where early infrastructure investors can capture high-value, captive audiences.

## Methodology
This project utilizes a local ETL pipeline. Raw CSV data containing EV registrations, existing charging stations, and theater coordinates were ingested into a local **SQLite data warehouse**

** Data Validation:**
Information for the California cinema dataset comes from Overpass Turbo, a crowd-source platform where addresses are manually entered by the community. 
Crowd-sourced spatial data often contains anomalies. Initial data exploration revealed missing geographic tags for major flagship locations, such as AMC Mercado 20 in Santa Clara. Local market knowledge was applied to manually impute the missing zip code prior to SQL aggregation, ensuring targets were accurately captured.

```{r data-pipeline, results='hide'}
setwd("C:/Users/conor/Downloads/Datasets")
library(dplyr)

#Dataset 1: Alternative Fueling Stations Data 
ca_ev_data <- read.csv("C:\\Users\\conor\\Downloads\\Datasets\\alt_fuel_stations_ca.csv")
head(ca_ev_data)
colnames(ca_ev_data)


#cols_to_keep <- c("City","State","EV.Network","ZIP","EV.Pricing","Funding.Sources")
ca_df <- select(ca_ev_data,City,State,EV.Network,ZIP,EV.Pricing,Funding.Sources)
ca_df <- rename(ca_df,zip_code = ZIP)
```
```{r}
#Dataset 2: 2025 EV Registrations by Zip Code
ev_zip_data <- read.csv("C:\\Users\\conor\\Downloads\\Datasets\\vehicle-fuel-type-counts-2024.csv")
ev_zip_data <- select(ev_zip_data,-Date)
clean_ev_data <- subset(ev_zip_data, Fuel == 'Battery Electric' | Fuel == 'Plug-in Hybrid')
clean_ev_data <- rename(clean_ev_data,zip_code=ZIP.Code)
```
```{r}
# Dataset 3: Points of Interest
# Preparing to do a join on zip code
ca_cinemas <- read.delim("C:\\Users\\conor\\Downloads\\Datasets\\california_cinemas.csv",sep = "\t")
ca_cinemas <- ca_cinemas %>% rename(lat=1,long=2,zip_code=3)
ca_cinemas <- ca_cinemas %>% select(lat,long,zip_code,name) #dropping the amenity column

# Data Imputation: Fixing known errors, I discovered a missing local cinema
ca_cinemas <- ca_cinemas %>% mutate(zip_code = ifelse(grepl("Mercado",name, ignore.case = TRUE), "95054", zip_code ))
```

```{r}
# Database Architecture and SQL Execution
library(DBI)
library(RSQLite)
# Creating a temporary SQLite database 
con <- dbConnect(RSQLite::SQLite(), "ev_market_database.sqlite")

# Putting the three clean datasets into SQL database as tables
dbWriteTable(con, "chargers", ca_df,overwrite = TRUE)
dbWriteTable(con, "EVs", clean_ev_data, overwrite = TRUE)
dbWriteTable(con, "cinemas", ca_cinemas, overwrite = TRUE)

# Reading external SQL file in my PC
sql_query <- readLines("ev_market_aggregation.sql")
sql_query <- paste(sql_query, collapse = "\n")

ranked_opportunities <- dbGetQuery(con, sql_query)
dbDisconnect(con)
```
The opportunity Score metric was calculated as 'Total EVs / (Existing Chargers + 1)'. The top three highest-value targets for immediate infrastructure expansion are:
1. **Orinda, East Bay (94563):** 3,130 registered EVs sharing zero public charging stations. A pure local monopoly,
2. **San Francisco - Castro (94114):** 2,662 registered EVs with zero existing public stations in a dense, parking-constrained neighborhood
3. **San Francisco - West Portal (94127):** 1,981 EVs with zero chargers, representing a massive suburban-urban foothold.
```{r}
head(ranked_opportunities,15)

## Analyze
After the master data table is created, the purpose of this phase is to search for zip codes with addressable markets. I do this by calculating an opportunity score that represents the ratio of electric vehicles to charging stations. The zip codes with the highest opportunity scores show the most promising locations to invest in. For example, the highest opportunity score is 3130. This means there is 3130 vehicles competing over every charging station in that zip code. It also means the cinema in that area is looking to capture that market potential.I noticed that the first three areas in the opportunity score rankings have no electric vehicle charging stations near a cinema. Any company that can build a charging station at these locations can capitalize on market potential. In addition, there are some areas with a high volume of EV chargers. For example, the zip code 92677 corresponds to 14 charging stations. It is likely that the area is overwhelmed, and a cinema can benefit from charging infrastructure.

As expected, after creating a map, we can visually confirm that the Bay Area has the highest potential opportunity score. There are 295 observations in the map, and 4 of them are above the lower score bracket.
I cannot find a data point for one of my local cinemas in Santa Clara. This indicates a flaw in the data. I corrected it by performing a data imputation step to manually add a zip code. After looking at the map, I was surprised to see that the Los Angeles area is not included in the high end of the range. This is despite Los Angeles having one of the highest concentrations of electric vehicles in the United States. 

I eventually decided to make a duplicate of my Rstudio script so I can implement a SQL file into the project. 


```
##Strategic Mapping

```{r mapping, out.width='100%', echo=TRUE}
library(leaflet)
library(RColorBrewer)

cinema_map_data <- ca_cinemas %>% 
  filter(!is.na(lat) & !is.na(long) & zip_code != "") %>%
  left_join(ranked_opportunities, by = "zip_code")
  
cinema_map_data <- cinema_map_data %>% filter(lat >= 32.5 & lat <= 42.0, 
                                              long >= -124.5 & long <= -114.0)
# California Coordinates are positioned approximately between these values above.

# A source for the mapping error before cleaning comes from dataset 2 which tracks vehicle registrations, it might be common for people with California registrations to move to nearby states.
any(!startsWith(cinema_map_data$zip_code,"9"))
#California zip codes always start with 9
cinema_map_data <- cinema_map_data %>% filter(substr(zip_code,start = 1, stop = 1) == "9")

opportunity_score_palette <- colorNumeric(
  palette = "YlGn",
  domain = cinema_map_data$opportunity_score)

ev_strategy_map <- leaflet(data = cinema_map_data) %>% 
  # Map Layer 1
  addProviderTiles(providers$CartoDB.Positron) %>% 
  # Map Layer 2
  addCircleMarkers(
    lng = ~long,
    lat = ~lat,
    fillColor = ~opportunity_score_palette(opportunity_score),
    color = "black",
    radius = 8,
    fillOpacity = 0.8,
    stroke = FALSE,
    
    # Map Layer 3
    popup = ~paste(
      "<b>Theater:</b>", name, "<br>",
      "<b>Zip Code:</b>", zip_code, "<br>",
      "<b>Total EVs:</b>", total_evs, "<br>",
      "<b>Existing Chargers:</b>", total_chargers, "<br>",
      "<b>Opportunity Score:</b>", round(opportunity_score, 0)
    )
  ) %>%
  # Map Layer 4
  addLegend(
    position = "bottomright",
    pal = opportunity_score_palette,
    values = ~opportunity_score,
    title = "EV Opportunity Score",
    opacity = 1
  )
```

```{r}
ev_strategy_map
```
## Key Findings

While electric vehicle adoption is heavily concentrated into specific zip codes, cinemas are areas of high consumer activity that can be further capitalized on. In this project, I had to ensure I could correct the raw data when necessary. For example, I had to include my local theater in the master data table. Based on the map, the majority of California cinemas have an opportunity score of approximately 500. The few locations with a high opportunity score are concentrated in the Bay Area, specifically San Francisco and Berkeley. 

## Recommendations
The top three zip codes should be prioritized. The highest opportunity score is located in Orinda. There are 3130 registered electric vehicles but no public charging stations. This sets up a prime opportunity to capture that market. Other considerations should be made regarding parking lot capacity, electrical grid access, and property management partnership viability in order to successfully implement strategic initiatives. 
