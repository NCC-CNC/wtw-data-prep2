#' Convert object to ASCII characters
#'
#' Convert any characters in an object to only contain ASCII characters.
#'
#' @param x Object (e.g. `list` or `character` vector).
#'
#' @return Object.
#'
#' @noRd
enc2ascii <- function(x) {
  if (inherits(x, "character")) {
    iconv(enc2utf8(x), from = "utf-8", to = "ascii", sub = "")
  } else if (inherits(x, "list")) {
    lapply(x, enc2ascii)
  } else {
    x
  }
}