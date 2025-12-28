include(joinpath(@__DIR__, "Oipd.jl"))

using .Oipd


println("this is running top_level_test.jl")


prob_below("AAPL", 250.0, get_closest_expiry("AAPL"), "plots/pdfs/AAPL_pdf_plot.png")