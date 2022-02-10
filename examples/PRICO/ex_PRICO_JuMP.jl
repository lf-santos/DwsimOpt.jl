# To-do: derive high-fidelity gradient
using DwsimOpt
using JuMP
using Ipopt
using FiniteDifferences
using LinearAlgebra
using GAMS
using MadNLP

## SIMULATION OPTIMIZATION PROBLEM DEFINITION
path2sim = "c:/Users/lfsfr/Desktop/DwsimOpt.jl/examples/PRICO/PRICO.dwxmz"
path2dwsim = "C:/Users/lfsfr/AppData/Local/DWSIM7/"

include("c:/Users/lfsfr/Desktop/DwsimOpt.jl/src/SimOpt.jl")
sim_jl = py"sim"

# Declare the simulation optimization problem
py"""
# Import dwsim-python data exchange interface (has to be after Automation2)
from dwsimopt.py2dwsim import create_pddx, assign_pddx

# Assign DoF:
create_pddx( ["MR-1", "CompoundMassFlow", "Nitrogen", "kg/s"],    sim, element="dof" )
create_pddx( ["MR-1", "CompoundMassFlow", "Methane", "kg/s"],     sim, element="dof" )
create_pddx( ["MR-1", "CompoundMassFlow", "Ethane", "kg/s"],      sim, element="dof" )
create_pddx( ["MR-1", "CompoundMassFlow", "Propane", "kg/s"],     sim, element="dof" )
create_pddx( ["VALV-01", "OutletPressure", "Mixture", "Pa"],      sim, element="dof" )
create_pddx( ["COMP-4", "OutletPressure", "Mixture", "Pa"],       sim, element="dof" )

# Assign F
create_pddx( ["Sum_W", "EnergyFlow", "Mixture", "kW"], sim, element="fobj" )

# adding constraints (g_i <= 0):
g1 = create_pddx( ["MITA1-Calc", "OutputVariable", "mita", "°C"], sim, element="constraint", assign=False )
assign_pddx( lambda: 3-g1[0]() , ["MITA1-Calc", "OutputVariable", "mita", "°C"], sim, element="constraint" )
create_pddx( ["MSTR-27", "MassFraction", "Liquid", "x"], sim, element="constraint" )
create_pddx( ["MR-1", "MassFraction", "Liquid", "x"], sim, element="constraint" )
create_pddx( ["MSTR-03", "MassFraction", "Liquid", "x"], sim, element="constraint" )
create_pddx( ["MSTR-05", "MassFraction", "Liquid", "x"], sim, element="constraint" )

# decision variables bounds
# x0 = np.array( [1.07249112e-04, 1.93057244e-04, 2.16881626e-04, 7.44968925e-04, 3.43386624e+05, 6.39810411e+06] )
# x0 = np.array( [1.12083333e-04, 1.30420113e-04, 2.57333445e-04, 8.00266697e-04, 3.45000000e+05, 1.53000000e+02] )
x0 = np.array( [1.12083333e-04, 2.20416667e-04, 1.42216680e-04, 7.54165016e-04, 3.45000000e+05, 7.20000000e+06] )
x0 = np.array( [1.3*1.12083333e-04, 1.3*2.20416667e-04, 1.3*1.42216680e-04, 1.3*7.54165016e-04, 3.45000000e+05, 7.20000000e+06] )
bounds_raw = np.array( [0.75*np.asarray(x0), 1.25*np.asarray(x0)] )   # 50 % around base case

# regularizer calculation
regularizer = np.zeros(x0.size)
for i in range(len(regularizer)):
    regularizer[i] = 10**(-1*math.floor(math.log(x0[i],10))) # regularizer for magnitude order of 1e0

# bounds regularized
bounds_reg = regularizer*bounds_raw

# objective and constraints lambda definitions
f = lambda x: sim.calculate_optProblem(np.asarray(x)/regularizer)[0:sim.n_f]
g = lambda x: sim.calculate_optProblem(np.asarray(x)/regularizer)[sim.n_f:(sim.n_f+sim.n_g)]
"""

