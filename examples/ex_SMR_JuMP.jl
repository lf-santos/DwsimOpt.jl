# To-do: make user-defined objective function and constraints work (no metter what)
#  -> try declaring x1, x2, ... separatelly. Ugly, but may work.
using BlackBoxOptim
using DwsimOpt
using JuMP
using Ipopt
using FiniteDifferences

include("c:\\Users\\lfsfr\\Desktop\\DwsimOpt.jl\\src\\SimOpt.jl")

op1 = OptProblemDef()
# optProblem(f, g, x0, searchSpace, dim, sim_jl)

model = Model(optimizer_with_attributes(Ipopt.Optimizer))

# VARIABLES
@variable(model, op1.searchSpace[1, i]' <= x[i = 1:op1.dim] <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)

# OBJECTIVE FUNCTION
# function fobj_bb(x)
#     xx = []
#     for i = 1:Vararg
#         xx = [xx; x[i]]
#     end
# end
fobj_bb(x) = op1.f([x])
function ∇fobj_bb(g::AbstractVector{T}, x::T) where {T}
    ∇f_tmp = grad(central_fdm(2, 1), op1.f, x)
    for i = 1:length(x)
        g[i] = ∇f_tmp[i]
    end
end
# ∇fobj_bb(x) = grad(central_fdm(5, 1), op1.f, x)
register(model, :fobj_bb, op1.dim, fobj_bb, ∇fobj_bb; autodiff = false)
# @NLobjective(model, Min, fobj_bb(x...))
@NLobjective(model, Min, fobj_bb(x[1], x[2], x[3], x[4], x[5], x[6], x[7], x[8]))

# CONSTRAINTS
g1_bb(x) = op1.g(x)[1]
g2_bb(x) = op1.g(x)[2]
function ∇g1_bb(g::AbstractVector{T}, x::T) where {T}
    ∇g1_tmp = grad(central_fdm(2, 1), g1_bb(x), x)
    for i = 1:length(x)
        g[i] = ∇g1_tmp[i]
    end
end
function ∇g2_bb(g::AbstractVector{T}, x::T) where {T}
    ∇g2_tmp = grad(central_fdm(2, 1), g2_bb(x), x)
    for i = 1:length(x)
        g[i] = ∇g2_tmp[i]
    end
end
register(model, :g1_bb, op1.dim, g1_bb, ∇g1_bb; autodiff = false)
@NLconstraint(model, g1_bb(x...) <= 0)
register(model, :g2_bb, op1.dim, g2_bb, ∇g2_bb; autodiff = false)
@NLconstraint(model, g2_bb(x...) <= 0)

JuMP.optimize!(model)

@show JuMP.termination_status(model)
@show JuMP.primal_feasibility_report(model)
@show JuMP.dual_status(model)

# retrieve the objective value, corresponding x values and the status
println(JuMP.value.(x))
println(JuMP.value.(y))
println(JuMP.objective_value(model))
println(JuMP.termination_status(model))