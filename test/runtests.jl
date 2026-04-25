using OptionsImpliedPDF
using Test
using Plots

@testset "OptionsImpliedPDF.jl tests" begin
    include("../test/bstests.jl")
    include("../test/svi_test.jl")
    @test OptionsImpliedPDF.greet_your_package_name() == "Hello OptionsImpliedPDF!"
    @test OptionsImpliedPDF.greet_your_package_name() != "Hello world!"
end

