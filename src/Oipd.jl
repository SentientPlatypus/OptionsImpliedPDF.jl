module Oipd
    include(joinpath(@__DIR__, "data.jl"))
    include(joinpath(@__DIR__, "functions.jl"))
    include(joinpath(@__DIR__, "bs.jl"))
    include(joinpath(@__DIR__, "svi.jl"))

    using Plots
    using Distributions
    using Dates
    using DataFrames
    using Dierckx
    using PythonCall
    

    #top level functions that people will have access to.

    function prob_below(ticker::String, strike_price::Float64, expiry::String, savepath::String=nothing)
        """Returns the probability of the underlying asset being below the strike price at expiry. (sampled from risk-neutral pdf)"""
        spot = get_spot_price(ticker)
        call_df, put_df = get_option_prices(ticker, expiry)
        rate = 0.01
        τ = get_τ(expiry)
        F = spot * exp(rate * τ)

        paritized = paritize(spot, call_df, put_df, τ, rate)
        paritized_with_iv = add_IV_column(paritized, spot, rate, τ)
        smoothed_data = gaussian_smooth(paritized_with_iv, 5)
        smoothed_data_no_nans = remove_nans(smoothed_data)

        fit, iv_fun = fit_svi_smile(
            Float64.(smoothed_data_no_nans.strike),
            Float64.(smoothed_data_no_nans.iv),
            F, τ
            , 1e-4)

        repriced_paritized = reprice(paritized, spot, rate, τ, iv_fun)

        probability_below = p_below(
            strike_price,
            spot,
            iv_fun,
            rate,
            τ
        )

        if savepath != nothing
            strikes = range(minimum(paritized.strike), stop=maximum(paritized.strike), length=100)
            pdf_values = [Breeden_Litzenberger(k, spot, iv_fun, rate, τ) for k in strikes]


            plot(
                strikes,
                pdf_values,
                xlabel = "Strike",
                ylabel = "Density",
                title = "$(ticker) $(expiry) risk-neutral pdf",
                legend = true
            )

            line_at_spot = vline!([spot], line=:dash, label="Spot Price: $(spot)")

            savefig(savepath)
        end


        return probability_below
    end

    function prob_at_or_above(ticker::String, strike_price::Float64, expiry::String, savepath::String=nothing)
        """Returns the probability of the underlying asset being at or above the strike price at expiry. (sampled from risk-neutral pdf)"""
        return 1 - prob_below(ticker, strike_price, expiry, savepath)
    end

    export plot_pdf
    export prob_at_or_above
    export prob_below
    export get_closest_expiry

end