# Symbolica.jl

[![Julia](https://img.shields.io/badge/julia-%3E%3D1.13-blue)](https://julialang.org)

Symbolica.jl is a Julia wrapper for the [Symbolica](https://symbolica.io) computer algebra system, providing high-performance symbolic computation through Rust's Symbolica crate. It interoperates with [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl) expressions.

## Features

| Operation      | Description                              |
| -------------- | ---------------------------------------- |
| `expand`       | Expand products and powers               |
| `factor`       | Factor polynomials over the rationals    |
| `simplify`     | Cancel common factors in rational expressions |
| `derivative`   | Symbolic differentiation                 |
| `substitute`   | Variable substitution                    |
| `series`       | Truncated series around a numeric point  |

## Installation

Symbolica.jl requires Julia ≥ 1.13 and [Rust](https://rustup.rs) ≥ 1.89. It uses the registered RustCall.jl 0.9 release (compatible 0.9.x updates are allowed), not a development branch. The native library is compiled during `Pkg.build()`.

```julia
using Pkg
Pkg.add("Symbolica")
Pkg.build("Symbolica")
```

When updating an existing checkout, run `Pkg.free("RustCall")` first if its
`Manifest.toml` still tracks RustCall by a git URL or local path, then run
`Pkg.resolve()` and `Pkg.build("Symbolica")` again. The build regenerates the ignored bindings in
`src/generated/` in RustCall's 0.9 format; bindings generated for earlier minor versions
are not compatible. Do not copy generated bindings or native libraries between builds.

The native Symbolica dependency is pinned to the 2.2.0 source commit
[`77c1374`](https://github.com/symbolica-dev/symbolica/commit/77c137481904b8a5531ede86e3ef36b82beed7fd)
so an upstream default-branch change cannot silently alter the facade's API.

## Quick Start

```julia
using Symbolics
using Symbolica

@variables x y

Symbolica.expand((x + y)^3)                  # x^3 + 3x^2*y + 3x*y^2 + y^3
Symbolica.factor(x^2 + 2x + 1)               # (1 + x)^2
Symbolica.simplify((x^2 - 1) / (x - 1))      # 1 + x
Symbolica.derivative(x^3 + sin(x), x)        # cos(x) + 3x^2
Symbolica.substitute(x + y, Dict(x => y + 1)) # 1 + 2y
Symbolica.series(1 / (1 - x), x, 0, 3)       # 1 + x + x^2 + x^3
```

## Keeping expressions in Rust

For a sequence of operations, keep the expression in Rust and convert only at
its endpoints. Each mutating operation returns the same `NativeExpression`:

```julia
native = NativeExpression((x + y)^3)
expand!(native)
derivative!(native, x)
result = convert(Num, native)
```

The RustCall-generated handle owns the Symbolica `Atom` and releases it through
its finalizer. Invalid input returned by the Rust parser becomes an
`ArgumentError`. Substitutions are sent to Rust in one call and applied
sequentially, in dictionary iteration order. Invalid substitutions leave the
native expression unchanged.

`series(expr, variable, point, depth)` returns terms through the absolute
power `depth` without a remainder term. `series!` updates a native expression;
an unsupported expansion reports an `ArgumentError` and leaves it unchanged.
`simplify` performs rational cancellation and is not a general simplifier.

Unlicensed Symbolica runs in restricted non-commercial mode, with one instance
and one core per machine, and prints a license banner. Concurrent unlicensed
processes can be terminated by Symbolica; see its license documentation below.
Run `julia --project benchmark/operations.jl` for local timing comparisons,
including conversion overhead and a sequence using a native handle.

## Architecture

Symbolics expressions are encoded as strings at the boundary and parsed into
Rust-owned Symbolica atoms. RustCall generates the owned handle, methods, and
`Result` bindings. Results are printed and parsed back into Symbolics when
requested. The `NativeExpression` API keeps the atom across multiple operations;
64-bit integer constants are transferred directly without string parsing.

## License

Symbolica.jl is MIT licensed. The underlying [Symbolica](https://symbolica.io) crate has its own license — see https://symbolica.io for details.
