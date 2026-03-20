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
                                     fill = "#0a4875") {

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
    ) +
    ggplot2::theme_minimal()
}
