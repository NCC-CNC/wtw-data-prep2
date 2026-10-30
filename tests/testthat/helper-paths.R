# Paths and working-directory helpers for the pipeline tests.
#
# testthat sources this file with the working directory set to
# tests/testthat. The pipeline steps are plain scripts that source their
# helpers with paths relative to the repo root (e.g.
# `source("R/fct_init_metadata.R")`), so they are sourced with the working
# directory switched to the repo root and restored afterwards.

# Absolute path to the repo root
REPO_ROOT <- normalizePath(file.path("..", ".."), winslash = "/")

# --- working directory -------------------------------------------------------

# Evaluates `code` with the working directory set to `dir`, then restores it
with_dir <- function(dir, code) {
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  force(code)
}

# Sources pipeline scripts from R/ with the working directory at the repo
# root. `env` is where the script's top-level definitions go; helpers the
# script itself sources (with `source()`'s default) go to the global env.
source_pipeline <- function(files, env = globalenv()) {
  with_dir(REPO_ROOT, {
    for (f in files) {
      source(file.path("R", f), local = env)
    }
  })
  invisible(env)
}

# A new, empty temporary folder
new_temp_dir <- function(pattern = "wtw") {
  dir <- tempfile(pattern)
  dir.create(dir, recursive = TRUE)
  normalizePath(dir, winslash = "/")
}

# Copies a folder's contents to a new temporary folder and returns its path
copy_dir <- function(from, pattern = "wtw") {
  to <- new_temp_dir(pattern)
  file.copy(
    list.files(from, full.names = TRUE, all.files = TRUE, no.. = TRUE),
    to,
    recursive = TRUE
  )
  to
}
