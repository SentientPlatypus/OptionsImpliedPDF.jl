function w(k::Float64, a::Float64, b::Float64, ρ::Float64, m::Float64, σ::Float64)
    """w(k) = a + b( ρ(k-m) + sqrt((k-m)^2 + σ^2) )"""
    x = k - m
    return a + b * (ρ * x + sqrt(x*x + σ*σ))
end

function w′(k::Float64, a::Float64, b::Float64, ρ::Float64, m::Float64, σ::Float64)
    "first derivative of w wrt k"
    x = k - m
    s = sqrt(x*x + σ*σ)
    return b * (ρ + x / s)
end

function w″(k::Float64, a::Float64, b::Float64, ρ::Float64, m::Float64, σ::Float64)
    "second derivative of w wrt k"
    x = k - m
    s = sqrt(x*x + σ*σ)
    return b * (σ*σ) / (s^3)
end

function Gatheral_Jacquier(a::Float64, b::Float64, ρ::Float64, m::Float64, σ::Float64)
    return a + b*σ*sqrt(1 - ρ*ρ)
end

function g(k::Float64, a::Float64, b::Float64, ρ::Float64, m::Float64, σ::Float64)
    w_val = w(k, a, b, ρ, m, σ)

    if !(isfinite(w_val)) || w_val <= 0
        return -Inf
    end

    w1 = w′(k, a, b, ρ, m, σ)
    w2 = w″(k, a, b, ρ, m, σ)

    t1 = (1 - (k * w1) / (2 * w_val))^2
    t2 = - (w1^2) / 4 * (1 / w_val + 1 / 4)
    t3 = + w2 / 2

    return t1 + t2 + t3
end

function min_g_on_grid(a::Float64, b::Float64, ρ::Float64, m::Float64, σ::Float64, kmin::Float64=-1.5, kmax::Float64=1.5, n::Int=401)
    min_g = Inf
    for k in range(kmin, kmax, length=n)
        gk = g(Float64(k), a, b, ρ, m, σ)
        min_g = min(min_g, gk)
    end
    return min_g
end

function reparamaterize(u::Vector{Float64}, ρ_bound::Float64=0.999, σ_min::Float64=1e-4)
    "this reparamaterizes so b≥0, |ρ|<ρ_bound, σ≥σ_min."
    a_raw, b_raw, ρ_raw, m_raw, σ_raw = u

    a = a_raw
    b = exp(b_raw)
    ρ = ρ_bound * tanh(ρ_raw)
    m = m_raw
    σ = σ_min + exp(σ_raw)

    return a, b, ρ, m, σ
end

function svi_objective(u::Vector{Float64}, k_data::Vector{Float64}, w_data::Vector{Float64}, weights::Vector{Float64})
    "this is the objective function. literally ORIE again lol. THis is what we MINIMIZE."
    a, b, ρ, m, σ = reparamaterize(u)

    penalty = 0.0

    minvar = Gatheral_Jacquier(a, b, ρ, m, σ)
    if minvar < 0
        penalty += 1e6 * minvar^2
    end


    for k in k_data
        ŵ = w(k, a, b, ρ, m, σ)
        if !(isfinite(ŵ)) || ŵ <= 0
            penalty += 1e6
        end
    end

    sse = 0.0
    for i in eachindex(k_data)
        ŵ = w(k_data[i], a, b, ρ, m, σ)
        err = ŵ - w_data[i]
        sse += weights[i] * err^2
    end

    return sse + penalty
end

using Optim

function fit_svi(k_data::Vector{Float64}, w_data::Vector{Float64}, weights::Vector{Float64}=ones(length(k_data)), maxiter::Int=4000)
    "Fits the SVI model to the given data and objective function (svi objective). returns the fitted parameters a, b, ρ, m, σ and the optimization result."
    u0 = [
        minimum(w_data) * 0.5,   # a
        log(0.1),                # b
        0.0,                     # ρ
        0.0,                     # m
        log(0.1)                 # σ
    ]

    obj(u) = svi_objective(u, k_data, w_data, weights)

    opts = Optim.Options(iterations = maxiter)
    result = Optim.optimize(obj, u0, NelderMead(), opts)

    û = Optim.minimizer(result)
    a, b, ρ, m, σ = reparamaterize(û)

    return (a=a, b=b, ρ=ρ, m=m, σ=σ, result=result)
end

function fit_svi_smile(K::Vector{Float64}, iv::Vector{Float64}, F::Float64, T::Float64, k_extend::Float64=0.6)


    idx = findall(i -> isfinite(K[i]) && isfinite(iv[i]) && iv[i] > 0, eachindex(K))
    Kc = K[idx]
    ivc = iv[idx]

    k_data = log.(Kc ./ F)
    w_data = (ivc .^ 2) .* T

    fit = fit_svi(k_data, w_data)

    kmin = minimum(k_data) - k_extend
    kmax = maximum(k_data) + k_extend
    mg = min_g_on_grid(fit.a, fit.b, fit.ρ, fit.m, fit.σ, kmin, kmax)

    if mg < 0
        error("SVI butterfly arbitrage detected: min g(k) = $mg")
    end

    iv_fun = (Kq::Float64) -> begin
        k = log(Kq / F)
        sqrt(max(w(k, fit.a, fit.b, fit.ρ, fit.m, fit.σ), 0.0) / T)
    end

    return fit, iv_fun
end
