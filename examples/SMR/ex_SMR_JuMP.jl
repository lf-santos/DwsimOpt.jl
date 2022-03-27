# To-do: make user-defined objective function and constraints work (no metter what)
#  -> try declaring x1, x2, ... separatelly. Ugly, but may work.
using DwsimOpt
using JuMP
using Ipopt
using FiniteDifferences
using LinearAlgebra
using PyCall

path2sim = "c:/Users/lfsfr/Desktop/DwsimOpt.jl/examples/SMR/SMR.dwxmz"
path2dwsim = "C:/Users/lfsfr/AppData/Local/DWSIM7/"

include("c:/Users/lfsfr/Desktop/DwsimOpt.jl/src/SimOpt.jl")
sim_jl = py"sim_smr"

# just for testing: connect to another simulation

py"""
sim2 = SimulationOptimization(dof=np.array([]), path2sim= "c:/Users/lfsfr/Desktop/DwsimOpt.jl/examples/SMR/SMR.dwxmz", 
                    path2dwsim = $path2dwsim)
sim2.connect(interf)
"""

py"""
sim_smr = sim2

# Import dwsim-python data exchange interface (has to be after Automation2)
from dwsimopt.py2dwsim import create_pddx, assign_pddx

# Assign DoF:
create_pddx( ["MR-1", "CompoundMassFlow", "Nitrogen", "kg/s"],    sim_smr, element="dof" )
create_pddx( ["MR-1", "CompoundMassFlow", "Methane", "kg/s"],     sim_smr, element="dof" )
create_pddx( ["MR-1", "CompoundMassFlow", "Ethane", "kg/s"],      sim_smr, element="dof" )
create_pddx( ["MR-1", "CompoundMassFlow", "Propane", "kg/s"],     sim_smr, element="dof" )
create_pddx( ["MR-1", "CompoundMassFlow", "Isopentane", "Pa"],    sim_smr, element="dof" )
create_pddx( ["VALV-01", "OutletPressure", "Mixture", "Pa"],      sim_smr, element="dof" )
create_pddx( ["COMP-1", "OutletPressure", "Mixture", "Pa"],       sim_smr, element="dof" )
create_pddx( ["COOL-08", "OutletTemperature", "Mixture", "K"],    sim_smr, element="dof" )

# Assign F
create_pddx( ["Sum_W", "EnergyFlow", "Mixture", "kW"], sim_smr, element="fobj" )

# adding constraints (g_i <= 0):
g1 = create_pddx( ["MITA1-Calc", "OutputVariable", "mita", "°C"], sim_smr, element="constraint", assign=False )
assign_pddx( lambda: 3-g1[0]() , ["MITA1-Calc", "OutputVariable", "mita", "°C"], sim_smr, element="constraint" )
g2 = create_pddx( ["MITA2-Calc", "OutputVariable", "mita", "°C"], sim_smr, element="constraint", assign=False )
assign_pddx( lambda: 3-g2[0]() , ["MITA2-Calc", "OutputVariable", "mita", "°C"], sim_smr, element="constraint" )

# decision variables bounds
x0 = np.array( [0.25/3600, 0.70/3600, 1.0/3600, 1.10/3600, 1.80/3600, 2.50e5, 50.00e5, -60+273.15] )
bounds_raw = np.array( [0.5*np.asarray(x0), 1.5*np.asarray(x0)] )   # 50 % around base case
bounds_raw[0][-1] = 153     # precool temperature low limit manually
bounds_raw[1][-1] = 253     # precool temperature upper limit manually

# regularizer calculation
regularizer = np.zeros(x0.size)
for i in range(len(regularizer)):
    regularizer[i] = 10**(-1*math.floor(math.log(x0[i],10))) # regularizer for magnitude order of 1e0

# bounds regularized
bounds_reg = regularizer*bounds_raw

# objective and constraints lambda definitions
f = lambda x: sim_smr.calculate_optProblem(np.asarray(x)/regularizer)[0:sim_smr.n_f]
g = lambda x: sim_smr.calculate_optProblem(np.asarray(x)/regularizer)[sim_smr.n_f:(sim_smr.n_f+sim_smr.n_g)]
"""

f = py"f"
g = py"g"
x0 = py"x0*regularizer"
searchSpace = py"bounds_reg"
dim = sim_jl.n_dof
op1 = optProblem(f, g, x0, searchSpace, dim, sim_jl, py"sim.n_dof", py"sim.n_f", py"sim.n_g")
op1.sim_jl.verbose = false;
py"sim_smr.verbose=False";
save_sim() = py"""sim.interface.SaveFlowsheet(sim.flowsheet,$pwd()+"/examples/PRICO/PRICO_composite2.dwxmz",True)"""

