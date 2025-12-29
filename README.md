# Oipdf.jl

[![Build Status](https://github.com/SentientPlatypus/Oipdf.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/SentientPlatypus/Oipdf.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Julia](https://img.shields.io/badge/Julia-1.10+-blue.svg)](https://julialang.org/)

Oipdf.jl extracts risk-neutral probability distributions from options market data, revealing the market's collective expectations about future asset price movements.

Under the efficient market hypothesis, these option-implied probabilities represent the most informed estimates available of potential price outcomes, derived from the wisdom of market participants.

> This package was inspired by the existing python library, [OIPD](https://github.com/tyrneh/options-implied-probability/blob/main/README.md)


![Risk-Neutral Probability Density Function](examples/example_plots/AAPL/2026-01-09/7_pdf_numerical.png)

*Example output: Risk-neutral probability density function extracted from AAPL options data*

## Features

- **Real-time Options Data**: Fetches live options chains from Yahoo Finance
- **Black-Scholes Pricing**: Completes implementation with implied volatility calculation
- **SVI Model**: Stochastic Volatility Inspired model for volatility smile fitting
- **Risk-Neutral Probabilities**: Calculates probabilities of price movements using risk-neutral density
- **Breeden-Litzenberger**: Numerical density estimation from option prices
- **Visualization**: Built-in plotting functions for analysis and debugging
- **Arbitrage Detection**: Automatic checking for model consistency and arbitrage opportunities

## Quick Start

```julia
using Oipdf

# Calculate probability that AMD will be below $200 at expiration
prob = prob_below("AMD", 200.0, "2025-01-17")

# Calculate probability that AMD will be at or above $250
prob_above = prob_at_or_above("AMD", 250.0, "2025-01-17")

# Get closest available expiration date
expiry = get_closest_expiry("AMD")
```

## Installation

```julia
using Pkg
Pkg.add("https://github.com/SentientPlatypus/Oipd.jl")
```

## Documentation

- **[Technical Documentation](TECHNICAL_README.md)**: Detailed mathematical background, algorithms, and API reference
- **[Examples](examples/)**: Practical usage examples and scripts
- **API Reference**: Comprehensive function documentation in source code

## Core Functionality

### Options Data
- Fetch real-time call and put options data
- Automatic data cleaning and quote health checking
- Support for any ticker with options available on Yahoo Finance

### Pricing Models
- **Black-Scholes**: European option pricing with Newton-Raphson implied volatility
- **SVI**: Parametric volatility smile modeling

### Probability Analysis
- Calculate risk-neutral probabilities for price movements
- Support for custom strike prices and expiration dates
- Automatic volatility surface construction

### Visualization
- Volatility smile plots
- Price vs strike analysis
- Risk-neutral density plots
- SVI model fit diagnostics

#### Example Plots (AAPL Options Analysis)

**Implied Volatility Smile**
![Implied Volatility Smile](examples/example_plots/AAPL/2026-01-09/2_iv_smile.png)

**SVI Model Fit**
![SVI Fitted Volatility Surface](examples/example_plots/AAPL/2026-01-09/5_iv_svi.png)

**Risk-Neutral Probability Density**
![Risk-Neutral Probability Density Function](examples/example_plots/AAPL/2026-01-09/7_pdf_numerical.png)

## Example Usage

```julia
using Oipdf

# Analyze AMD options expiring in January 2025
ticker = "AMD"
expiry = "2025-01-17"
strike = 220.0

# Calculate probabilities
prob_below_strike = prob_below(ticker, strike, expiry)
prob_above_strike = prob_at_or_above(ticker, strike, expiry)

println("Probability AMD < $strike at expiry: $(round(prob_below_strike * 100, digits=2))%")
println("Probability AMD ≥ $strike at expiry: $(round(prob_above_strike * 100, digits=2))%")

# Generate analysis plots
prob_below(ticker, strike, expiry, "./plots")
```

## Dependencies

- **DataFrames.jl**: Data manipulation
- **Plots.jl**: Visualization
- **Optim.jl**: Numerical optimization
- **Distributions.jl**: Statistical distributions
- **PythonCall.jl**: Yahoo Finance data fetching via yfinance

## Applications

- **Risk Management**: Assess probability of adverse price movements
- **Portfolio Optimization**: Incorporate option-implied probabilities
- **Trading Strategies**: Volatility arbitrage and directional bets
- **Research**: Empirical analysis of risk-neutral distributions
- **Education**: Learn options pricing and volatility modeling

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use Oipdf.jl in your research, please cite:

```bibtex
@software{wicksono2025oipd,
  author = {Gene Wicaksono},
  title = {Oipdf.jl: Options Pricing and Risk Analysis in Julia},
  url = {https://github.com/SentientPlatypus/Oipdf.jl},
  year = {2025}
}
```

## Acknowledgments

- Yahoo Finance for options data
- The Julia community for excellent packages
- Financial mathematics literature on SVI and risk-neutral pricing


