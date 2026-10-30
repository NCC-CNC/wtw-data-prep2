library(testthat)

# The repo is not an installable package, so run the test folder directly.
# Works from the repo root (e.g. the .Rproj) or from tests/.
test_dir(if (dir.exists("testthat")) "testthat" else file.path("tests", "testthat"))
