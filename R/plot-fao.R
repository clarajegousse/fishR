#' Plot top captured species for a selected country
#'
#' @param data A data frame returned by `load_fao_capture()`.
#' @param country Country name in English, matching `Country_Name_En`.
#' @param year Year to plot.
#' @param n Number of top species to show.
#' @param fill Fill colour for bars.
#'
#' @return A ggplot object.
#' @export
plot_top_species_country <- function(data,
                                     country,
                                     year,
                                     n = 10,
                                     fill = "black") {

  required_cols <- c("Country_Name_En", "PERIOD", "Sp_Name_En", "VALUE")

  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.character(country) || length(country) != 1 || is.na(country)) {
    stop("`country` must be a single character string.", call. = FALSE)
  }

  if (!is.numeric(year) || length(year) != 1 || is.na(year)) {
    stop("`year` must be a single numeric value.", call. = FALSE)
  }

  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n <= 0) {
    stop("`n` must be a single positive number.", call. = FALSE)
  }

  data_plot <- data |>
    dplyr::filter(
      .data$Country_Name_En == country,
      .data$PERIOD == year,
      !is.na(.data$Sp_Name_En)
    ) |>
    dplyr::group_by(species = .data$Sp_Name_En) |>
    dplyr::summarise(
      total_tonn = sum(.data$VALUE, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::slice_max(.data$total_tonn, n = n, with_ties = FALSE)

  if (nrow(data_plot) == 0) {
    stop(
      "No data found for country = '", country,
      "' and year = ", year, ".",
      call. = FALSE
    )
  }

  ggplot2::ggplot(
    data_plot,
    ggplot2::aes(
      x = .data$total_tonn,
      y = forcats::fct_reorder(.data$species, .data$total_tonn)
    )
  ) +
    ggplot2::geom_col(fill = fill) +
    ggplot2::labs(
      title = paste("Top", n, "captured species in", country, "in", year),
      subtitle = "Total catch (tonnes)",
      x = "Catch (tonnes)",
      y = NULL,
      caption = "Source: FAO capture production data"
    )
}


#' Plot catch trend over time for a species in a country
#'
#' @param data A data frame returned by `load_fao_capture()`.
#' @param country Country name in English, matching `Country_Name_En`.
#' @param species Species name in English, matching `Sp_Name_En`.
#' @param facet Logical; if `TRUE` and multiple species are supplied, use
#'   faceted panels. If `FALSE`, overlay lines with colour. Ignored when
#'   a single species is supplied. Defaults to `FALSE`.
#' @param colour Line colour (single species) or palette start colour
#'   (multiple species). Defaults to `"black"`.
#'
#' @return A ggplot object.
#' @export
plot_species_trend <- function(data,
                               country,
                               species,
                               facet = FALSE,
                               colour = "black") {

  required_cols <- c("Country_Name_En", "PERIOD", "Sp_Name_En", "VALUE")

  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.character(country) || length(country) != 1 || is.na(country)) {
    stop("`country` must be a single character string.", call. = FALSE)
  }

  if (!is.character(species) || length(species) == 0 || anyNA(species)) {
    stop("`species` must be a character vector of at least one species name.",
         call. = FALSE)
  }

  if (!is.logical(facet) || length(facet) != 1) {
    stop("`facet` must be a single logical value (TRUE or FALSE).", call. = FALSE)
  }

  data_plot <- data |>
    dplyr::filter(
      .data$Country_Name_En == country,
      .data$Sp_Name_En %in% species,
      !is.na(.data$PERIOD),
      !is.na(.data$VALUE)
    ) |>
    dplyr::group_by(species = .data$Sp_Name_En, year = .data$PERIOD) |>
    dplyr::summarise(
      total_tonn = sum(.data$VALUE, na.rm = TRUE),
      .groups = "drop"
    )

  if (nrow(data_plot) == 0) {
    stop(
      "No data found for country = '", country,
      "' and species = ", paste(species, collapse = ", "), ".",
      call. = FALSE
    )
  }

  multi <- length(unique(data_plot$species)) > 1

  p <- ggplot2::ggplot(
    data_plot,
    ggplot2::aes(
      x = .data$year,
      y = .data$total_tonn,
      colour = if (multi && !facet) .data$species else NULL,
      group = .data$species
    )
  ) +
    ggplot2::geom_line(
      colour = if (!multi || facet) colour else NULL,
      linewidth = 0.8
    ) +
    ggplot2::geom_point(
      colour = if (!multi || facet) colour else NULL,
      size = 1.5
    ) +
    ggplot2::scale_y_continuous(labels = scales::label_comma()) +
    ggplot2::labs(
      title    = paste("Catch trend:", paste(species, collapse = ", ")),
      subtitle = country,
      x        = NULL,
      y        = "Catch (tonnes)",
      colour   = NULL,
      caption  = "Source: FAO capture production data"
    ) +
    ggplot2::theme(legend.position = "bottom")

  if (multi && facet) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$species), scales = "free_y")
  }

  p
}

