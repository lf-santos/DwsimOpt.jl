using Documenter
using DwsimOpt

makedocs(
    sitename = "DwsimOpt",
    format = Documenter.HTML(),
    modules = [DwsimOpt]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
