using DAQHDF5
using Documenter

DocMeta.setdocmeta!(DAQHDF5, :DocTestSetup, :(using DAQHDF5); recursive=true)

makedocs(;
    modules=[DAQHDF5],
    authors="Paulo José Saiz Jabardo",
    repo="https://github.com/pjsjipt/DAQHDF5.jl/blob/{commit}{path}#{line}",
    sitename="DAQHDF5.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
