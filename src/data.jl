using PythonCall
using DataFrames

yf = pyimport("yfinance")
pd = pyimport("pandas")

function get_option_prices(ticker::String, expiry_date::String)
    "Returns two dataframes. One with call options and one with put options for the given ticker and expiry date"

    stock = yf.Ticker(ticker)

    @assert length(stock.options) > 0 "No options data is found for the given ticker: $(ticker). Check that the ticker is correct."
    @assert expiry_date in stock.options "Expiry date: $(expiry_date) not found for the given ticker: $(ticker). The possible dates are $(stock.options)"

    opt_chain = stock.option_chain(expiry_date)

    call_df = DataFrame(PyTable(opt_chain.calls))
    put_df = DataFrame(PyTable(opt_chain.puts))

    call_df.mid = (call_df.ask .+ call_df.bid) ./ 2
    put_df.mid = (put_df.ask .+ put_df.bid) ./ 2

    return call_df, put_df
end

function get_spot_price(ticker::String)
    "Returns the spot price of the given ticker"
    stock = yf.Ticker(ticker)
    spot = pyconvert(Float64, stock.fast_info["lastPrice"])
    return spot
end

function get_closest_expiry(ticker::String)
    "Returns the closest expiry date for the given ticker"
    stock = yf.Ticker(ticker)
    @assert length(stock.options) > 0 "No options data is found for the given ticker: $(ticker). Check that the ticker is correct."
    closest_expiry = pyconvert(String, stock.options[1])
    return closest_expiry
end

println("im running dis fr fr")
ticker = "AMD"
expiry = get_closest_expiry(ticker)
println("ticker: $(ticker) expiry: $(expiry)")
call_df, put_df = get_option_prices(ticker, expiry)
spot = get_spot_price(ticker)
rate = 0.01

include("../src/functions.jl")
paritized = paritize(spot, call_df, put_df, expiry, rate)
println(paritized)

using Plots
plot(
    paritized.strike,
    paritized.price,
    seriestype = :scatter,      # or :scatter
    marker = :circle,
    xlabel = "Strike",
    ylabel = "Price",
    title = "Paritized Option Prices",
    legend = false
)

savefig("test_plot.png")

export get_option_prices


