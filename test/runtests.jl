using Test
using Symbolics
using Symbolica
using RustCall

@variables x y

@testset "released RustCall bindings" begin
    @test v"0.9" <= pkgversion(RustCall) < v"0.10"
    @test Symbolica.SymbolicaBackend.SymbolicaNative._BINDINGS_FORMAT == "0.9"
end

@testset "expand" begin
    @test isequal(Symbolica.expand((x+y)^2), x^2 + 2x*y + y^2)
    @test isequal(Symbolica.expand((x+y)^3), x^3 + 3x^2*y + 3x*y^2 + y^3)
end

@testset "factor" begin
    @test isequal(Symbolica.factor(x^2 + 2x + 1), (x + 1)^2)
end

@testset "simplify" begin
    @test isequal(Symbolica.simplify((x^2 - 1) / (x - 1)), x + 1)
end

@testset "derivative" begin
    @test isequal(Symbolica.derivative(x^3 + sin(x), x), 3x^2 + cos(x))
end

@testset "substitute" begin
    @test isequal(Symbolica.substitute(x + y, Dict(x => y + 1)), (y + 1) + y)
    native = NativeExpression(x + y)
    backend = Symbolica.SymbolicaBackend
    frame(s) = string(ncodeunits(s), ':', s)
    batch = frame("x") * frame("y") * frame("y") * frame("2")
    backend._ok(backend.SymbolicaNative.substitute_batch(native.handle, batch))
    @test isequal(convert(Num, native), Num(4))
    for invalid in ("1:x", "1:x1:y2:é1:(", "999:x", "1:é")
        @test_throws ArgumentError backend._ok(backend.SymbolicaNative.substitute_batch(native.handle, invalid))
        @test isequal(convert(Num, native), Num(4))
    end
    @test substitute!(native, Dict()) === native
    @test isequal(convert(Num, native), Num(4))
end

@testset "owned expressions and errors" begin
    native = NativeExpression((x + y)^2)
    @test expand!(native) === native
    derivative!(native, x)
    @test isequal(convert(Num, native), 2x + 2y)
    substitute!(native, Dict(x => y + 1))
    expand!(native)
    @test isequal(convert(Num, native), 2 + 4y)
    @test_throws ArgumentError Symbolica.SymbolicaBackend.expression("((( unparsable @@@")
    @test isequal(Symbolica.expand((x + y)^2), x^2 + 2x*y + y^2)
end
