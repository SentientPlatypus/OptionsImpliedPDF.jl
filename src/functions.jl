using Dates
using DataFrames
using Dierckx

include("bs.jl")

function greet_your_package_name()
    return "Hello Oipd!"
end

function get_τ(expiry_dt::String)
    return Float64((Date(expiry_dt) - today()).value) / 365.0
end

function paritize(spot::Float64, call_df::DataFrame, put_df::DataFrame, expiry_dt::String, rate::Float64)
    
    calls_otm = filter(:inTheMoney => ==(false), call_df)
    puts_otm = filter(:inTheMoney => ==(false), put_df)

    println(names(call_df))

    τ = get_τ(expiry_dt)

    puts_otm.synth_call_price = puts_otm.mid .+ spot .- puts_otm.strike * exp(-rate * τ)

    synth_calls = copy(puts_otm)
    synth_calls.price = synth_calls.synth_call_price
    calls_otm.price = calls_otm.mid

    call_price_vs_strike = calls_otm[:, [:strike, :price]]
    put_price_vs_strike = synth_calls[:, [:strike, :price]]

    paritized_data = vcat(call_price_vs_strike, put_price_vs_strike)
    sort!(paritized_data, :strike)


    return paritized_data
end


function add_IV_column(paritized::DataFrame, spot::Float64, rate::Float64, expiry_dt::String)
    "Adds an implied volatility column to the paritized dataframe using newtons method."

    τ = get_τ(expiry_dt)
    t = 0.0
    T = τ

    paritized.iv = Vector{Float64}(undef, nrow(paritized))

    for (i, row) in enumerate(eachrow(paritized))
        K = Float64(row.strike)
        mkt = Float64(row.price) 
        show_logs = i % 50 == 0

        bs = BlackScholesMerton(spot, K, T, t, rate, 0.20)

        paritized.iv[i] = try
            newtons(bs, Call, mkt; tol=1e-8, max_iter=200, show=show_logs)
        catch
            NaN
        end
    end

    return paritized
end

function gaussian_smooth(paritized_with_iv::DataFrame, kernel_size::Int)
    N = nrow(paritized_with_iv)

    strikes = paritized_with_iv.strike
    values  = paritized_with_iv.iv

    smoothed = similar(values)

    for i in 1:N
        j_min = max(1, i - kernel_size)
        j_max = min(N, i + kernel_size)

        weights_sum = 0.0
        value_sum   = 0.0

        for j in j_min:j_max
            w = exp(- (i - j)^2 / (2 * kernel_size^2))
            weights_sum += w
            value_sum   += w * values[j]
        end

        smoothed[i] = value_sum / weights_sum
    end

    return DataFrame(
        strike = strikes,
        iv = smoothed
    )
end

function remove_nans(data::DataFrame)
    filtered = filter(row -> isfinite(row.iv), data)
    return filtered
end

function fit_iv_spline(smoothed_data::DataFrame, s=1e-4)
    K = Float64.(smoothed_data.strike)
    iv = Float64.(smoothed_data.iv)
    spl = Spline1D(K, iv; k=3, s=s)

    return spl
end

function reprice(paritized::DataFrame, spot::Float64, rate::Float64, expiry_dt::String, fit_fn)
    """Given a fit_fn that was fitted in the iv-space, reprice the paritized data using black scholes, ensuring a smooth price curve."""
    τ = get_τ(expiry_dt)
    t = 0.0

    prices = Vector{Float64}(undef, nrow(paritized))

    for (i, row) in enumerate(eachrow(paritized))
        K = Float64(row.strike)
        σ = fit_fn(K)

        bs = BlackScholesMerton(spot, K, τ, t, rate, σ)
        prices[i] = bs(Call)
    end

    return DataFrame(
        strike = paritized.strike,
        price = prices
    )
end

function fit_price_spline(paritized::DataFrame, s=1e-4)
    K = Float64.(paritized.strike)
    prices = Float64.(paritized.price)
    spl = Spline1D(K, prices; k=3, s=s)

    return spl
end


function Breeden_Litzenberger(k::Float64, spl_price::Spline1D, rate::Float64, expiry_dt::String)
    """Using the Breeden_Litzenberger forrmula, this computes the risk-neutral PDF at strike k given a price spline."""
    T = get_τ(expiry_dt)
    d2C = derivative(spl_price, k, 2)
    q = exp(rate * T) * d2C
    return q
end

function Breeden_Litzenberger(K::Float64, spot::Float64, iv_fun::Function, r::Float64, expiry_dt::String, h::Float64 = 0.001)
    "Using the Breeden_Litzenberger forrmula, this computes the risk-neutral PDF at strike k given a function iv_fun:σ→price"
    T = get_τ(expiry_dt)

    C(Kx) = BlackScholesMerton(spot, Kx, T, 0.0, r, iv_fun(Kx))(Call)

    d2C = (C(K+h) - 2C(K) + C(K-h)) / h^2
    return exp(r*T) * d2C
end



export greet_your_package_name