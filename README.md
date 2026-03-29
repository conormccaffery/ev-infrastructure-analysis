# EV Charging Infrastructure Optimization: California Cinemas

**Tech Stack:** R, SQLite, SQL (CTEs, Joins, Aggregations), Leaflet (Spatial Mapping)

## Project Overview
This project identifies highly profitable, underserved markets for Level 2 Electric Vehicle (EV) charging station deployment. By analyzing EV registration density against existing public charging infrastructure, the objective is to locate "localized monopolies"—specifically targeting commercial movie theaters, which offer the ideal 2-to-3 hour customer dwell time required for Level 2 charging.

## Data Architecture & ETL Pipeline
Rather than relying solely on in-memory dataframe manipulations, this project simulates an enterprise workflow utilizing a local **Extract, Transform, Load (ETL)** pipeline:
1. **Extract:** Ingested raw CSV data from the California Energy Commission (existing chargers), DMV records (EV registrations), and crowd-sourced spatial coordinates (cinema locations).
2. **Transform:** Cleaned spatial anomalies (dropping out-of-state coordinates) and applied manual data imputation. *Note: Crowd-sourced data initially missed major flagship locations (e.g., AMC Mercado 20). Local market validation was used to impute the missing zip code prior to database ingestion.*
3. **Load:** Pushed the cleaned dataframes into a local **SQLite Data Warehouse**. 
4. **Aggregate:** Executed an external `.sql` script utilizing Common Table Expressions (CTEs) and `LEFT JOIN`s to calculate the final Supply/Demand KPI matrix.

## The Opportunity Index (KPI)
The core metric used to rank zip codes is the **Opportunity Score**, calculated natively in SQL:
`Total EVs / (Existing Chargers + 1)`
*(Note: A constant of +1 was added to the denominator to prevent division-by-zero errors in zero-infrastructure markets).*

## Key Findings: Top 3 Target Markets
The spatial aggregation revealed several high-value "zero-competition" zones:
* **Orinda (94563):** 3,130 registered EVs sharing 0 public charging stations. A pure local monopoly.
* **San Francisco - Castro (94114):** 2,662 registered EVs with 0 existing public stations in a dense, parking-constrained neighborhood.
* **San Francisco - West Portal (94127):** 1,981 EVs with 0 chargers, representing a massive suburban-urban foothold.

## How to Run This Project
1. Clone this repository to your local machine.
2. Ensure you have the `dplyr`, `DBI`, `RSQLite`, and `leaflet` packages installed in R.
3. Run the `ev_market_analysis.R` script. The script will automatically connect to the local SQLite database, execute the SQL query, and generate the interactive Leaflet map in your viewer.
