using Agate
using Onyx
using Test
using OceanBioME: BoxModelGrid
using Oceananigans.Biogeochemistry: required_biogeochemical_tracers
using Agate.Construction: export_recipe, import_recipe

@testset "Onyx recipes" begin
    bgc, recipe = Onyx.construct_plus_recipe(;
        size_structure=(;
            phytoplankton=(diat=[2.0, 8.0],),
            zooplankton=(microzoo=[30.0, 90.0],),
        ),
        parameters=(detritus_remineralization=1e-5,),
        grid=BoxModelGrid(Float32),
    )
    @test recipe.family == :Onyx
    mktemp() do path, io
        close(io)
        export_recipe(path, recipe)
        imported = import_recipe(path)
        @test imported == recipe
        replayed = Onyx.construct(imported; grid=BoxModelGrid(Float32))
        @test required_biogeochemical_tracers(replayed) ==
              required_biogeochemical_tracers(bgc)
        @test replayed.parameters == bgc.parameters
    end
end
