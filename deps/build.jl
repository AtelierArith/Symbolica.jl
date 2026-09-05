# Build step of Symbolica.jl
#
# 1. fetch the Symbolica crate (the facade crate depends on it by path)
# 2. link the `juliacall_macros` proc-macro crate of the installed RustCall.jl
#    so the facade crate can use `#[julia]`
# 3. build the facade crate and generate precompilable Julia bindings from its
#    FFI manifest (RustCall.write_bindings_to_file)

using RustCall

const DEPS_DIR = @__DIR__
const ROOT_DIR = dirname(DEPS_DIR)
const SYMBOLICA_DIR = joinpath(DEPS_DIR, "symbolica")
# `juliacall_macros` depends on `rustcall_core` by relative path, so both are
# linked next to each other under deps/.
const LINKED_CRATES = ("juliacall_macros", "rustcall_core")
const RUST_DIR = joinpath(ROOT_DIR, "rust")
const BINDINGS_PATH = joinpath(ROOT_DIR, "src", "generated", "SymbolicaNative.jl")

if !isdir(SYMBOLICA_DIR)
    @info "Cloning symbolica from GitHub..."
    run(`git clone https://github.com/symbolica-dev/symbolica.git $(SYMBOLICA_DIR)`)
end

for crate in LINKED_CRATES
    src = joinpath(pkgdir(RustCall), "deps", crate)
    isdir(src) || error("$crate not found in the RustCall package at $src")
    link = joinpath(DEPS_DIR, crate)
    if !ispath(link) || realpath(link) != realpath(src)
        rm(link; force = true, recursive = true)
        symlink(src, link; dir_target = true)
    end
    @info "Using $crate from $src"
end

mkpath(dirname(BINDINGS_PATH))

@info "Building the Rust facade crate and generating Julia bindings..."
RustCall.write_bindings_to_file(
    RUST_DIR,
    BINDINGS_PATH;
    output_module_name = "SymbolicaNative",
    build_release = true,
    relative_lib_path = "lib",
)

@info "Build complete" bindings = BINDINGS_PATH
