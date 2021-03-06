using BlackBoxOptim
using DwsimOpt
include("c:\\Users\\lfsfr\\Desktop\\DwsimOpt.jl\\src\\SimOpt.jl")

op1 = OptProblemDef()

function fpen(x)
    return Float64(op1.f(x)[1]) .+ sum(max.(0, op1.g(x)))
end

bound = [Tuple(op1.searchSpace[:, i]') for i = 1:size(op1.searchSpace)[2]]

res = bboptimize(fpen; SearchRange = bound, NumDimensions = op1.dim, MaxTime = 10.0)