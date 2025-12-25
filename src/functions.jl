using Dates
using DataFrames

function greet_your_package_name()
    return "Hello Oipd!"
end

function get_τ(expiry_dt::String)
    return Float64((Date(expiry_dt) - today()).value) / 365.0
end

function paritize(spot::Float64, call_df::DataFrame, put_df::DataFrame, expiry_dt::String, rate::Float64)
    
    calls_otm = filter(:inTheMoney => ==(false), call_df)
    puts_otm = filter(:inTheMoney => ==(false), put_df)

    τ = get_τ(expiry_dt)

    puts_otm.synth_call_price = puts_otm.mid .+ spot .- puts_otm.strike * exp(-rate * τ)

    synth_calls = copy(puts_otm)
    synth_calls.price = synth_calls.synth_call_price
    calls_otm.price = calls_otm.mid

    call_price_vs_strike = calls_otm[:, [:strike, :price]]
    put_price_vs_strike = synth_calls[:, [:strike, :price]]

    paritized_data = vcat(call_price_vs_strike, put_price_vs_strike)

    return paritized_data
end


function price_to_IV(options::DataFrame, spot::Float64, rate::Float64, expiry_dt::String)

    init_guess = 0.2

    return 0.2
end

function gaussian_smooth(data::Vector{Float64}, kernel_size::Int)
    # Implement the logic to perform Gaussian smoothing
    # ...
    return smoothed_data
end

function fit_spline(data::Vector{Float64}, degree::Int)
    # Implement the logic to fit a spline to the data
    # ...
    return spline
end


function Breeden_Litzenberger(data::Vector{Float64})
    # Implement the logic to calculate Breeden-Litzenberger formula
    # ...
    return result
end


export greet_your_package_name