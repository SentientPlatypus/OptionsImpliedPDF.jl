# [User guide](@id user-guide)

```@meta
CurrentModule = OptionsImpliedPDF
```

## What the numbers mean

`prob_below` and `prob_at_or_above` return **risk-neutral** probabilities implied by listed option prices (the pricing measure Q), not a forecast of real-world frequencies. They are useful for relative pricing, strike comparisons, and internal consistency checks.

## Typical workflow

1. Choose a **ticker** listed on Yahoo Finance with options.
2. Choose an **expiry** string in Yahoo’s format (e.g. `"2026-01-16"`), or call `get_closest_expiry(ticker)` for the nearest listed expiry.
3. Call `prob_below` or `prob_at_or_above` with a **strike** in the same units as spot (e.g. dollars per share for US equities).

```julia
using OptionsImpliedPDF

ticker = "AMD"
expiry = get_closest_expiry(ticker)

p_low = prob_below(ticker, 200.0, expiry)
p_high = prob_at_or_above(ticker, 250.0, expiry)
```

## Saving diagnostic plots

Pass a directory as the fourth argument (`savedir`) to write figures under `savedir/ticker/expiry/` (parity, IV smile, smoothing, SVI fit, repriced curve, numerical PDF, etc.).

```julia
prob_below("AAPL", 180.0, "2026-01-16", "./plots")
```

## Data quality and errors

- Thin or missing bid/ask quotes can produce warnings; the code may fall back to `lastPrice`.
- SVI calibration includes butterfly diagnostics; a bad chain can error instead of returning an invalid density.

For methodology, see [Technical background](@ref technical-background).
