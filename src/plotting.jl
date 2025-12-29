using Plots


function make_dir_if_not_exists(dir::String)
    if !isdir(dir)
        mkpath(dir)
    end
end

function plot_paritized_prices(paritized, ticker, dir::String)
    plot(
        paritized.strike,
        paritized.price,
        seriestype = :scatter,
        marker = :circle,
        xlabel = "Strike",
        ylabel = "Price",
        title = "$(ticker) Paritized Option Prices",
        legend = false
    )
    savefig("$(dir)/1_paritized_plot.png")
end

function plot_iv_smile(paritized_with_iv, ticker, dir::String)
    plot(
        paritized_with_iv.strike,
        paritized_with_iv.iv,
        seriestype = :scatter,
        marker = :circle,
        xlabel = "Strike",
        ylabel = "Implied Vol",
        title = "$(ticker) Implied Volatility Smile",
        legend = false
    )
    savefig("$(dir)/2_iv_smile.png")
end

function plot_smoothed_iv(smoothed_data, ticker, dir::String)
    plot(
        smoothed_data.strike,
        smoothed_data.iv,
        seriestype = :scatter,
        marker = :circle,
        xlabel = "Strike",
        ylabel = "Implied Vol (smoothed)",
        title = "$(ticker) Implied Volatility Smile smoothed",
        legend = false
    )
    savefig("$(dir)/3_iv_smile_smoothed.png")
end

function plot_smoothed_iv_filtered(smoothed_data_no_nans, ticker, dir::String)
    plot(
        smoothed_data_no_nans.strike,
        smoothed_data_no_nans.iv,
        seriestype = :scatter,
        marker = :circle,
        xlabel = "Strike",
        ylabel = "Implied Vol (smoothed)",
        title = "$(ticker) Implied Volatility Smile smoothed (NaNs removed)",
        legend = false
    )
    savefig("$(dir)/4_iv_smile_smoothed_filtered.png")
end

function plot_svi_fit(smoothed_data_no_nans, iv_fun, ticker, dir::String)
    K = Float64.(smoothed_data_no_nans.strike)
    iv = Float64.(smoothed_data_no_nans.iv)
    K_dense = range(minimum(K), maximum(K), length=400)
    iv_dense = iv_fun.(K_dense)
    plot(
        K_dense,
        iv_dense,
        label = "SVI fitted IV",
        linewidth = 2,
        xlabel = "Strike",
        ylabel = "Implied Volatility",
        title = "$(ticker) Smoothed Implied Volatility (SVI fit)"
    )
    scatter!(
        K,
        iv,
        label = "Raw IV",
        markersize = 4
    )
    savefig("$(dir)/5_iv_svi.png")
end

function plot_repriced_prices(repriced_paritized, ticker, dir::String)
    plot(
        repriced_paritized.strike,
        repriced_paritized.price,
        seriestype = :scatter,
        marker = :circle,
        xlabel = "Strike",
        ylabel = "Price ",
        title = "$(ticker) Price vs Strike (Repriced with Smoothed IV)",
        legend = false
    )
    savefig("$(dir)/6_price_vs_strike_repriced.png")
end

function plot_pdf_numerical(repriced_paritized, spot, iv_fun, rate, τ, ticker, dir::String)
    K = Float64.(repriced_paritized.strike)
    K_dense = range(minimum(K), maximum(K), length=500)
    plot(
        K_dense,
        [Breeden_Litzenberger(k, spot, iv_fun, rate, τ) for k in K_dense],
        label = "exp(rτ)d^2C/dK^2",
        linewidth = 2,
        xlabel = "Strike",
        ylabel = "Price",
        title = "$(ticker) Probability Density function numerical (Breeden-Litzenberger)",
        legend = true
    )


    line_at_spot = vline!([spot], line=:dash, label="Spot Price: $(spot)")

    savefig("$(dir)/7_pdf_numerical.png")
end