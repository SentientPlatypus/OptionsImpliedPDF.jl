using Dates
using DataFrames

include("bs.jl")

function greet_your_package_name()
    return "Hello Oipd!"
end

function get_τ(expiry_dt::String)
    return Float64((Date(expiry_dt) - today()).value) / 365.0
end

function paritize(spot::Float64, call_df::DataFrame, put_df::DataFrame, τ::Float64, rate::Float64)
    
    calls_otm = filter(:inTheMoney => ==(false), call_df)
    puts_otm = filter(:inTheMoney => ==(false), put_df)

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


function add_IV_column(paritized::DataFrame, spot::Float64, rate::Float64, τ::Float64)
    "Adds an implied volatility column to the paritized dataframe using newtons method."

    paritized.iv = Vector{Float64}(undef, nrow(paritized))

    for (i, row) in enumerate(eachrow(paritized))
        K = Float64(row.strike)
        mkt = Float64(row.price) 
        show_logs = i % 50 == 0

        bs = BlackScholesMerton(spot, K, τ, 0.0, rate, 0.20)

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

function reprice(paritized::DataFrame, spot::Float64, rate::Float64, τ::Float64, fit_fn)
    """Given a fit_fn that was fitted in the iv-space, reprice the paritized data using black scholes, ensuring a smooth price curve."""

    prices = Vector{Float64}(undef, nrow(paritized))

    for (i, row) in enumerate(eachrow(paritized))
        K = Float64(row.strike)
        σ = fit_fn(K)

        bs = BlackScholesMerton(spot, K, τ, 0.0, rate, σ)
        prices[i] = bs(Call)
    end

    return DataFrame(
        strike = paritized.strike,
        price = prices
    )
end

# function fit_price_spline(paritized::DataFrame, s=1e-4)
#     K = Float64.(paritized.strike)
#     prices = Float64.(paritized.price)
#     spl = Spline1D(K, prices; k=3, s=s)

#     return spl
# end


# function Breeden_Litzenberger(k::Float64, spl_price::Spline1D, rate::Float64, τ::Float64)
#     """Using the Breeden_Litzenberger forrmula, this computes the risk-neutral PDF at strike k given a price spline. 
#     r is the risk-free rate, τ is time to expiry in years.
#     """
#     d2C = derivative(spl_price, k, 2)
#     q = exp(rate * τ) * d2C
#     return q
# end

function Breeden_Litzenberger(K::Float64, spot::Float64, iv_fun::Function, r::Float64, τ::Float64, h::Float64 = 0.001)
    "Using the Breeden_Litzenberger forrmula, this computes the risk-neutral PDF at strike k given a function iv_fun:σ→price
    r is the risk-free rate, τ is time to expiry in years."

    C(Kx) = BlackScholesMerton(spot, Kx, τ, 0.0, r, iv_fun(Kx))(Call)

    if K <= h
        d2C = (C(K + 2h) - 2C(K + h) + C(K)) / (h^2)
    else
        d2C = (C(K + h) - 2C(K) + C(K - h)) / (h^2)
    end
    return exp(r*τ) * d2C
end


function p_at_or_above(K::Float64, spot::Float64, iv_fun::Function, r::Float64, τ::Float64)
    "Computes the risk-neutral probability that the underlying will be above strike K at expiry using the Breeden-Litzenberger formula.
    This is done by taking the cdf at K, and subtracting it from 1."
    return 1.0 - p_below(K, spot, iv_fun, r, τ)
end


function p_below(K::Float64, spot::Float64, iv_fun::Function, r::Float64, τ::Float64)
    "Computes the risk-neutral probability that the underlying will be below strike K at expiry using the Breeden-Litzenberger formula.
    This is done by integrating the risk-neutral PDF from 0 to K. using the trapezoidel rule.
    This is the cdf at K."

    integrand(k) = Breeden_Litzenberger(k, spot, iv_fun, r, τ)

    lower_limit = 1.0
    num_points = 10000
    dk = (K - lower_limit) / num_points

    integral = 0.0
    for i in 0:(num_points - 1)
        k1 = lower_limit + i * dk
        k2 = lower_limit + (i + 1) * dk
        integral += 0.5 * (integrand(k1) + integrand(k2)) * dk
    end

    return integral
end


export greet_your_package_name