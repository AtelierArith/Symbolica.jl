"""
    NativeExpression(expr::Num)

Keep an expression in Rust across operations. Use `expand!`, `factor!`,
`simplify!`, `derivative!`, and `substitute!`, then `convert(Num, expr)` to
return to Symbolics. The owned Rust value is released by its finalizer.
"""
struct NativeExpression
    handle::SymbolicaBackend.SymbolicaNative.Expression
end
function NativeExpression(expr::Num)
    value = SymbolicUtils.unwrap(expr)
    if value isa Integer && typemin(Int64) <= value <= typemax(Int64)
        handle = SymbolicaBackend.SymbolicaNative.Expression()
        SymbolicaBackend.SymbolicaNative.set_integer(handle, Int64(value))
        return NativeExpression(handle)
    end
    return NativeExpression(SymbolicaBackend.expression(to_symstr(expr)))
end
Base.convert(::Type{Num}, expr::NativeExpression) = from_symstr(SymbolicaBackend.SymbolicaNative.render(expr.handle))

for (op, description) in ((:expand, "Expand products and powers"),
                          (:factor, "Factor over the rationals"),
                          (:simplify, "Cancel common factors"))
    bang = Symbol(op, :!)
    @eval begin
        function $bang(expr::NativeExpression)
            SymbolicaBackend.SymbolicaNative.$op(expr.handle)
            return expr
        end
        @doc $description function $op(expr::Num)
            native = NativeExpression(expr)
            $bang(native)
            return convert(Num, native)
        end
    end
end

function derivative!(expr::NativeExpression, var::Num)
    SymbolicaBackend._ok(SymbolicaBackend.SymbolicaNative.derivative(expr.handle, to_symstr(var)))
    return expr
end
"Compute the derivative of a symbolic expression with respect to a variable."
function derivative(expr::Num, var::Num)
    native = NativeExpression(expr)
    derivative!(native, var)
    return convert(Num, native)
end
"Expand through the given absolute degree around `point`, omitting the remainder term."
function series!(expr::NativeExpression, var::Num, point::Number, depth::Integer)
    SymbolicaBackend._ok(SymbolicaBackend.SymbolicaNative.series(expr.handle, to_symstr(var), _format_literal(point), Int64(depth)))
    return expr
end
function series(expr::Num, var::Num, point::Number, depth::Integer)
    native = NativeExpression(expr)
    series!(native, var, point, depth)
    return convert(Num, native)
end
function substitute!(expr::NativeExpression, dict::Dict)
    io = IOBuffer()
    for (key, value) in dict
        for item in (key, value)
            str = to_symstr(item)
            print(io, ncodeunits(str), ':', str)
        end
    end
    SymbolicaBackend._ok(SymbolicaBackend.SymbolicaNative.substitute_batch(expr.handle, String(take!(io))))
    return expr
end
"Apply substitutions sequentially in dictionary iteration order."
function substitute(expr::Num, dict::Dict)
    native = NativeExpression(expr)
    substitute!(native, dict)
    return convert(Num, native)
end
