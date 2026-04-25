using Test
using Distributions
include("../src/bs.jl")
@testset "Implied vol via Newton (newtons)" begin
    @testset "Recovers known volatility for Call" begin
        S = 100.0
        K = 100.0
        r = 0.01
        t = 0.0
        T = 1.0
        σ_true = 0.25

        bs_true = BlackScholesMerton(S, K, T, t, r, σ_true)
        market_price = bs_true(Call)

        bs_guess = BlackScholesMerton(S, K, T, t, r, 0.20)
        σ_imp = newtons(bs_guess, Call, market_price; tol=1e-10, max_iter=200)

        @test isapprox(σ_imp, σ_true; atol=1e-8, rtol=0.0)
        @test isapprox(bs_guess.σ, σ_true; atol=1e-8, rtol=0.0)
    end

    @testset "Recovers known volatility for Put" begin
        S = 100.0
        K = 90.0
        r = 0.03
        t = 0.0
        T = 0.5
        σ_true = 0.35

        bs_true = BlackScholesMerton(S, K, T, t, r, σ_true)
        market_price = bs_true(Put)

        bs_guess = BlackScholesMerton(S, K, T, t, r, 0.20)
        σ_imp = newtons(bs_guess, Put, market_price; tol=1e-10, max_iter=200)

        @test isapprox(σ_imp, σ_true; atol=1e-8, rtol=0.0)
        @test isapprox(bs_guess.σ, σ_true; atol=1e-8, rtol=0.0)
    end

    @testset "Parity consistency: call and put imply same vol" begin
        S = 120.0
        K = 110.0
        r = 0.02
        t = 0.0
        T = 0.75
        σ_true = 0.22

        bs_true = BlackScholesMerton(S, K, T, t, r, σ_true)
        call_price = bs_true(Call)
        put_price  = bs_true(Put)

        bs_call = BlackScholesMerton(S, K, T, t, r, 0.30)
        bs_put  = BlackScholesMerton(S, K, T, t, r, 0.30)

        σ_call = newtons(bs_call, Call, call_price; tol=1e-10, max_iter=200)
        σ_put  = newtons(bs_put,  Put,  put_price;  tol=1e-10, max_iter=200)

        @test isapprox(σ_call, σ_put; atol=1e-8, rtol=0.0)
        @test isapprox(σ_call, σ_true; atol=1e-8, rtol=0.0)
    end

    @testset "Throws when price is impossible (no-arbitrage)" begin
        S = 100.0
        K = 100.0
        r = 0.01
        t = 0.0
        T = 1.0

        bs_guess = BlackScholesMerton(S, K, T, t, r, 0.2)
        impossible_price = 200.0 

        @test_throws ErrorException newtons(bs_guess, Call, impossible_price; tol=1e-10, max_iter=50)
    end
end
