using Documenter
using Symbolica

makedocs(
    sitename = "Symbolica.jl",
    modules = [Symbolica],
    remotes = nothing,
    format = Documenter.HTML(prettyurls = get(ENV, "CI", "false") == "true", repolink = "https://github.com/AtelierArith/Symbolica.jl"),
    pages = ["チュートリアル" => "index.md"],
    checkdocs = :none,
)

deploydocs(;
    repo = "github.com/AtelierArith/Symbolica.jl.git",
    devbranch = "main",
)
