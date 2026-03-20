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
