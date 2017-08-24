__precompile__()

module ForwardDiff

using Cassette: @context, @primitive, value, meta
using SpecialFunctions
using DiffRules

@context DualCtx

for (M, f, arity) in PRIMITIVES
    if arity == 1
        dfdx = diffrule(M, f, :vx)
        @eval begin
            @primitive DualCtx function @ctx(c::typeof($f))(@ctx(x))
                vx, dx = value(c, x), meta(c, x)
                return Dual(c, $f(vx), propagate($dfdx, dx))
            end
        end
    elseif arity == 2
        dfdx, dfdy = diffrule(M, f, :vx, :vy)
        @eval begin
            @primitive DualCtx function @ctx(c::typeof($f))(@ctx(x), @ctx(y))
                vx, dx = value(c, x), meta(c, x)
                vy, dy = value(c, y), meta(c, y)
                return Dual(c, $f(vx, vy), propagate($dfdx, dx, $dfdy, dy))
            end
            @primitive DualCtx function @ctx(c::typeof($f))(@ctx(x), vy)
                vx, dx = value(c, x), meta(c, x)
                return Dual(c, $f(vx, y), propagate($dfdx, dx))
            end
            @primitive DualCtx function @ctx(c::typeof($f))(vx, @ctx(y))
                vy, dy = value(c, x), meta(c, x)
                return Dual(c, $f(x, vy), propagate($dfdy, dy))
            end
        end
    end
end

propagate(dfdx::Number, dx::AbstractVector) = dfdx * dx

propagate(dfdx::Number, dx::AbstractVector, dfdy::Number, dy::AbstractVector) = propagate(dfdx, dx) + propagate(dfdy, dy)

end # module ForwardDiff
