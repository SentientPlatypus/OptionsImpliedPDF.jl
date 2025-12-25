using Oipd
using Test
using Plots

@testset "Oipd.jl" begin

    @test Oipd.greet_your_package_name() == "Hello Oipd!"
    @test Oipd.greet_your_package_name() != "Hello world!"


    ticker = "AMD"
    expiry = Oipd.get_closest_expiry(ticker)

    # @test typeof(expiry) == String

    # call_df, put_df = Oipd.get_option_prices(ticker, expiry)
    # spot = Oipd.get_spot_price(ticker)
    # rate = 0.01

    # @test typeof(call_df) == DataFrame
    # @test typeof(put_df) == DataFrame
    # @test typeof(spot) == Float64

    # paritized = Oipd.paritize(spot, call_df, put_df, expiry, rate)
    # @test typeof(paritized) == DataFrame
    # plot!(paritized)
    # Plots.savefig("test_plot.png")


end
