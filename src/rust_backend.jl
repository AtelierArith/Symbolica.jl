module SymbolicaBackend

using RustCall

const _GENERATED = joinpath(@__DIR__, "generated", "SymbolicaNative.jl")
isfile(_GENERATED) || error("Symbolica native bindings not found. Run `Pkg.build(\"Symbolica\")` first.")
include(_GENERATED)

_ok(result::RustCall.RustResult) = RustCall.is_ok(result) ? RustCall.unwrap(result) : throw(ArgumentError(result.value))

function expression(input::AbstractString)
    handle = SymbolicaNative.Expression()
    _ok(SymbolicaNative.set(handle, String(input)))
    return handle
end

end
