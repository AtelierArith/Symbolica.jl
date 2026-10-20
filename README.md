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

## Installation

Symbolica.jl requires Julia ≥ 1.13 and [Rust](https://rustup.rs) ≥ 1.89. It uses the registered RustCall.jl 0.7.2 release (compatible 0.7.x updates are allowed), not a development branch. The native library is compiled during `Pkg.build()`.

```julia
using Pkg
Pkg.add("Symbolica")
Pkg.build("Symbolica")
```

When updating an existing checkout, run `Pkg.free("RustCall")` first if its
`Manifest.toml` still tracks RustCall by a git URL or local path, then run
`Pkg.resolve()` and `Pkg.build("Symbolica")` again. The build regenerates the ignored bindings in
`src/generated/` in RustCall's current 0.7 format; old integer-format bindings
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
```

## Architecture

```
Symbolics.jl Expr
    ↓ encode
string
    ↓ RustCall.jl bindings (`#[julia] fn(String) -> String`)
rust/ facade crate (→ pinned Symbolica source via Cargo)
    ↓
Symbolica Atom (parse → operate → print)
    ↓
rust/ facade crate
    ↓ RustCall.jl
string
    ↓ decode
Symbolics.jl Expr
```

## License

Symbolica.jl is MIT licensed. The underlying [Symbolica](https://symbolica.io) crate has its own license — see https://symbolica.io for details.
