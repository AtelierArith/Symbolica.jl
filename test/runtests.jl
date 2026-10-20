using Test
using Symbolics
using Symbolica
using RustCall

@variables x y

@testset "released RustCall bindings" begin
    @test v"0.7.2" <= pkgversion(RustCall) < v"0.8"
    @test Symbolica.SymbolicaBackend.SymbolicaNative._BINDINGS_FORMAT == "0.7"
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
end

@testset "rust panic boundary" begin
    # An unparsable expression makes the Rust facade `panic!` inside
    # `parse_expr` (rust/src/lib.rs); RustCall's panic boundary must turn
    # that into a catchable `RustCall.RustPanicError` rather than aborting
    # the process. A successful call afterward verifies the panic channel clears.
    @test_throws RustCall.RustPanicError Symbolica.SymbolicaBackend._call_expand("((( unparsable @@@")
    @test isequal(Symbolica.expand((x + y)^2), x^2 + 2x*y + y^2)
end
