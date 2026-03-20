#' Load and clean FAO capture production data
#'
#' Reads the FAO capture quantity file and joins country, species,
#' and water area lookup tables.
#'
#' @param path Path to extracted FAO capture directory. If `NULL`,
#'   the data are downloaded or retrieved from the default cache.
#'
#' @return A tibble with cleaned and joined FAO capture data.
#' @export
load_fao_capture <- function(path = NULL) {
  if (is.null(path)) {
    path <- download_fao_capture()
  }

  qty_file     <- find_fao_capture_file(path, "Capture_Quantity.csv")
  country_file <- find_fao_capture_file(path, "CL_FI_COUNTRY_GROUPS.csv")
  species_file <- find_fao_capture_file(path, "CL_FI_SPECIES_GROUPS.csv")
  area_file    <- find_fao_capture_file(path, "CL_FI_WATERAREA_GROUPS.csv")

  data_qty <- readr::read_csv(qty_file, show_col_types = FALSE)

  data_country <- readr::read_csv(country_file, show_col_types = FALSE) |>
    drop_non_english_cols() |>
    dplyr::rename(Country_Name_En = Name_En, Country_Identifier = Identifier)

  data_sp <- readr::read_csv(species_file, show_col_types = FALSE) |>
    drop_non_english_cols() |>
    dplyr::rename(
      Sp_Name_En = Name_En,
      Sp_Scientific_Name = Scientific_Name,
      Sp_Identifier = Identifier
    )

  data_area <- readr::read_csv(area_file, show_col_types = FALSE) |>
    drop_non_english_cols()

  data_qty |>
    dplyr::left_join(data_country, by = c("COUNTRY.UN_CODE" = "UN_Code")) |>
    dplyr::left_join(data_sp, by = c("SPECIES.ALPHA_3_CODE" = "3A_Code")) |>
    dplyr::left_join(data_area, by = c("AREA.CODE" = "Code"))
}
