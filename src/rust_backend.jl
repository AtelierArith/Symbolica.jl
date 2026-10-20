module SymbolicaBackend

# The facade crate (rust/) exposes `#[julia] fn(String) -> String` entry points.
# `deps/build.jl` builds it and writes precompilable bindings with
# RustCall.write_bindings_to_file; loading them here keeps Symbolica.jl
# precompilable (no code generation at load time).
const _GENERATED = joinpath(@__DIR__, "generated", "SymbolicaNative.jl")

if !isfile(_GENERATED)
    error("""
          Symbolica native bindings not found at $_GENERATED.
          Run `Pkg.build("Symbolica")` first.
          """)
end

include(_GENERATED)
using .SymbolicaNative: symbolica_expand, symbolica_factor, symbolica_simplify,
                        symbolica_derivative, symbolica_substitute

"""
    _call_expand(input::AbstractString) -> String
"""
_call_expand(input::AbstractString) = symbolica_expand(input)

"""
    _call_factor(input::AbstractString) -> String
"""
_call_factor(input::AbstractString) = symbolica_factor(input)

"""
    _call_simplify(input::AbstractString) -> String
"""
_call_simplify(input::AbstractString) = symbolica_simplify(input)

"""
    _call_derivative(input::AbstractString, var::AbstractString) -> String
"""
_call_derivative(input::AbstractString, var::AbstractString) = symbolica_derivative(input, var)

"""
    _call_substitute(input::AbstractString, var::AbstractString, replacement::AbstractString) -> String
"""
_call_substitute(input::AbstractString, var::AbstractString, replacement::AbstractString) =
    symbolica_substitute(input, var, replacement)

end # module SymbolicaBackend
