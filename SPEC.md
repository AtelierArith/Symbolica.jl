# Symbolica.jl 仕様書

## 概要

Symbolica.jl は RustCall.jl を利用して Symbolica Rust crate を呼び出し、
Symbolics.jl と相互運用可能な CAS バックエンドを提供する。

初期スコープは Symbolics.jl 互換 API のみとする。

## 目標

- Symbolics.jl 式を Symbolica に変換
- Symbolica による式変形
- Symbolics.jl 式へ再変換
- RustCall.jl を利用
- AbstractAlgebra.jl/Oscar.jl は対象外

## API

```julia
using Symbolica
using Symbolics

@variables x y

Symbolica.expand((x+y)^3)
Symbolica.factor(x^2 + 2x + 1)
Symbolica.simplify((x^2 - 1)/(x - 1))
Symbolica.derivative(x^3 + sin(x), x)
Symbolica.substitute(x+y, Dict(x => y+1))
```

## アーキテクチャ

Symbolics Expr
↓
Encoder (Julia: Expr → 文字列)
↓
RustCall.jl (`@rust_crate` → ccall)
↓
rust/ facade crate (`#[julia]` → deps/symbolica)
↓
Symbolica Atom (parse → 操作 → print)
↓
rust/ facade crate (String → `#[julia]` で返却)
↓
RustCall.jl
↓
Decoder (Julia: 文字列 → Expr)
↓
Symbolics Expr

## extern/ — リファレンスパッケージ

`extern/` 以下は参照用。**これらのコードは一切変更してはならない。**
ソースコードの依存関係として利用してはいけない。実装の参考として読むのみ。

| パッケージ | 概要 |
|---|---|
| `RustCall.jl/` | Rust FFI フレームワーク。`@rust_str` (`rust"""..."""`) で Rust コードをコンパイル・ロード。`#[julia]` attribute で関数公開、`@rust_crate` で外部 crate バインド。 |
| `Symbolics.jl/` | ユーザー向け CAS。`Num` が `BasicSymbolic{VartypeT}` をラップ。`@variables`, `simplify`, `expand`, `substitute`, `derivative` などを提供。バックエンド変換は SymPy extension を参考にできる。 |
| `SymbolicUtils.jl/` | Symbolics.jl の基盤エンジン。`BasicSymbolic{T}` ADT (`Sym`, `Term`, `AddMul`, `Div`, `Const`)、`@rule` パターンマッチング、`simplify`/`substitute`/`expand` の実装、`toexpr` コード生成。 |

### Symbolics.jl / SymbolicUtils.jl の内部構造（変換実装の参考）

**式の内部表現:**
```julia
# Num は BasicSymbolic{VartypeT} を Const{} でラップしたもの
Num(x)  →  Const{VartypeT}(inner::BasicSymbolic{VartypeT})
unwrap(n::Num)  →  BasicSymbolic{VartypeT}
value(x)  →  unwrap_const(unwrap(x))  # Num → BasicSymbolic

# BasicSymbolic{VartypeT} のバリアント (Moshi.Data の @data):
#   Sym{VartypeT}      -- 変数 (name, type, shape, metadata)
#   Term{VartypeT}     -- 関数適用 f(args...)
#   AddMul{VartypeT}   -- 加算(ADD) または乗算(MUL) (coeff + dict)
#   Div{VartypeT}      -- 除算 (num, den)
#   Const{VartypeT}    -- 定数 (val)
```

**述語関数 (TermInterface.jl):**
- `iscall(x)`, `issym(x)`, `isadd(x)`, `ismul(x)`, `ispow(x)`, `isdiv(x)`
- `operation(x)` -- Term の関数ヘッドを取得
- `arguments(x)` -- Term/AddMul の引数を取得
- `symtype(x)` -- 式が表現する Julia 型
- `metadata(x)` -- メタデータ辞書

**文字列変換の戦略:**
- Julia → 文字列: 式木を再帰的に走査し、`operation(x)` と `arguments(x)` を使って Symbolica のパーサが理解できる文字列を生成する
  - `+`, `-`, `*`, `/`, `^` 演算子
  - `sin`, `cos`, `tan`, `exp`, `log`, `sqrt` 関数
  - 整数・有理数・浮動小数点数・変数名
