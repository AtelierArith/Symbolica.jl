using Documenter
using Symbolica

makedocs(
    sitename = "Symbolica.jl",
    modules = [Symbolica],
    remotes = nothing,
    format = Documenter.HTML(prettyurls = false, repolink = "https://github.com/AtelierArith/Symbolica.jl"),
    pages = ["チュートリアル" => "index.md"],
    checkdocs = :none,
)
