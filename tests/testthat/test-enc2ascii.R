source(file.path("..", "..", "R", "wtw_fct_enc2ascii.R"))

# --- enc2ascii ---------------------------------------------------------------

test_that("enc2ascii transliterates French accented characters", {
  expect_equal(enc2ascii("Écosystème calcicole"), "Ecosysteme calcicole")
  expect_equal(
    enc2ascii("Proximité aux aires protégées"),
    "Proximite aux aires protegees"
  )
  expect_equal(enc2ascii("Céanothe d'Amérique"), "Ceanothe d'Amerique")
})

test_that("enc2ascii leaves plain ASCII unchanged", {
  expect_equal(enc2ascii("hello world"), "hello world")
  expect_equal(enc2ascii("theme"), "theme")
})

test_that("enc2ascii works on character vectors", {
  input <- c("Écosystème", "Milieu humide", "Forêt")
  expected <- c("Ecosysteme", "Milieu humide", "Foret")
  expect_equal(enc2ascii(input), expected)
})

test_that("enc2ascii recurses into lists", {
  input <- list(a = "Écosystème", b = list(c = "Forêt"))
  result <- enc2ascii(input)
  expect_equal(result$a, "Ecosysteme")
  expect_equal(result$b$c, "Foret")
})

test_that("enc2ascii passes through non-character types", {
  expect_equal(enc2ascii(42), 42)
  expect_equal(enc2ascii(TRUE), TRUE)
  expect_equal(enc2ascii(3.14), 3.14)
})

# --- enc2ascii_keep ----------------------------------------------------------

test_that("enc2ascii_keep preserves name fields as UTF-8", {
  input <- list(
    name = "Écosystème calcicole",
    units = "km²"
  )
  result <- enc2ascii_keep(input, keep = "name")
  expect_equal(result$name, "Écosystème calcicole")
  expect_equal(result$units, "km")
})

test_that("enc2ascii_keep preserves names in nested lists", {
  input <- list(
    name = "Mon Projet",
    themes = list(
      list(
        name = "Proximité aux aires protégées",
        units = "km²"
      )
    )
  )
  result <- enc2ascii_keep(input, keep = "name")
  expect_equal(result$name, "Mon Projet")
  expect_equal(result$themes[[1]]$name, "Proximité aux aires protégées")
  expect_equal(result$themes[[1]]$units, "km")
})

test_that("enc2ascii_keep supports multiple keep fields", {
  input <- list(
    name = "Écosystème",
    author_name = "François Légaré",
    mode = "advanced"
  )
  result <- enc2ascii_keep(input, keep = c("name", "author_name"))
  expect_equal(result$name, "Écosystème")
  expect_equal(result$author_name, "François Légaré")
  expect_equal(result$mode, "advanced")
})

test_that("enc2ascii_keep converts non-keep fields to ASCII", {
  input <- list(
    name = "Forêt boréale",
    provenance = "régional"
  )
  result <- enc2ascii_keep(input, keep = "name")
  expect_equal(result$name, "Forêt boréale")
  expect_equal(result$provenance, "regional")
})

test_that("enc2ascii_keep handles unnamed lists", {
  input <- list(
    list(name = "Écosystème", units = "hà"),
    list(name = "Forêt", units = "km²")
  )
  result <- enc2ascii_keep(input, keep = "name")
  expect_equal(result[[1]]$name, "Écosystème")
  expect_equal(result[[1]]$units, "ha")
  expect_equal(result[[2]]$name, "Forêt")
  expect_equal(result[[2]]$units, "km")
})
