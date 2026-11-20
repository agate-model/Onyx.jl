# Onyx.jl

A size-structured nitrogen–phytoplankton–zooplankton–detritus ecosystem model built with [Agate.jl](https://github.com/agate-model/Agate.jl).

Onyx provides the scientific definition, model construction, and recipe replay. Agate supplies the shared construction and compilation machinery.

## Usage

```julia
using Onyx

bgc = Onyx.construct()

bgc, recipe = Onyx.construct_plus_recipe()
replayed = Onyx.construct(recipe)
```

The model supports configurable size structure and parameter overrides.

## Installation

```julia
using Pkg
Pkg.add("Onyx")
```

## Development

Run the tests from the repository root:

```julia
using Pkg
Pkg.activate(".")
Pkg.test()
```

Examples and tutorials are available in the [Agate documentation](https://agate-model.github.io/Agate.jl/dev/).