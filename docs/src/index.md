# OptionsImpliedPDF.jl

```@meta
CurrentModule = OptionsImpliedPDF
```

## Overview

OptionsImpliedPDF.jl extracts **risk-neutral** probability information from options market data, summarizing what listed prices imply about the distribution of the underlying at expiry.

This package was inspired by the Python project [OIPD](https://github.com/tyrneh/options-implied-probability/blob/main/README.md).

![Risk-neutral PDF from AAPL options](https://raw.githubusercontent.com/SentientPlatypus/OptionsImpliedPDF.jl/main/examples/example_plots/AAPL/2026-01-09/7_pdf_numerical.png)

## Features

- Live options chains via Yahoo Finance ([PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl))
- Put–call parity and OTM processing, IV smoothing, **SVI** smile fit with no-butterfly checks
- **Breeden–Litzenberger**-style numerical density and tail probabilities
- Optional on-disk **Plots.jl** diagnostics when you pass `savedir`

## Where to read next

| Topic | Page |
|--------|------|
| Install & Python stack | [Installation](@ref installation-page) |
| How to call the API | [User guide](@ref user-guide) |
| `prob_below`, `prob_at_or_above`, `get_closest_expiry` | [API reference](@ref api-reference) |
| Pipeline & math | [Technical background](@ref technical-background) |
| PDF notes | [Notes & PDFs](@ref notes-pdfs) |

## Quick start (copy-paste)

```julia
using Pkg
Pkg.add("OptionsImpliedPDF")
```

```julia
using OptionsImpliedPDF

expiry = get_closest_expiry("AMD")
prob_below("AMD", 200.0, expiry)
prob_at_or_above("AMD", 250.0, expiry)
```

These calls hit the network (Yahoo). For offline doc builds we keep examples as static code here; run the same lines in your own Julia session.

## Contributing and license

Contributions are welcome via issues and pull requests.

Licensed under the MIT License: [LICENSE](https://github.com/SentientPlatypus/OptionsImpliedPDF.jl/blob/main/LICENSE).
