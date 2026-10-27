using Agate
using Onyx
using OceanBioME:
    Biogeochemistry, BoxModelGrid, BoxModel, PrescribedPhotosyntheticallyActiveRadiation
using Oceananigans: set!, time_step!
using Oceananigans.Fields: ConstantField
using Oceananigans.Units: day
using Test

const ONYX_REFERENCE_TRACERS = (:N, :D, :Z_1, :Z_2, :P_1, :P_2)
const ONYX_REFERENCE_INITIAL = (
    N=7.0,
    D=0.01,
    Z_1=0.01,
    Z_2=0.02,
    P_1=0.01,
    P_2=0.1,
)
const ONYX_REFERENCE_DT = day / 48
const ONYX_REFERENCE_SAVE_EVERY = 12
const ONYX_REFERENCE_RTOL = 1e-12
const ONYX_REFERENCE_ATOL = 1e-14

reference_path = joinpath(
    @__DIR__, "reference", "onyx_definition_v0.2.0_reference.csv"
)
isfile(reference_path) || error(
    "Onyx reference trajectory is missing at $reference_path. " *
    "Generate it with `julia --project=. scripts/generate_onyx_reference.jl` " *
    "and commit the generated CSV."
)
reference_rows = filter(
    row -> !isempty(row) && !startswith(row, '#'),
    readlines(reference_path),
)
header = Symbol.(split(first(reference_rows), ','))
reference = map(reference_rows[2:end]) do row
    values = parse.(Float64, split(row, ','))
    return NamedTuple{Tuple(header)}(Tuple(values))
end

@testset "Onyx definition v0.2.0 reference trajectory" begin
    @test Tuple(header) == (:time_days, :total_nitrogen, ONYX_REFERENCE_TRACERS...)
    @test [row.time_days for row in reference] == collect(0.0:0.25:60.0)

    grid = BoxModelGrid()
    bgc = Onyx.construct()
    light_attenuation = PrescribedPhotosyntheticallyActiveRadiation(ConstantField(100.0))
    bgc_model = Biogeochemistry(bgc; light_attenuation)
    box_model = BoxModel(; biogeochemistry=bgc_model)
    set!(box_model; ONYX_REFERENCE_INITIAL...)

    mismatches = NamedTuple[]

    function check_reference_state(row)
        for tracer in ONYX_REFERENCE_TRACERS
            actual = Float64(getproperty(box_model.fields, tracer).data[1, 1, 1])
            expected = getproperty(row, tracer)
            isapprox(
                actual,
                expected;
                rtol=ONYX_REFERENCE_RTOL,
                atol=ONYX_REFERENCE_ATOL,
            ) && continue

            push!(
                mismatches,
                (;
                    time_days=row.time_days,
                    tracer,
                    actual,
                    expected,
                    absolute_error=abs(actual - expected),
                ),
            )
        end
    end

    check_reference_state(reference[1])

    for row in reference[2:end]
        for _ in 1:ONYX_REFERENCE_SAVE_EVERY
            time_step!(box_model, ONYX_REFERENCE_DT)
        end
        check_reference_state(row)
    end

    if !isempty(mismatches)
        worst = mismatches[argmax(getproperty.(mismatches, :absolute_error))]
        @info "Onyx trajectory mismatch" count=length(mismatches) time_days=worst.time_days tracer=worst.tracer actual=worst.actual expected=worst.expected absolute_error=worst.absolute_error
    end

    @test isempty(mismatches)
end
