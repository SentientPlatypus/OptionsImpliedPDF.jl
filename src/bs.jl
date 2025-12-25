using Distributions

mutable struct BlackScholesMerton
    S::Float64 #underlying asset price
    K::Float64 #strike price
    T::Float64 #expiry time
    t::Float64 #current time
    r::Float64 #annualized risk free interest rate
    σ::Float64 #standard deviation of stock returns
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