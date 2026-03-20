#' Download FAO capture production dataset
#'
#' Downloads the FAO capture production ZIP file and extracts it to a
#' user data directory.
#'
#' @param path Directory where data should be stored. If `NULL`,
#'   a user cache directory is used.
#' @param overwrite Logical; overwrite existing extracted files.
#'
#' @return Invisibly returns the path to the extracted directory.
#' @export
download_fao_capture <- function(path = NULL, overwrite = FALSE) {

  # TODO: make URL version dynamic (e.g. parameterised `version`)
  # Current version hardcoded to ensure reproducibility
  url <- "https://www.fao.org/fishery/static/Data/Capture_2025.1.0.zip"

  if (is.null(path)) {
    path <- tools::R_user_dir("fishr", which = "data")
  }

  dir.create(path, recursive = TRUE, showWarnings = FALSE)

  zip_path <- file.path(path, "Capture_2025.1.0.zip")
  extract_dir <- file.path(path, "Capture_2025.1.0")

  if (dir.exists(extract_dir) && !overwrite) {
    message("Data already available at: ", extract_dir)
    return(invisible(extract_dir))
  }

  utils::download.file(url, destfile = zip_path, mode = "wb")

  if (!file.exists(zip_path) || file.info(zip_path)$size == 0) {
    stop("Download failed or produced an empty ZIP file.", call. = FALSE)
  }

  if (dir.exists(extract_dir)) {
    unlink(extract_dir, recursive = TRUE)
  }

  dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
  utils::unzip(zip_path, exdir = extract_dir)

  extracted_files <- list.files(extract_dir, recursive = TRUE, full.names = TRUE)

  if (length(extracted_files) == 0) {
    stop("ZIP extraction failed: no files found in extracted directory.", call. = FALSE)
  }

  invisible(extract_dir)
}
