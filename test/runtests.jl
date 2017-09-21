# this is just a scratchpad for me to play around with things for now, not an actual test suite

function rosenbrock!(x#=::Vector{Float64}=#)
    a = one(eltype(x))
    y = zeros(length(x))
    b = 100.0
    result = 0.0
    for i in 1:length(x)-1
        x[i] = (a - x[i])^2 + b*(x[i+1] - x[i]^2)^2
        y[i] = x[i]
        result += x[i]
    end
    x[end] = 0.0
    @assert sum(x) == sum(y) == result
    return result
end

# function gradient(f, x)
#     @assert length(x) == 3
#     ctx = DiffCtx(f)
#     dx = MetaContainer(ctx, x, )
#     dx = [MetaValue(ctx, x[1], [1.,0.,0.]),
#           MetaValue(ctx, x[2], [0.,1.,0.]),
#           MetaValue(ctx, x[3], [0.,0.,1.])]
#     return Execute(ctx, nothing, f)(dx)
# end
