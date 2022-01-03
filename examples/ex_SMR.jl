using BlackBoxOptim
using DwsimOpt

op1 = OptProblemDef()

function fpen(x)
    return Float64(op1.f(x)[1]) .+ sum(max.(0, op1.g(x)))
end

bound = [Tuple(op1.searchSpace[:, i]') for i = 1:size(op1.searchSpace)[2]]

res = bboptimize(fpen; SearchRange = bound, NumDimensions = sim_jl.n_dof, MaxTime = 10.0)