push_clean <- function() {
  try(file.remove("pushover.dta"))
}

push_analysis <- function() {
  if (file.exists("pushover.dta") == TRUE) {
    pushoverr::pushover(message = 'Analysis complete.')
  } else{
    pushoverr::pushover(message = 'Analysis errored.')
  }
  file.remove("pushover.dta")
}

push_plotting <- function() {
pushoverr::pushover(message='Plotting complete.')
}
