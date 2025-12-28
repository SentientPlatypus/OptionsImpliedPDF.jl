include("../src/data.jl")
include("../src/functions.jl")
include("../src/bs.jl")
include("../src/svi.jl")



println("this is running testrun.jl")


ticker = "AMD"
expiry = get_closest_expiry(ticker)

call_df, put_df = get_option_prices(ticker, expiry)
spot = get_spot_price(ticker)

println("ticker: $(ticker) expiry: $(expiry) spot: $(spot)")

τ = get_τ(expiry)
rate = 0.01

paritized = paritize(spot, call_df, put_df, τ, rate)
print(paritized)

paritized_with_iv = add_IV_column(paritized, spot, rate, τ)

smoothed_data = gaussian_smooth(paritized_with_iv, 5)
smoothed_data_no_nans = remove_nans(smoothed_data)

spl_iv = fit_iv_spline(smoothed_data_no_nans, 1e-4)

repriced_paritized = reprice(paritized, spot, rate, τ, spl_iv)

spl_price = fit_price_spline(repriced_paritized, 1e-4)

# pdf = Breeden_Litzenberger(spl_price, rate, τ)
using Plots
plot(
    paritized.strike,
    paritized.price,
    seriestype = :scatter,
    marker = :circle,
    xlabel = "Strike",
    ylabel = "Price",
    title = "Paritized Option Prices",
    legend = false
)

savefig("plots/$(ticker)_1_paritized_plot.png")

plot(
    paritized_with_iv.strike,
    paritized_with_iv.iv,
    seriestype = :scatter,
    marker = :circle,
    xlabel = "Strike",
    ylabel = "Implied Vol",
    title = "Implied Volatility Smile",
    legend = false
)
savefig("plots/$(ticker)_2_iv_smile.png")

plot(
    smoothed_data.strike,
    smoothed_data.iv,
    seriestype = :scatter,
    marker = :circle,
    xlabel = "Strike",
    ylabel = "Implied Vol (smoothed)",
    title = "Implied Volatility Smile smoothed",
    legend = false
)
savefig("plots/$(ticker)_3_iv_smile_smoothed.png")

plot(
    smoothed_data_no_nans.strike,
    smoothed_data_no_nans.iv,
    seriestype = :scatter,
    marker = :circle,
    xlabel = "Strike",
    ylabel = "Implied Vol (smoothed)",
    title = "Implied Volatility Smile smoothed (NaNs removed)",
    legend = false
)
savefig("plots/$(ticker)_4_iv_smile_smoothed_filtered.png")

K = Float64.(smoothed_data_no_nans.strike)
iv = Float64.(smoothed_data_no_nans.iv)

K_dense = range(minimum(K), maximum(K), length=400)
iv_dense = spl_iv.(K_dense)

plot(
    K_dense,
    iv_dense,
    label = "Spline IV",
    linewidth = 2,
    xlabel = "Strike",
    ylabel = "Implied Volatility",
    title = "Smoothed Implied Volatility (Spline)"
)

scatter!(
    K,
    iv,
    label = "Raw IV",
    markersize = 4
)

savefig("plots/$(ticker)_5_iv_spline.png")

plot(
    repriced_paritized.strike,
    repriced_paritized.price,
    seriestype = :scatter,
    marker = :circle,
    xlabel = "Strike",
    ylabel = "Price ",
    title = "Price vs Strike (Repriced with Smoothed IV)",
    legend = false
)
savefig("plots/$(ticker)_6_price_vs_strike_repriced.png")

###############
K = Float64.(repriced_paritized.strike)
price = Float64.(repriced_paritized.price)

K_dense = range(minimum(K), maximum(K), length=400)
price_dense = spl_price.(K_dense)

plot(
    K_dense,
    price_dense,
    label = "Spline Price",
    linewidth = 2,
    xlabel = "Strike",
    ylabel = "Price",
    title = "Smoothed Price (Spline)"
)

scatter!(
    K,
    price,
    label = "Raw Price",
    markersize = 4
)

savefig("plots/$(ticker)_7_price_spline.png")
##########
K = Float64.(repriced_paritized.strike)

K_dense = range(minimum(K), maximum(K), length=500)

plot(
    K_dense,
    [Breeden_Litzenberger(k, spl_price, rate, τ) for k in K_dense],
    label = "Spline Price",
    linewidth = 2,
    xlabel = "Strike",
    ylabel = "Price",
    title = "Probability Density function spline fit (Breeden-Litzenberger)"
)

savefig("plots/$(ticker)_8_pdf_spline.png")