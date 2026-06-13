use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use symbolica::atom::{Atom, AtomCore, DefaultNamespace};
use symbolica::atom::Symbol;
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

fn atom_to_string(atom: &Atom) -> String {
    atom
        .printer(PrintOptions::default().color_mode(ColorMode::Never))
        .to_string()
}

fn to_cstring(s: String) -> *mut c_char {
    CString::new(s).unwrap().into_raw()
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn symbolica_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn symbolica_expand(input: *const c_char) -> *mut c_char {
    let input_str = unsafe { CStr::from_ptr(input) }.to_str().unwrap();
    let expr = parse_expr(input_str);
    to_cstring(atom_to_string(&expr.expand()))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn symbolica_factor(input: *const c_char) -> *mut c_char {
    let input_str = unsafe { CStr::from_ptr(input) }.to_str().unwrap();
    let expr = parse_expr(input_str);
    to_cstring(atom_to_string(&expr.factor()))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn symbolica_simplify(input: *const c_char) -> *mut c_char {
    let input_str = unsafe { CStr::from_ptr(input) }.to_str().unwrap();
    let expr = parse_expr(input_str);
    to_cstring(atom_to_string(&expr.cancel()))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn symbolica_derivative(input: *const c_char, var: *const c_char) -> *mut c_char {
    let input_str = unsafe { CStr::from_ptr(input) }.to_str().unwrap();
    let var_str = unsafe { CStr::from_ptr(var) }.to_str().unwrap();
    let expr = parse_expr(input_str);
    let var_sym = Symbol::parse_with_default_namespace(DefaultNamespace {
        data: var_str,
        namespace: "julia".into(),
        file: "".into(),
        line: 0,
    })
    .unwrap_or_else(|e| panic!("Symbolica symbol parse error: {}", e));
    to_cstring(atom_to_string(&expr.derivative(var_sym)))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn symbolica_substitute(
    input: *const c_char,
    var: *const c_char,
    replacement: *const c_char,
) -> *mut c_char {
    let input_str = unsafe { CStr::from_ptr(input) }.to_str().unwrap();
    let var_str = unsafe { CStr::from_ptr(var) }.to_str().unwrap();
    let replacement_str = unsafe { CStr::from_ptr(replacement) }.to_str().unwrap();
    let expr = parse_expr(input_str);
    let var_atom = parse_expr(var_str);
    let repl_atom = parse_expr(replacement_str);
    to_cstring(
        atom_to_string(
            &expr
                .replace_multiple([Replacement::new(var_atom, repl_atom)]),
        ),
    )
}
