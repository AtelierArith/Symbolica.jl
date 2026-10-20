# Build step of Symbolica.jl
#
# 1. link the runtime, proc-macro implementation and core shipped by RustCall.jl
#    so the facade's `#[julia]` uses the same ABI as its Julia loader
# 2. build the facade crate (Cargo fetches its pinned Symbolica dependency)
#    and generate precompilable Julia bindings from its
#    FFI manifest (RustCall.write_bindings_to_file)

using RustCall

const DEPS_DIR = @__DIR__
const ROOT_DIR = dirname(DEPS_DIR)
# These crates depend on one another by relative path. Link all three siblings
# from the same installed RustCall, not independently versioned registry copies.
const LINKED_CRATES = ("rustcall_julia_macros", "rustcall_julia_macros_impl", "rustcall_julia_core")
const RUST_DIR = joinpath(ROOT_DIR, "rust")
const BINDINGS_PATH = joinpath(ROOT_DIR, "src", "generated", "SymbolicaNative.jl")

for crate in LINKED_CRATES
    src = joinpath(pkgdir(RustCall), "deps", crate)
    isdir(src) || error("$crate not found in the RustCall package at $src")
    link = joinpath(DEPS_DIR, crate)
    if !islink(link) && ispath(link)
        error("Refusing to replace a non-symlink at $link; move it aside and rebuild.")
    end
    if !ispath(link) || realpath(link) != realpath(src)
        rm(link; force = true)
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
