//! Symbolica operations exposed through RustCall's owned handles and Results.
use rustcall_julia_macros::julia;
use symbolica::atom::{Atom, AtomCore, DefaultNamespace, Symbol};
use symbolica::id::Replacement;
use symbolica::parser::ParseSettings;
use symbolica::printer::{ColorMode, PrintOptions};

fn parse_expr(input: &str) -> Result<Atom, String> {
    Atom::parse_with_default_namespace(
        DefaultNamespace {
            data: input,
            namespace: "julia".into(),
            file: "".into(),
            line: 0,
        },
        ParseSettings::symbolica(),
    )
    .map_err(|e| format!("Symbolica parse error: {e}"))
}
fn parse_symbol(input: &str) -> Result<Symbol, String> {
    Symbol::parse_with_default_namespace(DefaultNamespace {
        data: input,
        namespace: "julia".into(),
        file: "".into(),
        line: 0,
    })
    .map_err(|e| format!("Symbolica symbol parse error: {e}"))
}

fn field<'a>(rest: &mut &'a str) -> Result<&'a str, String> {
    let colon = rest.find(':').ok_or("missing field length")?;
    let digits = &rest[..colon];
    if digits.is_empty() || !digits.bytes().all(|b| b.is_ascii_digit()) {
        return Err("invalid field length".into());
    }
    let len: usize = digits.parse().map_err(|_| "field length overflow")?;
    let data = &rest[colon + 1..];
    let value = data
        .get(..len)
        .ok_or("truncated field or invalid UTF-8 boundary")?;
    *rest = &data[len..];
    Ok(value)
}

/// An owned Symbolica expression. Its internal Atom never crosses the FFI boundary.
#[julia]
pub struct Expression {
    atom: Atom,
}

#[julia]
impl Expression {
    #[julia]
    pub fn new() -> Self {
        Self {
            atom: parse_expr("0").expect("zero is valid"),
        }
    }
    #[julia]
    pub fn set(&mut self, input: String) -> Result<bool, String> {
        self.atom = parse_expr(&input)?;
        Ok(true)
    }
    #[julia]
    pub fn set_integer(&mut self, value: i64) {
        self.atom = Atom::num(value);
    }
    #[julia]
    pub fn render(&self) -> String {
        self.atom
            .printer(PrintOptions::default().color_mode(ColorMode::Never))
            .to_string()
    }
    #[julia]
    pub fn expand(&mut self) {
        self.atom = self.atom.expand();
    }
    #[julia]
    pub fn factor(&mut self) {
        self.atom = self.atom.factor();
    }
    #[julia]
    pub fn simplify(&mut self) {
        self.atom = self.atom.cancel();
    }
    #[julia]
    pub fn derivative(&mut self, var: String) -> Result<bool, String> {
        self.atom = self.atom.derivative(parse_symbol(&var)?);
        Ok(true)
    }
    #[julia]
    pub fn series(&mut self, var: String, point: String, depth: i64) -> Result<bool, String> {
        let var = parse_symbol(&var)?;
        let point = parse_expr(&point)?;
        let depth = i32::try_from(depth).map_err(|_| "series depth is out of range")?;
        let candidate = self
            .atom
            .series(var, &point, depth)
            .map_err(|e| format!("Symbolica series error: {e}"))?
            .to_atom();
        self.atom = candidate;
        Ok(true)
    }
    #[julia]
    pub fn substitute_batch(&mut self, encoded: String) -> Result<bool, String> {
        let mut rest = encoded.as_str();
        let mut pairs = Vec::new();
        while !rest.is_empty() {
            let var = parse_expr(field(&mut rest)?)?;
            let replacement = parse_expr(field(&mut rest)?)?;
            pairs.push((var, replacement));
        }
        let mut candidate = self.atom.clone();
        for (var, replacement) in pairs {
            candidate = candidate.replace_multiple([Replacement::new(var, replacement)]);
        }
        self.atom = candidate;
        Ok(true)
    }
}
