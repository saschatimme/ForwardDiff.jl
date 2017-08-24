__precompile__()

module ForwardDiff

using Cassette: @context, @primitive, value, meta
using SpecialFunctions
using DiffRules

@context DualCtx

for (M, f, arity) in PRIMITIVES
    if arity == 1
        dfdx = diffrule(M, f, arity)
        @eval begin
            @primitive DualCtx function @ctx(c::typeof($f))(@ctx(x))
                vx, dx = value(c, x), meta(c, x)
                return Dual(c, $f(vx), propagate($dfdx(vx), dx))
            end
        end
    elseif arity == 2
        dfdx, dfdy = diffrule(M, f, arity)
        @eval begin
            @primitive DualCtx function @ctx(c::typeof($f))(@ctx(x), @ctx(y))
                vx, dx = value(c, x), meta(c, x)
                vy, dy = value(c, y), meta(c, y)
                return Dual(c, $f(vx, vy), propagate($dfdx(vx, vy), dx, $dfdy(vx, vy), dy))
            end
            @primitive DualCtx function @ctx(c::typeof($f))(@ctx(x), y)
                vx, dx = value(c, x), meta(c, x)
                return Dual(c, $f(vx, y), propagate($dfdx(vx, y), dx))
            end
            @primitive DualCtx function @ctx(c::typeof($f))(x, @ctx(y))
                vy, dy = value(c, x), meta(c, x)
                return Dual(c, $f(x, vy), propagate($dfdy(x, vy), dy))
            end
        end
    end
end

end # module ForwardDiff
