#' Find a file in the extracted FAO capture dataset
#'
#' @param path Path to extracted FAO capture directory.
#' @param filename File name to locate.
#'
#' @return Full path to file.
#' @keywords internal
find_fao_capture_file <- function(path, filename) {
  file_path <- file.path(path, filename)

  if (!file.exists(file_path)) {
    stop("File not found: ", filename, call. = FALSE)
  }

  file_path
}

#' Drop non-English language columns from FAO lookup tables
#'
#' @param data A data frame.
#'
#' @return A data frame without Spanish, Russian, Arabic, Chinese,
#'   and French columns.
#' @keywords internal
drop_non_english_cols <- function(data) {
  data |>
    dplyr::select(
      -tidyselect::ends_with("_Es"),
      -tidyselect::ends_with("_Ru"),
      -tidyselect::ends_with("_Ar"),
      -tidyselect::ends_with("_Cn"),
      -tidyselect::ends_with("_Fr")
    )
}

#' Replace long FAO country names with short/common names
#'
#' Replaces verbose FAO country names in `Country_Name_En` with shorter,
#' commonly used equivalents (e.g. `"Russian Federation"` becomes
#' `"Russia"`). Countries not present in the internal lookup table are
#' left unchanged.
#'
#' Apply this function after `load_fao_capture()` if you want cleaner
#' country labels in plots and summaries. The original FAO name is not
#' preserved — if you need it, make a copy before calling this function.
#'
#' @param data A data frame returned by `load_fao_capture()`.
#'
#' @return The input data frame with `Country_Name_En` updated in place.
#' @export
clean_country_names <- function(data) {

  if (!"Country_Name_En" %in% names(data)) {
    stop(
      "Column 'Country_Name_En' not found. ",
      "Did you pass a data frame returned by `load_fao_capture()`?",
      call. = FALSE
    )
  }

  data |>
    dplyr::left_join(
      country_name_lookup,
      by = "Country_Name_En"
    ) |>
    dplyr::mutate(
      Country_Name_En = dplyr::coalesce(
        .data$Country_Name_Short,
        .data$Country_Name_En
      )
    ) |>
    dplyr::select(-"Country_Name_Short")
}

# Internal lookup table mapping FAO country names to short/common names.
# Add entries here as needed — names not in the table are returned unchanged.

country_name_lookup <- tibble::tribble(
  ~Country_Name_En,                                                         ~Country_Name_Short,

  # Long official names -> common short names
  "Union of Soviet Socialist Republics [former]",                            "USSR",
  "Russian Federation",                                                      "Russia",
  "United Kingdom of Great Britain and Northern Ireland",                    "UK",
  "United States of America",                                                "USA",
  "Republic of Korea",                                                       "South Korea",
  "Democratic People's Republic of Korea",                                   "North Korea",
  "Iran (Islamic Republic of)",                                              "Iran",
  "Taiwan Province of China",                                                "Taiwan",
  "Bolivia (Plurinational State of)",                                        "Bolivia",
  "Venezuela (Bolivarian Republic of)",                                      "Venezuela",
  "Viet Nam",                                                                "Vietnam",
  "Syrian Arab Republic",                                                    "Syria",
  "Lao People's Democratic Republic",                                        "Laos",
  "Libyan Arab Jamahiriya",                                                  "Libya",
  "Tanzania, United Republic of",                                            "Tanzania",
  "Congo, Democratic Republic of the",                                       "DR Congo",
  "Côte d'Ivoire",                                                           "Ivory Coast",
  "China, Hong Kong SAR",                                                    "Hong Kong",
  "China, Macao SAR",                                                        "Macao",
  "China, mainland",                                                         "China",
  "Micronesia (Federated States of)",                                        "Micronesia",
  "Saint Vincent and the Grenadines",                                        "St Vincent",
  "Saint Kitts and Nevis",                                                   "St Kitts & Nevis",
  "Saint Lucia",                                                             "St Lucia",
  "Trinidad and Tobago",                                                     "Trinidad & Tobago",
  "Antigua and Barbuda",                                                     "Antigua & Barbuda",
  "Bosnia and Herzegovina",                                                  "Bosnia & Herzegovina",
  "São Tomé and Príncipe",                                                   "São Tomé & Príncipe",
  "Papua New Guinea",                                                        "Papua New Guinea",
  "Solomon Islands",                                                         "Solomon Islands",
  "Netherlands Antilles",                                                    "Netherlands Antilles",
  "United Arab Emirates",                                                    "UAE",
  "Czech Republic",                                                          "Czechia",
  "Republic of Moldova",                                                     "Moldova",
  "North Macedonia",                                                         "North Macedonia",
  "Wallis and Futuna Islands",                                               "Wallis & Futuna"
)
