# energy-rhapsody.R -- sonify a solved energyRt scenario: one instrument per
# process, a day of dispatch becomes a bar of music.
#
# Inspired by useR!2025, "Rhapsody in R" by John Zito
# (https://www.youtube.com/watch?v=LSWKtduQ58I), and adapted from the
# pitchCarbon.R example by Stephan Lugovoy.
#
# Mapping:
#   pitch (baseline)  <- carbon intensity: the cleaner the source, the higher
#   pitch (movement)  <- hour-to-hour variability (+-5 semitones)
#   volume            <- generation level in that hour
#   rest              <- the process is idle
#   instrument        <- the process family (coal = tuba, solar = music box...)
#
# Requires the `gm` package; rendering the score/audio additionally needs
# MuseScore (https://musescore.org). `play = FALSE` returns the gm::Music
# object without rendering, so the composition itself needs no MuseScore.

energy_rhapsody <- function(scen, comm = "ELC", region = NULL, year = NULL,
                            slice = "^SUM_", tempo = 90, play = TRUE) {
  if (!requireNamespace("gm", quietly = TRUE)) {
    stop("energy_rhapsody() needs the 'gm' package: install.packages(\"gm\").\n",
         "Rendering score/audio also needs MuseScore on the PATH ",
         "(see ?gm::show).", call. = FALSE)
  }

  # ── 1. hourly generation profile per process (energyRt native extractor) ──
  mx <- energyRt::getMix(scen, "generation", comm = comm, region = region,
                         year = year, slice = slice)
  mx <- mx[mx$flow != "demand", , drop = FALSE]
  if (nrow(mx) == 0 || !"hour" %in% names(mx)) {
    stop("No hourly generation found for slice pattern '", slice,
         "' -- the calendar needs sub-annual (hourly) slices.", call. = FALSE)
  }
  if (is.null(year)) {                       # default: the last milestone year
    yr <- max(mx$year, na.rm = TRUE)
    mx <- mx[mx$year == yr, , drop = FALSE]
  }
  agg <- stats::aggregate(value ~ process + hour, mx, sum)
  hours <- sort(unique(agg$hour))
  processes <- sort(unique(agg$process))

  # ── 2. sonification config (C minor pentatonic, per pitchCarbon.R) ────────
  cfg <- list(midi_min = 48L, midi_max = 84L,          # C3..C6
              scale_pc = c(0L, 3L, 5L, 7L, 10L),
              vel_min = 28L, vel_max = 116L)

  scale_to_int <- function(x, out_min, out_max) {
    r <- range(x, na.rm = TRUE)
    if (!all(is.finite(r)) || r[1] == r[2])
      return(rep(as.integer(round((out_min + out_max) / 2)), length(x)))
    as.integer(round(out_min + (x - r[1]) / (r[2] - r[1]) * (out_max - out_min)))
  }
  snap_to_scale <- function(m) {
    pcs <- cfg$scale_pc %% 12L
    vapply(m, function(v) {
      if (is.na(v)) return(NA_integer_)
      (v %/% 12L) * 12L + pcs[which.min(abs(pcs - v %% 12L))]
    }, integer(1))
  }
  delta_to_offset <- function(v, max_offset = 5L) {
    d <- c(0, abs(diff(v)))
    if (max(d) == min(d)) return(rep(0L, length(d)))
    z <- (d - min(d)) / (max(d) - min(d))
    as.integer(round((2 * z - 1) * max_offset))
  }

  # carbon intensity baseline: cleaner source -> higher pitch (UTOPIA names)
  carbon_of <- function(p) {
    p <- toupper(p)
    if (grepl("COA", p))                 return(100)   # incl. ECOABIO co-firing
    if (grepl("GAS|OIL", p))             return(100)
    if (grepl("NUC", p))                 return(20)
    if (grepl("BIO", p))                 return(10)
    if (grepl("SOL|WIN|HYD", p))         return(5)
    if (grepl("STG|STORAGE", p))         return(30)
    60                                                  # imports & the rest
  }
  # instrument (General MIDI program) per process family
  instrument_of <- function(p, i) {
    p <- toupper(p)
    if (grepl("COABIO", p))       return(71L)  # bassoon  - the co-firing blend
    if (grepl("COA", p))          return(58L)  # tuba     - coal
    if (grepl("GAS", p))          return(62L)  # brass    - gas
    if (grepl("NUC", p))          return(49L)  # strings  - nuclear
    if (grepl("SOL", p))          return(10L)  # music box - solar
    if (grepl("WIN", p))          return(75L)  # pan flute - wind
    if (grepl("HYD", p))          return(74L)  # flute    - hydro
    if (grepl("STG|STORAGE", p))  return(89L)  # synth pad - storage
    if (grepl("IMP|TRD", p))      return(53L)  # voice     - imports
    c(1L, 5L, 12L, 25L, 41L, 57L, 66L, 81L)[(i - 1L) %% 8L + 1L]
  }

  baseline <- scale_to_int(-log1p(vapply(processes, carbon_of, numeric(1))),
                           cfg$midi_min, cfg$midi_max)
  baseline <- snap_to_scale(baseline)

  # ── 3. compose: one Line (part) per process ───────────────────────────────
  music <- gm::Music() + gm::Meter(4, 4) + gm::Tempo(tempo)
  for (i in seq_along(processes)) {
    p  <- processes[i]
    v  <- merge(data.frame(hour = hours),
                agg[agg$process == p, c("hour", "value")],
                by = "hour", all.x = TRUE)
    values <- abs(ifelse(is.na(v$value), 0, v$value))   # storage-in is negative

    pitch <- baseline[i] + delta_to_offset(values)
    pitch <- snap_to_scale(pmax(cfg$midi_min, pmin(cfg$midi_max, pitch)))
    pitch[values == 0] <- NA_integer_                    # idle -> rest
    vel <- scale_to_int(values, cfg$vel_min, cfg$vel_max)

    # merge consecutive equal-value hours into longer notes
    runs <- rle(values)
    idx  <- cumsum(c(1L, utils::head(runs$lengths, -1L)))
    music <- music +
      gm::Line(pitches = as.list(pitch[idx]), durations = as.list(runs$lengths),
               name = p) +
      gm::Instrument(instrument_of(p, i), to = p)
    for (k in seq_along(idx)) {
      music <- music + gm::Velocity(vel[idx[k]], to = p, i = k)
    }
  }

  if (isTRUE(play)) gm::show(music, to = c("score", "audio")) else music
}
