# Clone Symbolica and build the facade crate

const SYMBOLICA_DIR = joinpath(@__DIR__, "symbolica")
const RUST_DIR = joinpath(@__DIR__, "..", "rust")

# Clone symbolica if not present
if !isdir(SYMBOLICA_DIR)
    @info "Cloning symbolica from GitHub..."
    run(`git clone https://github.com/symbolica-dev/symbolica.git $(SYMBOLICA_DIR)`)
end

# Build the facade crate
@info "Building Rust facade crate..."
cd(RUST_DIR) do
    run(`cargo build --release`)
end

@info "Build complete. Native library is at $(joinpath(RUST_DIR, "target", "release"))"
