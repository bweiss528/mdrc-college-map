# MDRC Postsecondary RCT Interactive Study Locations Map

> **Built by Benjamin Weiss · Independent Research Project · 2026**

[![Live App](https://img.shields.io/badge/Live%20App-shinyapps.io-1a3a5c?style=for-the-badge)](https://benweiss.shinyapps.io/mdrc-college-map/)

An interactive R Shiny web application mapping 63 U.S. colleges and universities included in MDRC postsecondary randomized controlled trials (RCTs), featuring dynamic filtering, clickable institution profiles, demographic charts, and IPEDS urbanicity color-coding.

---

## 📊 Project Stats

| Metric | Value |
|--------|-------|
| Institutions Mapped | 63 |
| Study Programs | 33 |
| U.S. States Covered | 16 |
| Data Source | MDRC / IPEDS / Google Maps |

---

## 🗺️ Live Demo

**[→ Open the App](https://benweiss.shinyapps.io/mdrc-college-map/)**

---

## 1. Project Overview

This project is a fully interactive web application built in R and deployed publicly via shinyapps.io. It visualizes the geographic locations of 63 U.S. colleges and universities where MDRC — a nonprofit nonpartisan education and social policy research organization — has conducted postsecondary randomized controlled trials (RCTs).

The application was developed independently as a portfolio project to demonstrate skills in data wrangling, geospatial visualization, interactive web application development, and research communication. It was built with no prior experience in R or Shiny.

---

## 2. Data Sources

### Primary Source — MDRC RCT Database
The core dataset is a structured Excel database of MDRC postsecondary randomized controlled trials, compiled from publicly available MDRC research reports. Each record includes:

- Study program name and full title
- Institutions where the study was conducted
- Intervention components (financial support, advising, tutoring, instructional reform, learning communities, FT/summer enrollment promotion, success courses)
- Sample size and baseline demographic characteristics (gender, race/ethnicity, age)
- Summary of implementation and impact findings
- Links to published MDRC reports

### Geographic Coordinates — Google Maps
Coordinates (latitude and longitude) were obtained for each of the 63 institutions directly from Google Maps and manually verified against each institution's known address.

### Urbanicity Classification — IPEDS
Urbanicity classifications were obtained from the IPEDS College Navigator (NCES). Institutions are classified as:

- 🔵 **Urban** — City: Large, Midsize, or Small
- 🟡 **Suburban** — Suburb: Large, Midsize, or Small
- 🟢 **Town** — Town: Fringe, Distant, or Remote
- 🔴 **Rural** — Rural: Fringe, Distant, or Remote

---

## 3. Application Features

### Interactive Map
- 63 college markers **color-coded by IPEDS urbanicity**
- Markers scale in size as you zoom in and out
- Clicking any marker opens a full **institution profile popup**
- Map restricted to the continental United States
- Urbanicity legend displayed in the bottom-right corner

### Institution Profile Popups
Each popup contains a complete profile for every study conducted at that institution:
- Full program name, description, and duration
- Key statistics: total students, number of sites, program length
- **Demographic bar charts** for gender, race/ethnicity, and age
- Binary indicators for all seven program components
- Implementation and impact findings summaries
- Links to published MDRC reports

### Filtering System
- **Filter by State** — all 16 states represented
- **Filter by Study Program** — all 33 individual programs
- **Filter by Degree Level** — Associate's vs. Bachelor's
- **Filter by Urbanicity** — Urban, Suburban, Town, or Rural
- **Filter by Program Components** — 7 checkboxes for each intervention type
- **Reset All Filters** button

### Institution Table
- Searchable, paginated table of all displayed institutions
- Clicking a row **flies the map to that college** and highlights it with a red ring
- Clicking the map background removes the highlight and resets the view

---

## 4. Technical Stack

| Tool | Purpose |
|------|---------|
| **R** (v4.6.0) | Primary programming language |
| **Shiny** | Interactive web application framework |
| **Leaflet** | Interactive map rendering |
| **dplyr** | Data filtering and transformation |
| **DT** | Searchable, paginated data tables |
| **readxl** | Excel data import |
| **CartoDB Positron** | Clean light-gray basemap tiles |
| **shinyapps.io** | Cloud deployment and hosting |
| **Microsoft Excel** | Single source of truth for all college data |

---

## 5. Key Design Decisions

**Excel as data source** — Separating data from code means the map can be updated (new colleges, corrected coordinates, revised program details) without modifying the R script.

**Verified coordinates** — Each institution's coordinates were obtained directly from Google Maps and verified visually, ensuring dots land on or near the actual campus.

**Reactive filtering** — All seven filters operate simultaneously and update the map, marker count, and table in real time without any page reload.

**Click-to-fly navigation** — Clicking any row in the institution table animates the map to that college and displays a red highlight ring.

---

## 6. Known Limitations

- Report links for some programs point to general MDRC publication pages rather than specific PDFs
- Demographic data for SUCCESS, Montana 10, and MMA is drawn from a single published report
- Montana 10 college-level data is based on institutional information, not site-specific study records
- The free tier of shinyapps.io allows 25 active hours per month

---

## 7. File Structure

```
mdrc-college-map/
├── college_map_app_final.R          # Main Shiny application
├── RCT_Database_Task5_Coordinates.xlsx  # All college data and coordinates
└── MDRC_Map_README.docx             # Full methodology documentation (Word)
```

---

## 8. How to Run Locally

1. Install R and RStudio
2. Install required packages:
```r
install.packages(c("shiny", "leaflet", "dplyr", "DT", "readxl"))
```
3. Place both `college_map_app_final.R` and `RCT_Database_Task5_Coordinates.xlsx` in the same folder
4. Open the R file in RStudio and run:
```r
setwd("path/to/your/folder")
shiny::runApp("college_map_app_final.R")
```

---

*Developed by Benjamin Weiss · 2026 · [benweiss.shinyapps.io/mdrc-college-map](https://benweiss.shinyapps.io/mdrc-college-map/)*