f = py"f"
g = py"g"
x0 = py"x0*regularizer"
searchSpace = py"bounds_reg"
dim = sim_jl.n_dof
op1 = optProblem(f, g, x0, searchSpace, dim, sim_jl, py"sim.n_dof", py"sim.n_f", py"sim.n_g")
op1.sim_jl.verbose = false;
save_sim() = py"""sim.interface.SaveFlowsheet(sim.flowsheet,$pwd()+"/examples/PRICO/PRICO2.dwxmz",True)"""

# external functions and jacobian calculations
x0 = 1.0 * (op1.searchSpace[1, :] + op1.searchSpace[2, :]) ./ 2
# x0 = py"x0*regularizer"
function f_block(x)
    return [op1.f(x)[1]; op1.g(x)[:]]
end
first_time = true
function jac_block(x)
    # println("hi")
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp, ∇g3_bkp, ∇g4_bkp, ∇g5_bkp, first_time
    if norm(x0 - x) > 1e-5 || first_time == true
        f0 = f_block(x)
        println("Calculating jacobian of black-box functions at x=", x, " and f^{sim}=", f0)
        # flag_diff_method = "1st_forward"
        flag_diff_method = "2nd_central"
        h = 0.01
        tmp = zeros(6, length(x))
        for i = 1:length(x)
            if flag_diff_method == "1st_forward"
                tmp[:, i] = (f_block([x[1:i-1]; x[i] + h; x[i+1:end]]) - f0) / h
            elseif flag_diff_method == "2nd_central"
                tmp[:, i] = (f_block([x[1:i-1]; x[i] + h; x[i+1:end]]) - f_block([x[1:i-1]; x[i] - h; x[i+1:end]])) / (2 * h)
            end
        end
        # tmp = jacobian(forward_fdm(2, 1), f_block, x)[1]
        ∇f_bkp = tmp[1, :]
        ∇g1_bkp = tmp[2, :]
        ∇g2_bkp = tmp[3, :]
        ∇g3_bkp = tmp[4, :]
        ∇g4_bkp = tmp[5, :]
        ∇g5_bkp = tmp[6, :]
        x0 = x
        first_time = false
        return tmp
    end
end

## JuMP MODEL STUFF
model = Model(optimizer_with_attributes(Ipopt.Optimizer))
# model = Model(Ipopt.Optimizer)
set_optimizer_attribute(model, "max_cpu_time", 1200.0)
# model = Model(GAMS.Optimizer)
# set_optimizer_attribute(model, GAMS.ModelType(), "NLP")
# set_optimizer_attribute(model, "NLP", "CONOPT")
# set_optimizer_attribute(model, "resLIM", 1200.0)
# model = Model(() -> MadNLP.Optimizer(print_level = MadNLP.INFO, max_iter = 100))

# VARIABLES
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

# OBJECTIVE FUNCTION
fobj_bb(x1, x2, x3, x4, x5, x6) = op1.f([x1, x2, x3, x4, x5, x6])[1]
function ∇fobj_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T) where {T}
    # println("I am in ∇fobj_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp, ∇g3_bkp, ∇g4_bkp, ∇g5_bkp
    jac_block([x1, x2, x3, x4, x5, x6])
    ∇f_tmp = ∇f_bkp
    # ∇f_tmp = grad(forward_fdm(2, 1), op1.f, [x1, x2, x3, x4, x5, x6, x7, x8])[1]
    for i = 1:length([x1, x2, x3, x4, x5, x6])
        g[i] = ∇f_tmp[i]
    end
end
register(model, :fobj_bb, op1.dim, fobj_bb, ∇fobj_bb; autodiff = false)
@NLobjective(model, Min, fobj_bb(x1, x2, x3, x4, x5, x6))

