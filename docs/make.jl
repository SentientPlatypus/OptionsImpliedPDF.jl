using Pkg
const PKGROOT = dirname(@__DIR__)
Pkg.activate(@__DIR__)
Pkg.develop(Pkg.PackageSpec(path=PKGROOT))
Pkg.instantiate()

using Documenter
using OptionsImpliedPDF

const REPO = "github.com/SentientPlatypus/OptionsImpliedPDF.jl.git"

makedocs(
    sitename = "OptionsImpliedPDF.jl",
    authors = "Gene Wicaksono and contributors",
    modules = [OptionsImpliedPDF],
    checkdocs = :exports,
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://sentientplatypus.github.io/OptionsImpliedPDF.jl/stable/",
        edit_link = "main",
    ),
    pages = [
        "Home" => "index.md",
        "Installation" => "installation.md",
        "User guide" => "guide.md",
        "API reference" => "api.md",
        "Technical background" => "technical.md",
        "Notes & PDFs" => "notes.md",
    ],
)

if get(ENV, "CI", nothing) == "true"
    deploydocs(;
        repo = REPO,
        devbranch = "main",
        push_preview = true,
    )
end
