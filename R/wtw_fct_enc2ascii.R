#' Convert object to ASCII characters
#'
#' Convert characters in an object to ASCII. Special characters (e.g. accented
#' characters such as \code{é}, \code{è}, \code{ç}, \code{ê}, \code{ù},
#' \code{ì}) are transliterated to their closest ASCII equivalents using ICU
#' rules. Any remaining non-ASCII characters are stripped.
#'
#' @param x Object (e.g. `list` or `character` vector).
#'
#' @return Object with character values converted to ASCII.
#'
#' @noRd
enc2ascii <- function(x) {
  if (inherits(x, "character")) {
    x <- stringi::stri_trans_general(x, "Latin-ASCII")
    iconv(x, from = "UTF-8", to = "ascii", sub = "")
  } else if (inherits(x, "list")) {
    lapply(x, enc2ascii)
  } else {
    x
  }
}

#' Wrapper around enc2ascii that preserves specific named fields as UTF-8
#' @param x Object (e.g. `list` or `character` vector).
#' @param keep Character vector of list element names to preserve as UTF-8.
#' @noRd
enc2ascii_keep <- function(x, keep = "name") {
  if (inherits(x, "list")) {
    nms <- names(x)
    for (i in seq_along(x)) {
      if (!is.null(nms) && nms[i] %in% keep) {
        x[[i]] <- enc2utf8(x[[i]])
      } else {
        x[[i]] <- enc2ascii_keep(x[[i]], keep)
      }
    }
    x
  } else {
    enc2ascii(x)
  }
}
