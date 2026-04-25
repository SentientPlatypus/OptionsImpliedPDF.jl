# If `using Plots` / OpenSSL / libpng errors appear, your global startup may load PythonCall
# before Julia’s JLLs. Run:
#   julia --startup-file=no src/0_example.jl
# or remove early `using PythonCall` from ~/.julia/config/startup.jl
import Pkg
const _PKG_ROOT = joinpath(@__DIR__, "..")
Pkg.activate(_PKG_ROOT)
Pkg.instantiate()

include(joinpath(@__DIR__, "OptionsImpliedPDF.jl"))

using .OptionsImpliedPDF

println("this is running 0_example.jl")

if get(ENV, "SKIP_YAHOO", "") == "1"
    println("SKIP_YAHOO=1 — skipping live Yahoo Finance (smoke test only).")
    exit(0)
end

savedir = "examples/example_plots"
ticker = "AAPL"

p_below = prob_below(ticker, 250.0, get_closest_expiry(ticker), savedir)
p_above = prob_at_or_above(ticker, 250.0, get_closest_expiry(ticker), savedir)

println("Probability that $(ticker) will be below 250.0 at expiry: $(p_below)")
println("Probability that $(ticker) will be above 250.0 at expiry: $(p_above)")