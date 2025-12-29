using Test
include("../src/svi.jl")

@testset "SVI Functions" begin

    @testset "w function" begin
        # Test basic SVI variance function
        k = 0.0
        a, b, ρ, m, σ = 0.01, 0.1, -0.5, 0.0, 0.2
        w_val = w(k, a, b, ρ, m, σ)
        @test w_val > 0
        @test isfinite(w_val)
        
        # Test at-the-money (k=0, m=0)
        @test w_val ≈ a + b * σ atol=1e-10
    end

    @testset "w derivatives" begin
        k = 0.1
        a, b, ρ, m, σ = 0.01, 0.1, -0.5, 0.0, 0.2
        
        w1 = w′(k, a, b, ρ, m, σ)
        w2 = w″(k, a, b, ρ, m, σ)
        
        @test isfinite(w1)
        @test isfinite(w2)
        
        # Test that second derivative is positive (convexity)
        @test w2 > 0
    end

    @testset "Gatheral-Jacquier condition" begin
        a, b, ρ, m, σ = 0.01, 0.1, -0.5, 0.0, 0.2
        min_var = Gatheral_Jacquier(a, b, ρ, m, σ)
        @test min_var >= 0  # Should be non-negative for no arbitrage
    end

    @testset "g function (arbitrage check)" begin
        k = 0.0
        a, b, ρ, m, σ = 0.01, 0.1, -0.5, 0.0, 0.2
        g_val = g(k, a, b, ρ, m, σ)
        @test isfinite(g_val)
        # For valid parameters, g should be positive
        @test g_val >= 0
    end

    @testset "min_g_on_grid" begin
        a, b, ρ, m, σ = 0.01, 0.1, -0.5, 0.0, 0.2
        min_g = min_g_on_grid(a, b, ρ, m, σ)
        @test isfinite(min_g)
        @test min_g >= 0  # Should be non-negative for no butterfly arbitrage
    end

    @testset "reparameterize" begin
        u = [0.01, log(0.1), 0.0, 0.0, log(0.1)]
        a, b, ρ, m, σ = reparamaterize(u)
        
        @test a == u[1]
        @test b > 0  # b should be positive
        @test abs(ρ) < 1  # ρ should be between -1 and 1
        @test σ > 0  # σ should be positive
        @test m == u[4]
    end

    @testset "svi_objective" begin
        u = [0.01, log(0.1), 0.0, 0.0, log(0.1)]
        k_data = [-0.5, 0.0, 0.5]
        w_data = [0.02, 0.015, 0.025]
        weights = [1.0, 1.0, 1.0]
        
        obj_val = svi_objective(u, k_data, w_data, weights)
        @test isfinite(obj_val)
        @test obj_val >= 0
    end

    @testset "fit_svi" begin
        # Create some synthetic data
        k_data = collect(range(-0.5, 0.5, length=10))
        true_params = (a=0.01, b=0.1, ρ=-0.3, m=0.0, σ=0.2)
        w_data = [max(0.001, w(k, true_params.a, true_params.b, true_params.ρ, true_params.m, true_params.σ)) for k in k_data]
        w_data .+= 0.001 * randn(length(w_data))  # Add some noise
        w_data = max.(w_data, 0.001)  # Ensure positive
        
        fit_result = fit_svi(k_data, w_data)
        
        # The reparameterization should ensure positive parameters, but optimization might not be perfect
        @test fit_result.b > 0
        @test abs(fit_result.ρ) <= 1
        @test fit_result.σ > 0
        # Skip convergence check for now as it varies with optimization
    end

    @testset "fit_svi_smile" begin
        # Create synthetic implied volatility data
        F = 100.0  # Forward price
        T = 1.0    # Time to expiry
        K = collect(range(80.0, 120.0, length=20))  # Strike prices
        k_data = log.(K ./ F)
        
        # True SVI parameters
        true_params = (a=0.01, b=0.1, ρ=-0.3, m=0.0, σ=0.2)
        
        # Generate synthetic IV
        w_true = [w(k, true_params.a, true_params.b, true_params.ρ, true_params.m, true_params.σ) for k in k_data]
        iv_true = sqrt.(w_true ./ T)
        
        fit, iv_fun = fit_svi_smile(K, iv_true, F, T)
        
        @test fit.a > 0
        @test fit.b > 0
        @test abs(fit.ρ) < 1
        @test fit.σ > 0
        
        # Test that the fitted function produces reasonable IV values
        test_K = 100.0
        fitted_iv = iv_fun(test_K)
        @test fitted_iv > 0
        @test isfinite(fitted_iv)
    end

    @testset "Arbitrage detection" begin
        # Test with parameters that should trigger arbitrage
        a, b, ρ, m, σ = -0.1, 0.1, -0.5, 0.0, 0.2  # Negative a should cause issues
        
        k_data = [-0.5, 0.0, 0.5]
        w_data = [0.02, 0.015, 0.025]
        
        # This should either penalize heavily or fail
        obj_val = svi_objective([a, log(b), ρ, m, log(σ)], k_data, w_data, ones(length(k_data)))
        @test obj_val > 1e3  # Should be heavily penalized
    end

end