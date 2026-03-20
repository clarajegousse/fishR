#' Download FAO capture production dataset (ZIP) and extract
#'
#' @param path Directory where data should be stored. Defaults to user data dir.
#' @param overwrite Logical; overwrite existing files.
#'
#' @return Invisibly returns the path to the extracted directory.
#' @export
download_fao_capture <- function(path = NULL, overwrite = FALSE) {

  # TODO: make URL version dynamic (e.g. parameterised `version`)
  # Current version hardcoded to ensure reproducibility
  url <- "https://www.fao.org/fishery/static/Data/Capture_2025.1.0.zip"

  # ---- define storage ----
  if (is.null(path)) {
    path <- tools::R_user_dir("fishr", which = "data")
  }

  dir.create(path, recursive = TRUE, showWarnings = FALSE)

  zip_path <- file.path(path, "capture.zip")
  extract_dir <- file.path(path, "capture")

  # ---- skip if already exists ----
  if (dir.exists(extract_dir) && !overwrite) {
    message("Data already available at: ", extract_dir)
    return(invisible(extract_dir))
  }

  # ---- download ----
  utils::download.file(url, destfile = zip_path, mode = "wb")

  # ---- extract ----
  if (dir.exists(extract_dir)) {
    unlink(extract_dir, recursive = TRUE)
  }

  dir.create(extract_dir, showWarnings = FALSE)

  utils::unzip(zip_path, exdir = extract_dir)

  invisible(extract_dir)
}
