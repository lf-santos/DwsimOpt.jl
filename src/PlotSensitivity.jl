using Plots

for ii = 1:sim_jl.n_dof

    # xx = LinRange(op1.searchSpace[1, ii], op1.searchSpace[2, ii], 11)
    xx = LinRange(x0[ii] - 0.3, x0[ii] + 0.3, 7)
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

