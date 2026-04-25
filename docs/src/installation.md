# [Installation](@id installation-page)

## Requirements

- **Julia** 1.10 or newer
- Network access for [Yahoo Finance](https://finance.yahoo.com/) options data (via Python `yfinance`)

## From the Julia registry

```julia
using Pkg
Pkg.add("OptionsImpliedPDF")
```

The first time you load the package, [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl) uses [CondaPkg.jl](https://github.com/JuliaPy/CondaPkg.jl) to provision a dedicated Python environment. Dependencies are pinned in the package root [`CondaPkg.toml`](https://github.com/SentientPlatypus/OptionsImpliedPDF.jl/blob/main/CondaPkg.toml) (for example `yfinance`).

If Python dependencies fail to resolve, or on Linux you see **`OPENSSL_3.3.0` not found** when loading the package, refresh the Conda environment (the package pins a recent `openssl` so it matches Julia’s `OpenSSL_jll`):

```julia
using CondaPkg
CondaPkg.resolve()
```

Then restart Julia and `using OptionsImpliedPDF` again.

## Local development checkout

```julia
using Pkg
Pkg.develop(path="/path/to/OptionsImpliedPDF")
```

Use the directory that contains `Project.toml`.

## Build this manual locally

From the repository root (in a shell where `julia` is on your `PATH`):

```bash
julia --project=docs -e 'using Pkg; Pkg.instantiate(); include("docs/make.jl")'
```

Or start Julia, activate `docs`, `Pkg.instantiate()`, then `include("docs/make.jl")`.

HTML is written to `docs/build/`. Open `docs/build/index.html` in a browser.

Continuous integration builds and deploys the site from the **Documentation** workflow when configured with a `DOCUMENTER_KEY` secret (see [Documenter: Hosting](https://documenter.juliadocs.org/stable/man/hosting/)).
