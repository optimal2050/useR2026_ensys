# Energy System Modeling with R

Course materials for **Energy System Modeling with R** — a free four-session
online series following *useR! 2026*, on building, solving and exploring
energy-system models in R with
[**energyRt**](https://github.com/optimal2050/energyRt) and the wider
[**optimal2050**](https://github.com/optimal2050) ecosystem.

### 📖 [**Read the materials »**](https://optimal2050.github.io/useR2026_ensys/)

### 📅 [**Course details and registration »**](https://energyRt.org/use-R-2026)

---

## The series

Four live Zoom sessions, **Fridays 7–28 August 2026, 12:00 UTC** (New York
08:00 · Berlin 14:00 · New Delhi 17:30 · Beijing 20:00), about 90 minutes each.

| | Date | Focus |
|---|---|---|
| **Session 1** | 7 August | "LEGO-lization" of energy modeling; energyRt basics; a model built and solved live |
| **Session 2** | 14 August | Exercise follow-up; building a model brick by brick; policy scenarios |
| **Session 3** | 21 August | Advanced applications; reproducing a large open-source model; alternative backends |
| **Session 4** | 28 August | Open questions, troubleshooting, extending to your own work |

Sessions 1 and 3 introduce new material; 2 and 4 work through participants'
exercises and questions. **Nothing needs to be installed to attend** — you are
welcome to join simply to watch. The hands-on exercises are done in your own
time between sessions.

Registration is a single sign-up for the whole series:
[**Zoom »**](https://us06web.zoom.us/meeting/register/9qp-nqa0S8-lzi-ktCz-hQ)

## What is in this repository

The published site is built from these sources with [Quarto](https://quarto.org/):

| Path | What it is |
|---|---|
| [`index.qmd`](index.qmd) | Preface — what the course covers and where to ask questions |
| [`r-resources.qmd`](r-resources.qmd) | Getting R, RStudio and Quarto; short introductions; key packages; cheatsheets |
| [`installation.qmd`](installation.qmd) | Installing energyRt and at least one solver backend |
| [`01-first-model.qmd`](01-first-model.qmd) | **Exercise 1** — grow a model from nothing to coal and CO₂, one object at a time |
| [`slides/builders.qmd`](slides/builders.qmd) | Reference deck: the `new*()` constructors and the system around them |
| [`R/`](R/) | Shared setup sourced by the exercise chapters |

## Preparing

You can follow the whole series without installing anything. To do the
exercises you will need **R ≥ 4.3**, energyRt, and one solver — GLPK is the
default and the least trouble:

- [R setup and resources](https://optimal2050.github.io/useR2026_ensys/r-resources.html)
- [Installing energyRt](https://optimal2050.github.io/useR2026_ensys/installation.html)

## Questions

Questions between sessions are welcome, and best asked in the open where the
answer helps everyone:

**[The course Q&A thread on Mastodon »](https://mstdn.science/@optimal2050/117049007107822486)**

Install problems, modeling questions, or something you built and want to show —
beginner questions especially welcome. No account? Registering at
[mastodon.social](https://mastodon.social/) takes about a minute, and an account
on any server can reply. For course updates, follow
[**@optimal2050@mstdn.science**](https://mstdn.science/@optimal2050) and tag your
own posts **#optimal2050**.

## Building and publishing

**The site is built and published from a workstation, not by CI.** The chapters
and decks need energyRt, a solver (Julia/HiGHS or GLPK) and the converted
PyPSA-Eur datasets; a GitHub runner has none of them, so a CI build would render
the prose without any of the numbers. The workflow's push trigger is disabled and
it is kept for manual dispatch only.

```bash
# 1. rebuild any deck whose source changed -- decks EXECUTE (they solve)
quarto render slides/real-model.qmd
quarto render slides/pypsa-replication.qmd
quarto render slides/builders.qmd

# 2. build the book and push it to gh-pages
quarto publish gh-pages
```

`quarto publish` renders into `_book/` (gitignored) and pushes only the result to
the `gh-pages` branch, which is what Pages serves. Nothing generated is committed
to `main` — except the decks, which are committed as pre-rendered static
resources because the book itself does not execute.

To build without publishing, `quarto render` alone is enough.

### Executing the exercises

The committed configuration keeps `execute: eval: false`, so a normal render is
fast and needs no solver. To actually run the exercise chunks while reviewing a
chapter:

```bash
quarto render 06-real-model.qmd --profile exec
```

Be aware of the cost: the full-year Belgium copperplate is ~473,000 variables and
about 4.5 minutes per solve, and that chapter solves several times. Render the
single file you are working on rather than the whole book.

## An open work in progress

Most of the *optimal2050* packages are still in active development and not yet
formally released. This course shares the ideas behind an ongoing project as
much as it teaches finished software — expect a few rough edges, and bring your
questions and critique. We are keen to discuss the approach, improve it
together, and welcome new collaborators.

energyRt itself is licensed under
[AGPL-3.0](https://github.com/optimal2050/energyRt/blob/master/LICENSE).
