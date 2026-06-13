"""
    from_symstr(s::String) -> Num

Convert a Symbolica output string back to a Symbolics.jl `Num` expression.
"""
function from_symstr(s::String)
    # Normalize Symbolica output to Julia-compatible syntax
    # Symbolica uses explicit "*" (e.g., "2*x"), Julia uses implicit (e.g., "2x")
    normalized = _normalize_symbolica_output(s)
    ex = Meta.parse(normalized)
    return parse_expr_to_symbolic(ex, @__MODULE__)
end

function _normalize_symbolica_output(s::String)
    # Symbolica uses explicit "*" (e.g., "2*x*y").
    # Keep explicit "*" to avoid Julia parsing ambiguities (e.g., "x^2*y" → "x^(2y)" in Julia).
    # No normalization needed for MVP.
    return s
end
