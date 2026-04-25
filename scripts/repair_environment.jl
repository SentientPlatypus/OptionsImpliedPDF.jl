# Repair Julia depot + project. From repo root:
#   julia --startup-file=no scripts/repair_environment.jl
#
# Use --startup-file=no so a global startup.jl cannot pull Conda/PythonCall
# before artifacts (fixes OpenSSL / precompile ordering on Linux).
import Pkg
import Dates

const ROOT = abspath(joinpath(dirname(@__FILE__), ".."))

Pkg.activate(ROOT)
@info "Active project" path = Pkg.project().path

@info "Instantiating…"
Pkg.instantiate()

@info "GC stale packages/artifacts…"
try
    Pkg.gc(; collect_delay = Dates.Day(0))
catch
    Pkg.gc()
end

@info "Loading Plots (exercises libpng / GR / FFMPEG JLLs)…"
using Plots
@info "Plots OK"

@info "Loading PythonCall…"
using PythonCall
@info "PythonCall OK"

@info "Precompiling full project…"
Pkg.precompile()

@info "Done. Run: julia --startup-file=no --project=@. src/0_example.jl"
