using Plots

x0 = [1.2778398816059422, 2.2016812643348533, 2.1926874743853113, 7.9498390207039975, 4.181380029504798, 6.317810550389354]
x0 = [1.5814234453183729, 2.2460481926382125, 2.6910033273896916, 7.51313601869025, 5.090659591398877, 7.064864255336468]

for ii = 1:sim_jl.n_dof

    # xx = LinRange(op1.searchSpace[1, ii], op1.searchSpace[2, ii], 11)
    xx = LinRange(x0[ii] - 0.05, x0[ii] + 0.05, 11)
    yy = zeros(size(xx))
    cc = zeros(length(xx), sim_jl.n_g)
    f_name = f_block
    # xx0 = (op1.searchSpace[1, :] + op1.searchSpace[2, :]) ./ 2
    xx0 = x0
    for i = 1:length(xx)
        tmp1 = f_name([xx0[1:ii-1]; xx[i]; xx0[ii+1:end]])
        yy[i, :] = tmp1[1:sim_jl.n_f]
        cc[i, :] = tmp1[sim_jl.n_f+1:end]
    end

    p = plot(xx, [yy cc], layout = 6,
        legend = false,
        seriestype = :scatter,
        title = ["($i)" for j in 1:1, i in 1:11], titleloc = :right, titlefont = font(8)
    )
    display(p)

end

