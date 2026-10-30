# Run with: julia --project benchmark/operations.jl
# Timings include allocations and are medians after one warm-up call.
using Symbolica, Symbolics, Statistics
@variables x y
expr = (x + y + 1)^8

function measure(f; samples=20)
    f()
    times = [@elapsed f() for _ in 1:samples]
    return median(times) * 1e3
end

cases = [
    "Symbolics expand" => () -> Symbolics.expand(expr),
    "Symbolica expand including conversions" => () -> Symbolica.expand(expr),
    "Symbolica conversion round trip" => () -> convert(Num, NativeExpression(expr)),
    "Symbolica two operations including conversions" => () -> Symbolica.derivative(Symbolica.expand(expr), x),
    "Symbolica two operations on native handle" => () -> begin
        native = NativeExpression(expr)
        expand!(native)
        derivative!(native, x)
        convert(Num, native)
    end,
]
for (name, f) in cases
    println(name, ": ", round(measure(f); digits=3), " ms median")
end
