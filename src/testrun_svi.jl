include("../src/data.jl")
include("../src/functions.jl")
include("../src/bs.jl")
include("../src/svi.jl")
include("../src/plotting.jl")



println("this is running testrun.jl")


ticker = "AMD"
expiry = get_closest_expiry(ticker)

call_df, put_df = get_option_prices(ticker, expiry)

spot = get_spot_price(ticker)
rate = 0.01 
τ = get_τ(expiry)
F = spot * exp(rate * τ)

println("F: $(F)")
println("ticker: $(ticker) expiry: $(expiry) spot: $(spot)")

paritized = paritize(spot, call_df, put_df, τ, rate)
print(paritized)

paritized_with_iv = add_IV_column(paritized, spot, rate, τ)

smoothed_data = gaussian_smooth(paritized_with_iv, 5)
smoothed_data_no_nans = remove_nans(smoothed_data)

fit, iv_fun = fit_svi_smile(
    Float64.(smoothed_data_no_nans.strike),
    Float64.(smoothed_data_no_nans.iv),
    F,τ
    , 1e-4)

@show fit

repriced_paritized = reprice(paritized, spot, rate, τ, iv_fun)

spl_price = fit_price_spline(repriced_paritized, 1e-4)



strike_price_to_analyze = 220.0

probability_below = p_below(
    strike_price_to_analyze,
    spot,
    iv_fun,
    rate,
    τ
)

probability_above = p_at_or_above(
    strike_price_to_analyze,
    spot,
    iv_fun,
    rate,
    τ
)


println("Probability that the price will be above $(strike_price_to_analyze) at expiry: $(probability_above)")
println("Probability that the price will be below $(strike_price_to_analyze) at expiry: $(probability_below)")

# Plotting
dir = "plots/testrun/$(ticker)/$(expiry)"

make_dir_if_not_exists(dir)
plot_paritized_prices(paritized, ticker, dir)
plot_iv_smile(paritized_with_iv, ticker, dir)
plot_smoothed_iv(smoothed_data, ticker, dir)
plot_smoothed_iv_filtered(smoothed_data_no_nans, ticker, dir)
plot_svi_fit(smoothed_data_no_nans, iv_fun, ticker, dir)
plot_repriced_prices(repriced_paritized, ticker, dir)
plot_pdf_numerical(repriced_paritized, spot, iv_fun, rate, τ, ticker, dir)