- 文字列 → Julia: `parse_expr_to_symbolic(ex, mod)` または `@syms` + 手動構築

## deps/symbolica

Symbolica の Rust 実装。`deps/symbolica` に本家 Symbolica crate (v2.0.0) を配置する。
Cargo workspace で `lib/numerica`（数論・代数構造）と `lib/graphica`（グラフ正準化）の2つのサブクレートを含む。

主要モジュール:
- `atom` -- 式表現 (`Atom`, `AtomView`, `AtomCore`)
- `parser` -- 式パーサ (`parse!` マクロ)
- `poly` -- 多項式演算・因数分解・GCD・グレブナー基底・級数展開
- `id` -- パターンマッチングと式置換
- `evaluate` -- JIT コンパイルによる高速数値評価 (symjit, SIMD, CUDA)
- `printer` -- 式の文字列出力
- `solve` -- 線形/非線形方程式解法
- `streaming` -- 巨大式のストリーム処理
- `tensors` -- テンソル正準化・行列演算
- `transcendental` -- 超越関数の数値評価
- `domains` -- 代数構造 (環・体・ユークリッド整域, 代数的数, 有限体)

本プロジェクトでは `deps/symbolica` を直接参照せず、薄い facade crate を別途作成し、
RustCall.jl 経由で必要な関数のみを公開する。

## ディレクトリ構成

```text
Symbolica.jl/
├─ Project.toml
├─ src/
│  ├─ Symbolica.jl
│  ├─ operations.jl
│  ├─ rust_backend.jl
│  ├─ convert_to_symbolica.jl
│  ├─ convert_from_symbolica.jl
│  └─ parser.jl
├─ deps/
│  └─ symbolica/          # 本家 Symbolica Rust crate (v2.0.0)
│       ├─ Cargo.toml
│       ├─ src/
│       └─ lib/
│            ├─ numerica/
│            └─ graphica/
├─ rust/
│  ├─ Cargo.toml           # facade crate → deps/symbolica に依存
│  └─ src/lib.rs           # extern "C" 公開関数
└─ test/
```

## MVP

- expand
- factor
- simplify
- derivative
- substitute

## 対応型

- Int
- Rational
- Float64
- Symbolics variables

## 対応演算

- +
- -
- *
- /
- ^

## 対応関数

- sin
- cos
- tan
- exp
- log
- sqrt

## Rust側

`rust/` に facade crate を作成する。この crate は `deps/symbolica` を依存関係として持ち、
RustCall.jl から `@rust_crate` でロードできるよう `#[julia]` attribute で関数を公開する。
MVP では文字列ベースのインターフェース（Symbolica の `parse!` / `AtomPrinter` を活用）とする。

```rust
// rust/src/lib.rs
use symbolica::atom::AtomCore;

#[julia]
fn symbolica_expand(input: String) -> String { ... }
#[julia]
fn symbolica_factor(input: String) -> String { ... }
#[julia]
fn symbolica_simplify(input: String) -> String { ... }
#[julia]
fn symbolica_derivative(input: String, var: String) -> String { ... }
#[julia]
fn symbolica_substitute(input: String, var: String, replacement: String) -> String { ... }
```

Julia 側では `@rust_crate` でロードする:

```julia
const SymbolicaCore = @rust_crate joinpath(@__DIR__, "..", "rust")
expand(input::String) = SymbolicaCore.symbolica_expand(input)
```

`#[julia]` attribute は `juliacall_macros` proc-macro crate によって提供され、
コンパイル時に `#[no_mangle] pub extern "C"` へ展開される。
RustCall.jl が型変換（`String` ↔ `Cstring` 等）を自動処理する。

## v0.2

- JSON AST
- Rust handle

## v0.3

- Matrix expression
- Code generation

## テスト

```julia
@test Symbolica.expand((x+y)^2) == x^2 + 2x*y + y^2
@test Symbolica.factor(x^2+2x+1) == (x+1)^2
```
