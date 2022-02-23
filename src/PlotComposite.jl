using Plots

x1 = [1.2778398816059422, 2.2016812643348533, 2.1926874743853113, 7.9498390207039975, 4.181380029504798, 6.317810550389354]
x0 = [1.5814234453183729, 2.2460481926382125, 2.6910033273896916, 7.51313601869025, 5.090659591398877, 7.064864255336468]
xz = [1.3871861585128287, 1.9380738100531907, 2.7660732617240016, 6.93383112743801, 4.2578379794699375, 7.181281452132222]
x0 = xz

function plotComposite(; x0 = x0)
    f_block(x0)

    pyimport("clr")
    pyimport("System")
    py""" 
    import clr
    clr.AddReference('System.Core')
    # clr.ImportExtensions(System.Linq)

    spd = sim.flowsheet.GetSpreadsheetObject()
    there_is_data = True
    # print(there_is_data)
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
    # println("T=", T, " , t=", t, " , Q=", Q)

    p = plot(Q, T,
        markercolor = :red,
        markersize = 6,
        label = "Hot composite",
        seriestype = :scatter,
        title = "Composite curves MSHE",
        xlabel = "Heat flow [kW]",
        xtickfont = font(12, "Courier"),
        ylabel = "Temperature [K]",
        ytickfont = font(12, "Courier")
    )
    plot!(Q, t,
        markercolor = :blue,
        markersize = 6,
        label = "Cold composite",
        seriestype = :scatter,
        legend = :bottomright,
        title = "Composite curves MSHE",
        xlabel = "Heat flow [kW]",
        xtickfont = font(12, "Courier"),
        ylabel = "Temperature [K]",
        ytickfont = font(12, "Courier"),
        guidefont = font(18),
        legendfont = font(14)
    )
    display(p)
end

plotComposite()
savefig("C:/Users/lfsfr/Desktop/2022_02_11-Presentation_Caballero-PinchLocationMethod/LNG_PLM/compositeCurveDWSIM.png")
plotComposite(x0 = x1)