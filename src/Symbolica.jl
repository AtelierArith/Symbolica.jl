module Symbolica

using Symbolics
using SymbolicUtils
using RustCall

export expand, factor, simplify, derivative, substitute
export NativeExpression, expand!, factor!, simplify!, derivative!, substitute!

include("rust_backend.jl")
include("convert_to_symbolica.jl")
include("convert_from_symbolica.jl")
include("operations.jl")

end # module Symbolica
