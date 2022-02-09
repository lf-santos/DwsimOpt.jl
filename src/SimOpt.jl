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

from dwsimopt.sim_opt import SimulationOptimization


# Loading DWSIM simulation into Python (Simulation object)
print($path2sim)
sim = SimulationOptimization(dof=np.array([]), path2sim= $path2sim, 
                    path2dwsim = $path2dwsim)
print(sim.path2sim)
sim.add_refs()

# Instanciate automation manager object
from DWSIM.Automation import Automation2
interf = Automation2()

# Connect simulation in sim.path2sim
sim.connect(interf)
"""