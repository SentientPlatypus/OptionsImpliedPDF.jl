using Distributions

mutable struct BlackScholesMerton
    S::Float64 #underlying asset price
    K::Float64 #strike price
    T::Float64 #expiry time
    t::Float64 #current time
    r::Float64 #annualized risk free interest rate
    σ::Float64 # volatility
end

@enum OptionType begin
    Call
    Put
end

function (bs::BlackScholesMerton)(option_type::OptionType)
    """Returns the price of a European option as a solution to the black scholes PDE with boundary conditions 
    C(0,t) = 0 ∀t
    lim S → ∞ C(S,t) = S - K 
    C(S,T) = max{S-K, 0}

    for what we wanna do, this is volatility → price mapping. We want to invert this, which we will do with newtons method.
    this is literally the textbook formula on wikipedia.
    """
    S, K, T, t, r, σ = bs.S, bs.K, bs.T, bs.t, bs.r, bs.σ
    d1 = (log(S / K) + (r + 0.5 * σ^2) * (T - t)) / (σ * sqrt(T - t))
    d2 = d1 - σ * sqrt(T - t)

    if option_type == Call
        return S * cdf(Normal(), d1) - K * exp(-r * (T - t)) * cdf(Normal(), d2)
    else
        return K * exp(-r * (T - t)) * cdf(Normal(), -d2) - S * cdf(Normal(), -d1)
    end
end

function f(bs::BlackScholesMerton, option_type::OptionType, market_price::Float64)
    "f(σ) = BS(σ) - market price"
    return bs(option_type) - market_price
end

function f′(bs::BlackScholesMerton)
    "since f = BS(σ) - market price, f' = BS'(σ). This function is that: derivative of black scholes value with respect to volatility σ."
    S, K, T, t, r, σ = bs.S, bs.K, bs.T, bs.t, bs.r, bs.σ
    τ = T - t
    d1 = (log(S / K) + (r + 0.5 * σ^2) * τ) / (σ * sqrt(τ))
    return S * sqrt(τ) * pdf(Normal(), d1)
end

function newtons(bs::BlackScholesMerton, option_type::OptionType, market_price::Float64; tol=1e-6, max_iter=100, show=false)
    "Newton's method to find the implied volatility given a market price. returns the resulting σ, and updates the black scholes struct with said σ"
    σ = bs.σ 
    for i in 1:max_iter
        bs.σ = σ
        f_val = f(bs, option_type, market_price)
        f_prime_val = f′(bs)

        if abs(f_val) < tol
            bs.σ = σ
            return σ
        end

        if f_prime_val < 1e-12
            error("Vega too small; Newton unstable at strike=$(bs.K)")
        end

        σ -= f_val / f_prime_val
        σ = clamp(σ, 1e-8, 5.0)

        if show && i % 20 == 0
            @show i bs.K σ f_val f_prime_val
        end
    end
    error("Newton's method did not converge")
end