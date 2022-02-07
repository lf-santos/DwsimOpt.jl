# To-do: make user-defined objective function and constraints work (no metter what)
#  -> try declaring x1, x2, ... separatelly. Ugly, but may work.
using DwsimOpt
using JuMP
using Ipopt
using FiniteDifferences

include("c:\\Users\\lfsfr\\Desktop\\DwsimOpt.jl\\src\\SimOpt.jl")

op1 = OptProblemDef()
op1.sim_jl.verbose = false;

model = Model(optimizer_with_attributes(Ipopt.Optimizer))

# VARIABLES
# @variable(model, op1.searchSpace[1, i]' <= x[i = 1:op1.dim] <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)
i = 1;
@variable(model, op1.searchSpace[1, i]' <= x1 <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)
i = 2;
@variable(model, op1.searchSpace[1, i]' <= x2 <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)
i = 3;
@variable(model, op1.searchSpace[1, i]' <= x3 <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)
i = 4;
@variable(model, op1.searchSpace[1, i]' <= x4 <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)
i = 5;
@variable(model, op1.searchSpace[1, i]' <= x5 <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)
i = 6;
@variable(model, op1.searchSpace[1, i]' <= x6 <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)
i = 7;
@variable(model, op1.searchSpace[1, i]' <= x7 <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)
i = 8;
@variable(model, op1.searchSpace[1, i]' <= x8 <= op1.searchSpace[2, i]', start = (op1.searchSpace[1, i] + op1.searchSpace[2, i]) ./ 2)

# OBJECTIVE FUNCTION
# fobj_bb(x) = op1.f([x])
fobj_bb(x1, x2, x3, x4, x5, x6, x7, x8) = op1.f([x1, x2, x3, x4, x5, x6, x7, x8])[1]
function ∇fobj_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T, x8::T) where {T}
    println("I am in ∇fobj_bb with x=", x1)
    ∇f_tmp = grad(central_fdm(2, 1), op1.f, [x1, x2, x3, x4, x5, x6, x7, x8])[1]
    for i = 1:length([x1, x2, x3, x4, x5, x6, x7, x8])
        g[i] = ∇f_tmp[i]
    end
end
# ∇fobj_bb(x) = grad(central_fdm(5, 1), op1.f, x)
register(model, :fobj_bb, op1.dim, fobj_bb, ∇fobj_bb; autodiff = false)
# @NLobjective(model, Min, fobj_bb(x[1], x[2], x[3], x[4], x[5], x[6], x[7], x[8]))
@NLobjective(model, Min, fobj_bb(x1, x2, x3, x4, x5, x6, x7, x8))

# CONSTRAINTS
g1(x) = op1.g(x)[1]
g2(x) = op1.g(x)[2]
g1_bb(x1, x2, x3, x4, x5, x6, x7, x8) = op1.g([x1, x2, x3, x4, x5, x6, x7, x8])[1]
g2_bb(x1, x2, x3, x4, x5, x6, x7, x8) = op1.g([x1, x2, x3, x4, x5, x6, x7, x8])[2]
function ∇g1_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T, x8::T) where {T}
    println("I am in ∇g1_bb with x=", x1)
    ∇g1_tmp = grad(central_fdm(2, 1), g1, [x1, x2, x3, x4, x5, x6, x7, x8])[1]
    for i = 1:length([x1, x2, x3, x4, x5, x6, x7, x8])
        g[i] = ∇g1_tmp[i]
    end
end
function ∇g2_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T, x8::T) where {T}
    println("I am in ∇g2_bb with x=", x1)
    ∇g2_tmp = grad(central_fdm(2, 1), g2, [x1, x2, x3, x4, x5, x6, x7, x8])[1]
    for i = 1:length([x1, x2, x3, x4, x5, x6, x7, x8])
        g[i] = ∇g2_tmp[i]
    end
end
register(model, :g1_bb, op1.dim, g1_bb, ∇g1_bb; autodiff = false)

@NLconstraint(model, g1_bb(x1, x2, x3, x4, x5, x6, x7, x8) <= 0)
register(model, :g2_bb, op1.dim, g2_bb, ∇g2_bb; autodiff = false)
@NLconstraint(model, g2_bb(x1, x2, x3, x4, x5, x6, x7, x8) <= 0)

JuMP.optimize!(model)

@show JuMP.termination_status(model)
@show JuMP.primal_feasibility_report(model)
@show JuMP.dual_status(model)

# retrieve the objective value, corresponding x values and the status
println(JuMP.value.(x))
println(JuMP.value.(y))
println(JuMP.objective_value(model))
println(JuMP.termination_status(model))