//! Facade crate between Symbolica.jl and the Symbolica CAS.
//!
//! Every entry point is a `#[julia]` function taking and returning `String`
//! (RustCall.jl generates the `extern "C"` wrapper and the Julia binding, see
//! RustCall.jl issue #242): expressions cross the FFI boundary as text in
//! Symbolica's syntax.

use rustcall_julia_macros::julia;
use symbolica::atom::Symbol;
use symbolica::atom::{Atom, AtomCore, DefaultNamespace};
use symbolica::id::Replacement;
use symbolica::parser::ParseSettings;
use symbolica::printer::{ColorMode, PrintOptions};

fn parse_expr(input: &str) -> Atom {
    Atom::parse_with_default_namespace(
        DefaultNamespace {
            data: input,
            namespace: "julia".into(),
            file: "".into(),
            line: 0,
        },
        ParseSettings::symbolica(),
    )
    .unwrap_or_else(|e| panic!("Symbolica parse error: {}", e))
}

fn parse_symbol(input: &str) -> Symbol {
    Symbol::parse_with_default_namespace(DefaultNamespace {
        data: input,
        namespace: "julia".into(),
        file: "".into(),
        line: 0,
    })
    .unwrap_or_else(|e| panic!("Symbolica symbol parse error: {}", e))
}

fn atom_to_string(atom: &Atom) -> String {
    atom.printer(PrintOptions::default().color_mode(ColorMode::Never))
        .to_string()
}

/// Expand products and powers.
#[julia]
pub fn symbolica_expand(input: String) -> String {
    atom_to_string(&parse_expr(&input).expand())
}

/// Factor over the rationals.
#[julia]
pub fn symbolica_factor(input: String) -> String {
    atom_to_string(&parse_expr(&input).factor())
}

/// Cancel common factors of a rational expression.
#[julia]
pub fn symbolica_simplify(input: String) -> String {
    atom_to_string(&parse_expr(&input).cancel())
}

/// Derivative of `input` with respect to the variable `var`.
#[julia]
pub fn symbolica_derivative(input: String, var: String) -> String {
    let expr = parse_expr(&input);
    atom_to_string(&expr.derivative(parse_symbol(&var)))
}

/// Replace every occurrence of `var` in `input` by `replacement`.
#[julia]
pub fn symbolica_substitute(input: String, var: String, replacement: String) -> String {
    let expr = parse_expr(&input);
    let var_atom = parse_expr(&var);
    let repl_atom = parse_expr(&replacement);
    atom_to_string(&expr.replace_multiple([Replacement::new(var_atom, repl_atom)]))
}
