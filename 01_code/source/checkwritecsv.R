checkwritecsv <- function(df, path) {
  if (!file.exists(path)) {
    write_csv(df, path)
  }
}