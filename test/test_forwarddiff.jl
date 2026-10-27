using Onyx
using ForwardDiff
using Test
using Oceananigans.Units: day

@testset "ForwardDiff Onyx tendency smoke tests" begin
    function p_1_tendency_with_growth_rate(mu)
        T = typeof(mu)
        bgc = Onyx.construct(;
            scalar_type=T,
            parameters=(; maximum_growth_rate=[mu, T(0.7 / day)]),
        )

        N = T(7.0)
        D = T(1.0)
        Z_1 = T(0.05)
        Z_2 = T(0.05)
        P_1 = T(0.01)
        P_2 = T(0.01)
        PAR = T(100.0)

        return bgc(Val(:P_1), 0, 0, 0, 0, N, D, P_1, P_2, Z_1, Z_2, PAR)
    end

    mu0 = 0.7 / day
    T0 = typeof(mu0)
    bgc0 = Onyx.construct(;
        scalar_type=T0,
        parameters=(; maximum_growth_rate=[mu0, T0(0.7 / day)]),
    )
    @test eltype(bgc0.parameters.maximum_growth_rate) === T0

    dP_1_dmu = ForwardDiff.derivative(p_1_tendency_with_growth_rate, mu0)
    @test isfinite(dP_1_dmu)

    δ = mu0 * 1e-6
    fd =
        (p_1_tendency_with_growth_rate(mu0 + δ) - p_1_tendency_with_growth_rate(mu0 - δ)) /
        (2δ)
    @test isapprox(dP_1_dmu, fd; rtol=1e-4, atol=1e-10)
end

