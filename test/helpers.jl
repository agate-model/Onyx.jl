using Test
using Agate
using Onyx
using Agate.Library.Allometry: AllometricParam, ConstantParam, PowerLaw
using Oceananigans.Units: day
import Oceananigans.Architectures: architecture, CPU

struct DummyGrid{T, Arch}
    arch::Arch
end
Base.eltype(::DummyGrid{T, Arch}) where {T, Arch} = T
architecture(grid::DummyGrid) = grid.arch
dummy_grid(::Type{T}; arch=CPU()) where {T<:AbstractFloat} = DummyGrid{T,typeof(arch)}(arch)

function argument_error_message(f)
    err = try
        f()
        nothing
    catch caught
        caught
    end
    @test err isa ArgumentError
    return err isa Exception ? sprint(showerror, err) : ""
end

onyx_named_size_structure() = (;
    phytoplankton=(diat=[2.0, 5.0, 10.0], dino=[8.0, 20.0]),
    zooplankton=(microzoo=[30.0, 60.0], mesozoo=[100.0]),
)

onyx_test_state(::Type{T}=Float64) where {T<:AbstractFloat} = (;
    N=T(7), D=T(1), P_1=T(0.01), P_2=T(0.01), Z_1=T(0.05), Z_2=T(0.05),
)

function onyx_runtime_args(::Type{T}=Float64; PAR=100) where {T<:AbstractFloat}
    return (0, 0, 0, 0, values(onyx_test_state(T))..., T(PAR))
end
