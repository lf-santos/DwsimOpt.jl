using Plots

x0 = [1.2778398816059422, 2.2016812643348533, 2.1926874743853113, 7.9498390207039975, 4.181380029504798, 6.317810550389354]
x0 = [1.5814234453183729, 2.2460481926382125, 2.6910033273896916, 7.51313601869025, 5.090659591398877, 7.064864255336468]
f_block(x0)

pyimport("clr")
pyimport("System")
py""" 
import clr
clr.AddReference('System.Core')
# clr.ImportExtensions(System.Linq)

spd = sim.flowsheet.GetSpreadsheetObject()
there_is_data = True
print(there_is_data)
i=1
T = np.array([])
t = np.array([])
Q = np.array([])
while there_is_data:
    # print([spd.Worksheets[0].Cells[i,0].Data, spd.Worksheets[0].Cells[i,1].Data, spd.Worksheets[0].Cells[i,2].Data])
    T=np.append(T, [spd.Worksheets[0].Cells[i,0].Data])
    t=np.append(t, [spd.Worksheets[0].Cells[i,1].Data])
    Q=np.append(Q, [spd.Worksheets[0].Cells[i,2].Data])
    i = i+1
    if spd.Worksheets[0].Cells[i,0].Data==None:
        there_is_data = False
        
"""
T = py"T"
t = py"t"
Q = py"Q"
println("T=", T, " , t=", t, " , Q=", Q)

p = plot(Q, [T t],
    legend = false,
    seriestype = :scatter,
)
display(p)