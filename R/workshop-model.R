# workshop-model.R -- shared setup for every workshop chapter.
# Each chapter starts with:  source("R/workshop-model.R")
# It loads energyRt, sets defaults, and provides small helpers used throughout.

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
