"""
    to_symstr(expr::Num) -> String

Convert a Symbolics.jl `Num` expression to a string compatible with
Symbolica's parser.
"""
function to_symstr(expr::Num)
    inner = SymbolicUtils.unwrap(expr)
    _to_symstr_val(inner)
end

import SymbolicUtils: issym, iscall, isadd, ismul, ispow, isdiv, operation, arguments, nameof

function _to_symstr_val(x)
    if issym(x)
        return string(nameof(x))
    elseif isadd(x)
        args = arguments(x)
        return "(" * join(_to_symstr_val.(args), " + ") * ")"
    elseif ismul(x)
        args = arguments(x)
        return "(" * join(_to_symstr_val.(args), " * ") * ")"
    elseif ispow(x)
        args = arguments(x)
        length(args) == 2 || error("Power expects 2 arguments")
        return "(" * _to_symstr_val(args[1]) * ")^(" * _to_symstr_val(args[2]) * ")"
    elseif isdiv(x)
        args = arguments(x)
        length(args) == 2 || error("Division expects 2 arguments")
        return "(" * _to_symstr_val(args[1]) * ")/(" * _to_symstr_val(args[2]) * ")"
    elseif iscall(x)
        op = operation(x)
        args = arguments(x)
        if op == (+)
            return "(" * join(_to_symstr_val.(args), " + ") * ")"
        elseif op == (*)
            return "(" * join(_to_symstr_val.(args), " * ") * ")"
        elseif op == (^)
            length(args) == 2 || error("Power expects 2 arguments, got $(length(args))")
            return "(" * _to_symstr_val(args[1]) * ")^(" * _to_symstr_val(args[2]) * ")"
        elseif op == (/)
            length(args) == 2 || error("Division expects 2 arguments")
            return "(" * _to_symstr_val(args[1]) * ")/(" * _to_symstr_val(args[2]) * ")"
        elseif op == (-)
            length(args) == 1 || error("Negation expects 1 argument")
            return "(-(" * _to_symstr_val(args[1]) * "))"
        else
            fname = string(nameof(op))
            return fname * "(" * join(_to_symstr_val.(args), ",") * ")"
        end
    else
        return _format_literal(x)
    end
end

function _format_literal(x::Integer)
    return string(x)
end

function _format_literal(x::AbstractFloat)
    return string(x)
end

function _format_literal(x::Rational)
    return "$(x.num)/$(x.den)"
end

function _format_literal(x)
    return string(x)
end
