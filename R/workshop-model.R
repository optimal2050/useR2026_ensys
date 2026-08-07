# workshop-model.R -- shared setup for every workshop chapter.
# Each chapter starts with:  source("R/workshop-model.R")
# It loads energyRt, sets defaults, and provides small helpers used throughout.

# ---- energyRt version stamp -------------------------------------------------
# The chapters are written against this version. Bump it whenever the course
# starts to rely on something newer, so participants on a stale install are
# told at the top of the session rather than by a confusing error mid-chapter.
WS_ENERGYRT_MIN <- "0.74.2.9000"

#' Check the installed energyRt against the version the workshop needs.
#'
#' Called automatically when this file is sourced. Re-run it yourself after
#' updating to confirm the new version is picked up (restart R first).
ws_check_energyRt <- function(min_version = WS_ENERGYRT_MIN) {
  install_hint <- paste0(
    '  source("https://raw.githubusercontent.com/optimal2050/energyRt/master/inst/install.R")\n',
    '  install_energyRt(branch = "dev")\n',
    "Then restart R (Session > Restart R) so the new version is loaded."
  )

  if (!requireNamespace("energyRt", quietly = TRUE)) {
    stop("energyRt is not installed. See the Installation chapter:\n",
         install_hint, call. = FALSE)
  }

  have <- utils::packageVersion("energyRt")
  if (have < package_version(min_version)) {
    warning("energyRt ", have, " is older than the ", min_version,
            " this workshop is written against.\n",
            "Some chapters will fail. Update with:\n", install_hint,
            call. = FALSE, immediate. = TRUE)
  } else {
    message("energyRt ", have, " -- workshop needs >= ", min_version, ". OK.")
  }
  invisible(have)
}

ws_check_energyRt()

library(energyRt)
library(dplyr)
library(ggplot2)

# where solver files and results are written (temporary, per session)
set_scenarios_path(file.path(tempdir(), "utopia"))

# one solver for the whole workshop: solve_scenario() picks it up automatically
set_default_solver(solver_options$glpk)

# ---- workshop defaults ------------------------------------------------------
WS_REGIONS  <- "R1"                                # build chapters: one region
WS_CAL      <- calendars$utopia_s4h24              # 4 seasons x 24 hours (96 slices)
WS_DISCOUNT <- 0.05

# deterministic capacity-factor / load / stock profiles shipped with energyRt
prof <- utopia_profiles(WS_REGIONS, calendar = "utopia_s4h24")

# ---- unit helpers (capacity GW, energy PJ, costs MEUR) ----------------------
meur_gw  <- function(eur_per_kw)  convert("EUR/kW",  "MEUR/GW", eur_per_kw)
meur_pj  <- function(eur_per_gj)  convert("EUR/GJ",  "MEUR/PJ", eur_per_gj)
meur_pj_kwh <- function(eur_per_kwh) convert("EUR/kWh", "MEUR/PJ", eur_per_kwh)

# ---- a shared ggplot theme so every chart matches ---------------------------
theme_ws <- function() theme_bw(base_size = 12)
