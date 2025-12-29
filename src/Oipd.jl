module Oipd
    include(joinpath(@__DIR__, "data.jl"))
    include(joinpath(@__DIR__, "functions.jl"))
    include(joinpath(@__DIR__, "bs.jl"))
    include(joinpath(@__DIR__, "svi.jl"))
    include(joinpath(@__DIR__, "plotting.jl"))

    using Plots
    using Distributions
    using Dates
    using DataFrames
    using PythonCall
    

    #top level functions that people will have access to.

    function prob_below(ticker::String, strike_price::Float64, expiry::String, savedir::String=nothing)
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


        #plotting logic
        if savedir != nothing
            dir = "$(savedir)/$(ticker)/$(expiry)"
            make_dir_if_not_exists(dir)
            plot_paritized_prices(paritized, ticker, dir)
            plot_iv_smile(paritized_with_iv, ticker, dir)
            plot_smoothed_iv(smoothed_data, ticker, dir)
            plot_smoothed_iv_filtered(smoothed_data_no_nans, ticker, dir)
            plot_svi_fit(smoothed_data_no_nans, iv_fun, ticker, dir)
            plot_repriced_prices(repriced_paritized, ticker, dir)
            plot_pdf_numerical(repriced_paritized, spot, iv_fun, rate, τ, ticker, dir)
        end


        return probability_below
    end

    function prob_at_or_above(ticker::String, strike_price::Float64, expiry::String, savedir::String=nothing)
        """Returns the probability of the underlying asset being at or above the strike price at expiry. (sampled from risk-neutral pdf)"""
        return 1 - prob_below(ticker, strike_price, expiry, savedir)
    end

    export plot_pdf
    export prob_at_or_above
    export prob_below
    export get_closest_expiry

end