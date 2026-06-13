"""
    expand(expr::Num) -> Num

Expand a symbolic expression using Symbolica.
"""
function expand(expr::Num)
    s = to_symstr(expr)
    result_s = SymbolicaBackend._call_expand(s)
    return from_symstr(result_s)
end

"""
    factor(expr::Num) -> Num

Factor a symbolic expression over the rationals using Symbolica.
"""
function factor(expr::Num)
    s = to_symstr(expr)
    result_s = SymbolicaBackend._call_factor(s)
    return from_symstr(result_s)
end

"""
    simplify(expr::Num) -> Num

Simplify a symbolic expression using Symbolica.
"""
function simplify(expr::Num)
    s = to_symstr(expr)
    result_s = SymbolicaBackend._call_simplify(s)
    return from_symstr(result_s)
end

"""
    derivative(expr::Num, var::Num) -> Num

Compute the derivative of a symbolic expression with respect to a variable
using Symbolica.
"""
function derivative(expr::Num, var::Num)
    s = to_symstr(expr)
    var_s = to_symstr(var)
    result_s = SymbolicaBackend._call_derivative(s, var_s)
    return from_symstr(result_s)
end

"""
    substitute(expr::Num, dict::Dict) -> Num

Substitute variables in a symbolic expression according to the given
dictionary mapping.
"""
function substitute(expr::Num, dict::Dict)
    s = to_symstr(expr)
    for (k, v) in dict
        k_s = to_symstr(k)
        v_s = to_symstr(v)
        s = SymbolicaBackend._call_substitute(s, k_s, v_s)
    end
    return from_symstr(s)
end