# model = Model(optimizer_with_attributes(Ipopt.Optimizer))
model = Model(Ipopt.Optimizer)
set_optimizer_attribute(model, "max_cpu_time", 60.0)
set_optimizer_attribute(model, "print_level", 0)

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
x0 = 0.95 * (op1.searchSpace[1, :] + op1.searchSpace[2, :]) ./ 2
function f_block(x)
    # println("hi")
    # global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp
    # if norm(x0 - x) > 1e-5
    #     println("bye")
    #     ∇f_bkp, ∇g1_bkp, ∇g2_bkp = op1.f(x)[1], op1.g(x)[1], op1.g(x)[2]
    #     x0 = x
    # end
    return [op1.f(x)[1], op1.g(x)[1], op1.g(x)[2]]
end
function jac_block(x)
    println("hi")
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp
    if norm(x0 - x) > 1e-5
        println("bye")
        tmp = jacobian(forward_fdm(2, 1), f_block, x0)[1]
        ∇f_bkp = tmp[1, :]
        ∇g1_bkp = tmp[2, :]
        ∇g2_bkp = tmp[3, :]
        x0 = x
    end
end

# OBJECTIVE FUNCTION
# fobj_bb(x) = op1.f([x])
fobj_bb(x1, x2, x3, x4, x5, x6, x7, x8) = op1.f([x1, x2, x3, x4, x5, x6, x7, x8])[1]
function ∇fobj_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T, x8::T) where {T}
    println("I am in ∇fobj_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp
    jac_block([x1, x2, x3, x4, x5, x6, x7, x8])
    ∇f_tmp = ∇f_bkp
    # ∇f_tmp = grad(forward_fdm(2, 1), op1.f, [x1, x2, x3, x4, x5, x6, x7, x8])[1]
    for i = 1:length([x1, x2, x3, x4, x5, x6, x7, x8])
        g[i] = ∇f_tmp[i]
    end
end
# ∇fobj_bb(x) = grad(central_fdm(5, 1), op1.f, x)
register(model, :fobj_bb, op1.dim, fobj_bb, ∇fobj_bb; autodiff=false)
# @NLobjective(model, Min, fobj_bb(x[1], x[2], x[3], x[4], x[5], x[6], x[7], x[8]))
@NLobjective(model, Min, fobj_bb(x1, x2, x3, x4, x5, x6, x7, x8))

# CONSTRAINTS
g1(x) = op1.g(x)[1]
g2(x) = op1.g(x)[2]
g1_bb(x1, x2, x3, x4, x5, x6, x7, x8) = op1.g([x1, x2, x3, x4, x5, x6, x7, x8])[1]
g2_bb(x1, x2, x3, x4, x5, x6, x7, x8) = op1.g([x1, x2, x3, x4, x5, x6, x7, x8])[2]
function ∇g1_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T, x8::T) where {T}
    println("I am in ∇g1_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp
    jac_block([x1, x2, x3, x4, x5, x6, x7, x8])
    ∇g1_tmp = ∇g1_bkp
    # ∇g1_tmp = grad(forward_fdm(2, 1), g1, [x1, x2, x3, x4, x5, x6, x7, x8])[1]
    for i = 1:length([x1, x2, x3, x4, x5, x6, x7, x8])
        g[i] = ∇g1_tmp[i]
    end
end
function ∇g2_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T, x8::T) where {T}
    println("I am in ∇g2_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp
    jac_block([x1, x2, x3, x4, x5, x6, x7, x8])
    ∇g2_tmp = ∇g2_bkp
    # ∇g2_tmp = grad(forward_fdm(2, 1), g2, [x1, x2, x3, x4, x5, x6, x7, x8])[1]
    for i = 1:length([x1, x2, x3, x4, x5, x6, x7, x8])
        g[i] = ∇g2_tmp[i]
    end
end
register(model, :g1_bb, op1.dim, g1_bb, ∇g1_bb; autodiff=false)

@NLconstraint(model, g1_bb(x1, x2, x3, x4, x5, x6, x7, x8) <= 0)
register(model, :g2_bb, op1.dim, g2_bb, ∇g2_bb; autodiff=false)
@NLconstraint(model, g2_bb(x1, x2, x3, x4, x5, x6, x7, x8) <= 0)

JuMP.optimize!(model)

@show JuMP.termination_status(model)
@show JuMP.primal_feasibility_report(model)
@show JuMP.dual_status(model)

# retrieve the objective value, corresponding x values and the status
println(JuMP.value.([x1, x2, x3, x4, x5, x6, x7, x8]))
println(JuMP.objective_value(model))
println(JuMP.termination_status(model))