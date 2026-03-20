
# fishr

An R package for downloading, cleaning, and visualising FAO global
capture fisheries data.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("https://github.com/clarajegousse/fishR")
```

## Overview

`fishr` wraps the [FAO Global Capture Production
dataset](https://www.fao.org/fisheries/en/) with a small set of
functions to get you from raw data to analysis-ready tibbles and plots
with minimal friction.

| Function | What it does |
|----|----|
| `download_fao_capture()` | Downloads and extracts the FAO capture ZIP to a local cache |
| `load_fao_capture()` | Reads and joins quantity, country, species, and area tables |
| `plot_top_species_country()` | Bar chart of top *n* species for a country in a given year |
| `plot_species_trend()` | Time series of catch for one or more species in a country |
| `plot_species_country_comparison()` | Compare catch of one species across countries (snapshot or trend) |

## Usage

### Download and load data

``` r
library(fishR)

# Downloads to a user cache directory; skips if already present
data_dir <- download_fao_capture()
```

``` r
# Returns a joined tibble ready for analysis
data <- load_fao_capture(path = data_dir)
```

### Top species in a country (single year)

``` r
plot_top_species_country(
  data    = data,
  country = "Iceland",
  year    = 2023,
  n       = 10
)
```

![](README_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

### Catch trend over time (single species)

``` r
plot_species_trend(
  data    = data,
  country = "Iceland",
  species = "Atlantic cod"
)
```

![](README_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

### Catch trend — multiple species, overlapping lines

``` r
plot_species_trend(
  data    = data,
  country = "Iceland",
  species = c("Atlantic cod", "Capelin", "Atlantic herring"),
  facet   = FALSE
)
```

    ## Warning in ggplot2::geom_line(colour = if (!multi || facet) colour else NULL, : Ignoring empty aesthetic:
    ## `colour`.

    ## Warning in ggplot2::geom_point(colour = if (!multi || facet) colour else NULL, : Ignoring empty aesthetic:
    ## `colour`.

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

### Catch trend — multiple species, faceted panels

Useful when species have very different catch magnitudes.

``` r
plot_species_trend(
  data    = data,
  country = "Iceland",
  species = c("Atlantic cod", "Capelin", "Atlantic herring"),
  facet   = TRUE
)
```

![](README_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

### Compare catch across countries

``` r
# Bar chart — top 10 countries for a species in a single year
plot_species_country_comparison(
  data    = data,
  species = "Atlantic cod",
  year    = 2023
)
```

![](README_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

``` r
# Bar chart — specific countries only
plot_species_country_comparison(
  data      = data,
  species   = "Atlantic cod",
  countries = c("Iceland", "Norway", "Canada"),
  year      = 2023
)
```

![](README_files/figure-gfm/unnamed-chunk-6-2.png)<!-- -->

``` r
# Time series — top 5 countries, overlapping lines
plot_species_country_comparison(
  data    = data,
  species = "Atlantic cod",
  n       = 5
)
```

![](README_files/figure-gfm/unnamed-chunk-6-3.png)<!-- -->

``` r
# Time series — specific countries, faceted panels
plot_species_country_comparison(
  data      = data,
  species   = "Atlantic cod",
  countries = c("Iceland", "Norway", "Canada"),
  facet     = TRUE
)
```

![](README_files/figure-gfm/unnamed-chunk-6-4.png)<!-- -->

## Data source

FAO ({{year}}). *Global Capture Production*. Fisheries and Aquaculture
Division. Available at:
<https://www.fao.org/fishery/en/collection/capture>

## Status

Early development — functions and data structure may change between
versions.
