# Symbolica.jl

[![Julia](https://img.shields.io/badge/julia-%3E%3D1.10-blue)](https://julialang.org)

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

Symbolica.jl requires [Rust](https://rustup.rs) ≥ 1.89. The native library is compiled automatically during `Pkg.build()`.

```julia
using Pkg
Pkg.add("Symbolica")
```

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
    ↓ ccall (Libdl)
rust/ facade crate (extern "C" → deps/symbolica)
    ↓
Symbolica Atom (parse → operate → print)
    ↓
rust/ facade crate (string → extern "C")
    ↓ ccall (Libdl)
string
    ↓ decode
Symbolics.jl Expr
```

## License

Symbolica.jl is MIT licensed. The underlying [Symbolica](https://symbolica.io) crate has its own license — see https://symbolica.io for details.
