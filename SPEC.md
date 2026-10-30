# Symbolica.jl 仕様書

## 概要

Symbolica.jl は RustCall.jl を利用して Symbolica Rust crate を呼び出し、
Symbolics.jl と相互運用可能な CAS バックエンドを提供する。
Julia 1.13 以上と、登録済みの RustCall.jl 0.9 以上（0.9.x）を使用する。

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
RustCall.jl (ビルド時に生成したバインディング → ccall)
↓
rust/ facade crate (`#[julia]` → コミット固定の Symbolica crate)
↓
Symbolica Atom (parse → 操作 → print)
↓
rust/ facade crate (Rust 所有の `Expression` ハンドル)
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

## Symbolica Rust crate

Symbolica の Rust 実装。Cargo の git 依存として本家 Symbolica crate (v2.2.0) を取得する。
ソースはコミット `77c137481904b8a5531ede86e3ef36b82beed7fd` に固定する。
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

本プロジェクトでは Julia から本家 crate を直接参照せず、薄い facade crate を別途作成し、
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
│  └─ generated/          # ビルド時に生成。git 管理対象外
│       ├─ SymbolicaNative.jl
│       └─ lib/
├─ deps/
│  ├─ build.jl
│  ├─ rustcall_julia_macros/       # インストール済み RustCall へのリンク
│  ├─ rustcall_julia_macros_impl/  # 同上
│  └─ rustcall_julia_core/         # 同上
├─ rust/
│  ├─ Cargo.toml           # facade crate → コミット固定の Symbolica に依存
│  └─ src/lib.rs           # #[julia] 公開関数
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

`rust/` に facade crate を作成する。この crate はコミット固定の Symbolica を依存関係として持ち、
RustCall.jl から呼び出せるよう `#[julia]` attribute で関数を公開する。
式の入出力には文字列を使い、操作の間は `#[julia]` 構造体 `Expression` に
Symbolica の `Atom` を保持する。`NativeExpression` はそのハンドルをラップし、
複数の破壊的操作の後に `convert(Num, expr)` で Symbolics に戻せる。
パースエラーは `Result` から Julia の `ArgumentError` に変換する。

`deps/build.jl` の `RustCall.write_bindings_to_file` は 0.9 形式の
プリコンパイル可能なバインディングを生成する。

`#[julia]` attribute は `rustcall_julia_macros` が再公開し、
`rustcall_julia_macros_impl` → `rustcall_julia_core` が実装する。
3 crate とも同じインストール済み RustCall.jl に含まれるものをリンクする。
RustCall.jl が UTF-8 文字列のポインタ・長さによる引数転送、戻り値の解放、panic 境界を処理する。
古い整数形式の生成済みバインディングは再利用せず、`Pkg.build("Symbolica")` で再生成する。

## v0.2

- JSON AST

## v0.3

- Matrix expression
- Code generation

## テスト

```julia
@test Symbolica.expand((x+y)^2) == x^2 + 2x*y + y^2
@test Symbolica.factor(x^2+2x+1) == (x+1)^2
```
