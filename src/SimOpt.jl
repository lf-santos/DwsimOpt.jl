struct optProblem
    f
    g
    x0
    searchSpace
    dim
    sim_jl
end


using PyCall

# Check if dwsimopt is installed
py"""
import importlib
dwsimopt_spec = importlib.util.find_spec("dwsimopt")
found = dwsimopt_spec is not None
if found == False:
    import subprocess
    import sys
    subprocess.check_call( [sys.executable, "-m", "pip", "install", "dwsimopt"] )
"""

# @pyimport dwsimopt
pyimport("dwsimopt")

py"""
import numpy as np
import math

import os
from pathlib import Path

dir_path = str(Path(os.getcwd()).absolute())
print(dir_path)
import subprocess
import sys
subprocess.check_call( ["python", "-m", "pip", "list"] )
print(sys.executable)

import sys
from dwsimopt.sim_opt import SimulationOptimization

# Getting DWSIM path from system path
path2dwsim = "C:/Users/lfsfr/AppData/Local/DWSIM7/"
print(path2dwsim)
"""

py"""
# Loading DWSIM simulation into Python (Simulation object)
sim_smr = SimulationOptimization(dof=np.array([]), path2sim= os.path.join(dir_path, "examples\\SMR.dwxmz"), 
                     path2dwsim = path2dwsim)
print(sim_smr.path2sim)
sim_smr.add_refs()
"""
py"""
# Instanciate automation manager object
from DWSIM.Automation import Automation2
interf = Automation2()

# Connect simulation in sim.path2sim
sim_smr.connect(interf)
"""

py"""
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

function OptProblemDef()
    sim_jl = py"sim_smr"
    f = py"f"
    g = py"g"
    x0 = py"x0*regularizer"
    searchSpace = py"bounds_reg"
    dim = sim_jl.n_dof

    return optProblem(f, g, x0, searchSpace, dim, sim_jl)
end
export OptProblemDef