__precompile__()

module ForwardDiff

using Cassette: @context, @contextual, unwrapcall, value, meta, unwrap, hascontext

@context DualCtx Dual

@contextual (ctx:::DualCtx)(args...) = unwrapcall(ctx, args...)

#######################
# imperative approach #
#######################

for (f, arity) in PRIMITIVES
    if arity == 1
        dfdx = diffrule(f, arity)
        @eval begin
            @contextual function (ctx::typeof($f):DualCtx)(x)
                if hascontext(ctx, x)
                    vx, dx = value(ctx, x), meta(ctx, x)
                    return Dual(ctx, $f(vx), propagate($dfdx(vx), dx))
                else
                    return $f(x)
                end
            end
        end
    elseif arity == 2
        dfdx, dfdy = diffrule(f, arity)
        @eval begin
            @contextual function (ctx::typeof($f):DualCtx)(x, y)
                if hascontext(ctx, x) && hascontext(ctx, y)
                    vx, dx = value(ctx, x), meta(ctx, x)
                    vy, dy = value(ctx, y), meta(ctx, y)
                    return Dual(ctx, $f(vx, vy), propagate($dfdx(vx, vy), dx, $dfdy(vx, vy), dy))
                elseif hascontext(ctx, x)
                    vx, dx = value(ctx, x), meta(ctx, x)
                    return Dual(ctx, $f(vx, y), propagate($dfdx(vx, y), dx))
                elseif hascontext(ctx, y)
                    vy, dy = value(ctx, x), meta(ctx, x)
                    return Dual(ctx, $f(x, vy), propagate($dfdy(x, vy), dy))
                else
                    return $f(x, y)
                end
            end
        end
    end
end

#####################
# dispatch approach #
#####################

for (f, arity) in PRIMITIVES
    if arity == 1
        dfdx = diffrule(f, arity)
        @eval begin
            @contextual function (ctx::typeof($f):DualCtx)(x:::Dual)
                vx, dx = value(ctx, x), meta(ctx, x)
                return Dual(ctx, $f(vx), propagate($dfdx(vx), dx))
            end
        end
    elseif arity == 2
        dfdx, dfdy = diffrule(f, arity)
        @eval begin
            @contextual function (ctx::typeof($f):DualCtx)(x:::Dual, y:::Dual)
                vx, dx = value(ctx, x), meta(ctx, x)
                vy, dy = value(ctx, y), meta(ctx, y)
                return Dual(ctx, $f(vx, vy), propagate($dfdx(vx, vy), dx, $dfdy(vx, vy), dy))
            end
            @contextual function (ctx::typeof($f):DualCtx)(x:::Dual, y)
                vx, dx = value(ctx, x), meta(ctx, x)
                return Dual(ctx, $f(vx, y), propagate($dfdx(vx, y), dx))
            end
            @contextual function (ctx::typeof($f):DualCtx)(x, y:::Dual)
                vy, dy = value(ctx, x), meta(ctx, x)
                return Dual(ctx, $f(x, vy), propagate($dfdy(x, vy), dy))
            end
        end
    end
end

# The above is lowered into something like the below:

#=
for (f, arity) in PRIMITIVES
    if arity == 1
        dfdx = diffrule(f, arity)
        @eval begin
            function (ctx::DualCtx{T,typeof(f)})(x::Dual{T}) where {T}
                vx, dx = value(ctx, x), meta(ctx, x)
                return Dual(ctx, $f(vx), propagate($dfdx(vx), dx))
            end
        end
    elseif arity == 2
        dfdx, dfdy = diffrule(f, arity)
        @eval begin
            function (ctx::DualCtx{T,typeof(f)})(x::Dual{T}, y::Dual{T}) where {T}
                vx, dx = value(ctx, x), meta(ctx, x)
                vy, dy = value(ctx, y), meta(ctx, y)
                return Dual(ctx, $f(vx, vy), propagate($dfdx(vx, vy), dx, $dfdy(vx, vy), dy))
            end
            function (ctx::DualCtx{T,typeof(f)})(x::Dual{T}, y) where {T}
                vx, dx = value(ctx, x), meta(ctx, x)
                return Dual(ctx, $f(vx, y), propagate($dfdx(vx, y), dx))
            end
            function (ctx::DualCtx{T,typeof(f)})(x, y::Dual{T}) where {T}
                vy, dy = value(ctx, x), meta(ctx, x)
                return Dual(ctx, $f(x, vy), propagate($dfdy(x, vy), dy))
            end
        end
    end
end
=#

#######################
# functional approach #
#######################

for (f, arity) in PRIMITIVES
    if arity == 1
        dfdx = diffrule(f, arity)
        @eval begin
            @contextual function (ctx::typeof($f):DualCtx)(x)
                contextcall($f, ctx, x) do x, dx
                    return Dual(ctx, $f(x), propagate($dfdx(x), dx))
                end
            end
        end
    elseif arity == 2
        dfdx, dfdy = diffrule(f, arity)
        @eval begin
            @contextual function (ctx::typeof($f):DualCtx)(x, y)
                contextcall(
                    function (vx, dx)
                        contextcall(
                            function (vy, dy)
                                Dual(ctx, $f(vx, vy), propagate($dfdx(vx, vy), dx, $dfdy(vx, vy), dy))
                            end,
                            function (y)
                                Dual(ctx, $f(vx, y), propagate($dfdx(vx, y), dx))
                            end,
                            ctx,
                            y
                        )
                    end,
                    function (x)
                        contextcall(
                            function (vy, dy)
                                Dual(ctx, $f(x, vy), propagate($dfdy(x, vy), dy))
                            end,
                            function (y)
                                $f(x, y)
                            end,
                            ctx,
                            y
                        )
                    end,
                    ctx,
                    x
                )
            end
        end
    end
end

end # module ForwardDiff
