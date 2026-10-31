# Symbolica.jl チュートリアル

Symbolica.jl は Symbolics.jl の式を Rust の Symbolica に渡し、展開や因数分解などを行います。このチュートリアルでは式の作成から連続した演算まで試します。

## 準備

Julia 1.13 以上、Rust 1.89 以上、およびネイティブライブラリのビルドに必要な C コンパイラ、`make`、`m4` を用意します。パッケージをインストールし、ネイティブライブラリをビルドします。

```julia
using Pkg
Pkg.add(["Symbolica", "Symbolics"])
Pkg.build("Symbolica")
```

未ライセンスの Symbolica は非商用の制限モードで動作し、バナーを表示します。同一マシンで同時に動かせるインスタンスは一つです。ライセンスの詳細は [Symbolica のサイト](https://symbolica.io/) を参照してください。

## 式を作って展開する

`@variables` で Symbolics の変数を作ります。両パッケージに同名の関数があるので、以下では `Symbolica.` を付けて呼び出します。

```@example tutorial
using Symbolics, Symbolica
@variables x y
expr = (x + y)^2
Symbolica.expand(expr)
```

結果は Symbolics の式なので、後続の Julia コードでも利用できます。元の `expr` は変更されません。

## 因数分解と簡約

```@example tutorial
Symbolica.factor(x^2 + 2x + 1)
```

```@example tutorial
Symbolica.simplify((x^2 - 1) / (x - 1))
```

`simplify` は有理式の共通因子を約分します。一般的な簡約をすべて行う関数ではありません。

## 微分と置換

```@example tutorial
Symbolica.derivative(x^3 + sin(x), x)
```

```@example tutorial
Symbolica.substitute(x + y, Dict(x => y + 1))
```

複数の置換は辞書の反復順に逐次適用されます。置換が互いに影響する場合は順序に注意してください。

## 級数展開

展開する変数、展開点、絶対次数を指定します。指定次数までの項を返し、剰余項は含めません。

```@example tutorial
Symbolica.series(1 / (1 - x), x, 0, 3)
```

## Rust 側に式を保持する

複数の演算を続けるときは `NativeExpression` を使うと、各演算の間は式を Rust 側に保持できます。末尾に `!` が付く操作は同じオブジェクトを更新します。

```@example tutorial
native = NativeExpression((x + y)^3)
expand!(native)
derivative!(native, x)
convert(Num, native)
```

式の受け渡しには通常文字列変換が使われますが、ネイティブな式への操作の間に往復は発生しません。所有する Rust オブジェクトは Julia のファイナライザで解放されます。無効な入力や級数展開のエラーは `ArgumentError` として報告されます。

## 次のステップ

各演算の引数や結果は、Julia のヘルプモードで `?Symbolica.series` のように確認できます。ローカルで性能を比較するには、リポジトリの `benchmark/operations.jl` を実行してください。