# CONSTRAINTS
g1(x) = op1.g(x)[1]
g2(x) = op1.g(x)[2]
g3(x) = op1.g(x)[3]
g4(x) = op1.g(x)[4]
g5(x) = op1.g(x)[5]
g1_bb(x1, x2, x3, x4, x5, x6) = op1.g([x1, x2, x3, x4, x5, x6])[1]
g2_bb(x1, x2, x3, x4, x5, x6) = op1.g([x1, x2, x3, x4, x5, x6])[2]
g3_bb(x1, x2, x3, x4, x5, x6) = op1.g([x1, x2, x3, x4, x5, x6])[3]
g4_bb(x1, x2, x3, x4, x5, x6) = op1.g([x1, x2, x3, x4, x5, x6])[4]
g5_bb(x1, x2, x3, x4, x5, x6) = op1.g([x1, x2, x3, x4, x5, x6])[5]
function ∇g1_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T) where {T}
    # println("I am in ∇g1_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp, ∇g3_bkp, ∇g4_bkp, ∇g5_bkp
    jac_block([x1, x2, x3, x4, x5, x6])
    ∇g1_tmp = ∇g1_bkp
    for i = 1:length([x1, x2, x3, x4, x5, x6])
        g[i] = ∇g1_tmp[i]
    end
end
function ∇g2_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T) where {T}
    # println("I am in ∇g2_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp, ∇g3_bkp, ∇g4_bkp, ∇g5_bkp
    jac_block([x1, x2, x3, x4, x5, x6])
    ∇g2_tmp = ∇g2_bkp
    for i = 1:length([x1, x2, x3, x4, x5, x6])
        g[i] = ∇g2_tmp[i]
    end
end
function ∇g3_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T) where {T}
    # println("I am in ∇g2_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp, ∇g3_bkp, ∇g4_bkp, ∇g5_bkp
    jac_block([x1, x2, x3, x4, x5, x6])
    ∇g3_tmp = ∇g3_bkp
    for i = 1:length([x1, x2, x3, x4, x5, x6])
        g[i] = ∇g3_tmp[i]
    end
end
function ∇g4_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T) where {T}
    # println("I am in ∇g2_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp, ∇g3_bkp, ∇g4_bkp, ∇g5_bkp
    jac_block([x1, x2, x3, x4, x5, x6])
    ∇g4_tmp = ∇g4_bkp
    for i = 1:length([x1, x2, x3, x4, x5, x6])
        g[i] = ∇g4_tmp[i]
    end
end
function ∇g5_bb(g::AbstractVector{T}, x1::T, x2::T, x3::T, x4::T, x5::T, x6::T) where {T}
    # println("I am in ∇g2_bb with x=", x1)
    global x0, ∇f_bkp, ∇g1_bkp, ∇g2_bkp, ∇g3_bkp, ∇g4_bkp, ∇g5_bkp
    jac_block([x1, x2, x3, x4, x5, x6])
    ∇g5_tmp = ∇g5_bkp
    for i = 1:length([x1, x2, x3, x4, x5, x6])
        g[i] = ∇g5_tmp[i]
    end
end
register(model, :g1_bb, op1.dim, g1_bb, ∇g1_bb; autodiff = false)
@NLconstraint(model, g1_bb(x1, x2, x3, x4, x5, x6) <= 0)
register(model, :g2_bb, op1.dim, g2_bb, ∇g2_bb; autodiff = false)
@NLconstraint(model, g2_bb(x1, x2, x3, x4, x5, x6) <= 0)
register(model, :g3_bb, op1.dim, g2_bb, ∇g2_bb; autodiff = false)
@NLconstraint(model, g3_bb(x1, x2, x3, x4, x5, x6) <= 0)
register(model, :g4_bb, op1.dim, g2_bb, ∇g2_bb; autodiff = false)
@NLconstraint(model, g4_bb(x1, x2, x3, x4, x5, x6) <= 0)
register(model, :g5_bb, op1.dim, g2_bb, ∇g2_bb; autodiff = false)
@NLconstraint(model, g5_bb(x1, x2, x3, x4, x5, x6) <= 0)

JuMP.optimize!(model)

@show JuMP.termination_status(model)
@show JuMP.primal_feasibility_report(model)
@show JuMP.dual_status(model)

# retrieve the objective value, corresponding x values and the status
println(JuMP.value.([x1, x2, x3, x4, x5, x6]))
println(JuMP.objective_value(model))
println(JuMP.termination_status(model))

f_block(JuMP.value.([x1, x2, x3, x4, x5, x6]))