#' Compare catch of a species across countries
#'
#' Produces either a bar chart (single year) or a line chart (time series)
#' comparing catches of one species across multiple countries. Countries can
#' be supplied explicitly or selected automatically as the top \code{n}
#' catching nations.
#'
#' @param data A data frame returned by `load_fao_capture()`.
#' @param species Species name in English, matching `Sp_Name_En`.
#' @param countries Character vector of country names to include. If `NULL`,
#'   the top \code{n} countries are selected automatically based on total
#'   catch over the period (or in \code{year} for single-year plots).
#' @param n Integer; number of top countries to show when \code{countries}
#'   is `NULL`. Ignored if \code{countries} is supplied. Defaults to `10`.
#' @param year Integer; if supplied, produces a bar chart for that year only.
#'   If `NULL`, produces a time series line chart across all available years.
#' @param facet Logical; if `TRUE` and a time series is plotted, use faceted
#'   panels instead of overlapping lines. Defaults to `FALSE`.
#'
#' @return A ggplot object.
#' @export
plot_species_country_comparison <- function(data,
                                            species,
                                            countries = NULL,
                                            n = 10,
                                            year = NULL,
                                            facet = FALSE) {

  required_cols <- c("Country_Name_En", "PERIOD", "Sp_Name_En", "VALUE")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.character(species) || length(species) != 1 || is.na(species)) {
    stop("`species` must be a single character string.", call. = FALSE)
  }

  if (!is.null(countries) && (!is.character(countries) || length(countries) == 0)) {
    stop("`countries` must be a character vector or NULL.", call. = FALSE)
  }

  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n <= 0) {
    stop("`n` must be a single positive number.", call. = FALSE)
  }

  if (!is.null(year) && (!is.numeric(year) || length(year) != 1 || is.na(year))) {
    stop("`year` must be a single numeric value or NULL.", call. = FALSE)
  }

  if (!is.logical(facet) || length(facet) != 1) {
    stop("`facet` must be a single logical value (TRUE or FALSE).", call. = FALSE)
  }

  # ---- filter to species (+ year if single-year mode) ----
  data_sp <- data |>
    dplyr::filter(
      .data$Sp_Name_En == species,
      !is.na(.data$Country_Name_En),
      !is.na(.data$VALUE)
    )

  if (!is.null(year)) {
    data_sp <- data_sp |> dplyr::filter(.data$PERIOD == year)
  }

  if (nrow(data_sp) == 0) {
    stop(
      "No data found for species = '", species, "'",
      if (!is.null(year)) paste0(" and year = ", year) else "",
      ".",
      call. = FALSE
    )
  }

  # ---- resolve country list ----
  if (is.null(countries)) {
    top_countries <- data_sp |>
      dplyr::group_by(.data$Country_Name_En) |>
      dplyr::summarise(total = sum(.data$VALUE, na.rm = TRUE), .groups = "drop") |>
      dplyr::slice_max(.data$total, n = n, with_ties = FALSE) |>
      dplyr::pull(.data$Country_Name_En)

    data_plot <- data_sp |>
      dplyr::filter(.data$Country_Name_En %in% top_countries)
  } else {
    missing_countries <- setdiff(countries, unique(data_sp$Country_Name_En))
    if (length(missing_countries) > 0) {
      warning(
        "The following countries were not found in the data and will be ignored: ",
        paste(missing_countries, collapse = ", "),
        call. = FALSE
      )
    }
    data_plot <- data_sp |>
      dplyr::filter(.data$Country_Name_En %in% countries)
  }

  data_plot <- data_plot |>
    dplyr::group_by(country = .data$Country_Name_En, year = .data$PERIOD) |>
    dplyr::summarise(
      total_tonn = sum(.data$VALUE, na.rm = TRUE),
      .groups = "drop"
    )

  if (nrow(data_plot) == 0) {
    stop("No data remaining after filtering countries.", call. = FALSE)
  }

  # ---- single-year bar chart ----
  if (!is.null(year)) {
    return(
      ggplot2::ggplot(
        data_plot,
        ggplot2::aes(
          x = .data$total_tonn,
          y = forcats::fct_reorder(.data$country, .data$total_tonn)
        )
      ) +
        ggplot2::geom_col(fill = "black") +
        ggplot2::scale_x_continuous(labels = scales::label_comma()) +
        ggplot2::labs(
          title    = paste("Catch of", species, "by country in", year),
          subtitle = if (is.null(countries)) paste("Top", n, "countries") else NULL,
          x        = "Catch (tonnes)",
          y        = NULL,
          caption  = "Source: FAO capture production data"
        )
    )
  }

  # ---- time series line chart ----
  p <- ggplot2::ggplot(
    data_plot,
    ggplot2::aes(
      x      = .data$year,
      y      = .data$total_tonn,
      colour = if (!facet) .data$country else NULL,
      group  = .data$country
    )
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_y_continuous(labels = scales::label_comma()) +
    ggplot2::labs(
      title    = paste("Catch of", species, "by country over time"),
      subtitle = if (is.null(countries)) paste("Top", n, "countries") else NULL,
      x        = NULL,
      y        = "Catch (tonnes)",
      colour   = NULL,
      caption  = "Source: FAO capture production data"
    ) +
    ggplot2::theme(legend.position = "bottom")

  if (facet) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$country), scales = "free_y")
  }

  p
}

#' Plot decadal average catch for a species in a country
#'
#' Aggregates catch data into decades and plots the average annual catch
#' per decade as a bar chart. Useful for identifying long-term trends
#' and structural shifts in catch levels.
#'
#' Decades are labelled by their starting year (e.g. 1990 = 1990--1999).
#' Incomplete decades (i.e. the current decade) are included but reflect
#' fewer years of data.
#'
#' @param data A data frame returned by `load_fao_capture()`.
#' @param country Country name in English, matching `Country_Name_En`.
#' @param species Species name in English, matching `Sp_Name_En`.
#' @param fill Fill colour for bars. Defaults to `"black"`.
#'
#' @return A ggplot object.
#' @export
plot_decadal_average <- function(data,
                                 country,
                                 species,
                                 fill = "black") {

  required_cols <- c("Country_Name_En", "PERIOD", "Sp_Name_En", "VALUE")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.character(country) || length(country) != 1 || is.na(country)) {
    stop("`country` must be a single character string.", call. = FALSE)
  }

  if (!is.character(species) || length(species) != 1 || is.na(species)) {
    stop("`species` must be a single character string.", call. = FALSE)
  }

  data_plot <- data |>
    dplyr::filter(
      .data$Country_Name_En == country,
      .data$Sp_Name_En == species,
      !is.na(.data$PERIOD),
      !is.na(.data$VALUE)
    ) |>
    dplyr::group_by(year = .data$PERIOD) |>
    dplyr::summarise(
      annual_catch = sum(.data$VALUE, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      decade = floor(.data$year / 10) * 10
    ) |>
    dplyr::group_by(.data$decade) |>
    dplyr::summarise(
      avg_catch  = mean(.data$annual_catch, na.rm = TRUE),
      n_years    = dplyr::n(),
      .groups    = "drop"
    ) |>
    dplyr::mutate(
      decade_label = paste0(.data$decade, "s")
    )

  if (nrow(data_plot) == 0) {
    stop(
      "No data found for country = '", country,
      "' and species = '", species, "'.",
      call. = FALSE
    )
  }

  ggplot2::ggplot(
    data_plot,
    ggplot2::aes(
      x = factor(.data$decade_label),
      y = .data$avg_catch
    )
  ) +
    ggplot2::geom_col(fill = fill) +
    ggplot2::scale_y_continuous(labels = scales::label_comma()) +
    ggplot2::labs(
      title    = paste("Decadal average catch:", species),
      subtitle = country,
      x        = NULL,
      y        = "Average annual catch (tonnes)",
      caption  = "Source: FAO capture production data"
    )
}
