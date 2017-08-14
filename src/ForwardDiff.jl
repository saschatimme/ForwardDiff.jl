__precompile__()

module ForwardDiff

using Cassette

@context DualCtx Dual

# imperative

function (ctx::DualCtx{typeof(f)})(x)
    if hascontext(ctx, x)
        x, dx = unwrap(ctx, x)
        return Dual(ctx, f(x), propagate(dfdx(x), dx))
    else
        return f(x)
    end
end

function (ctx::DualCtx{typeof(f)})(x, y)
    if hascontext(ctx, x) && hascontext(ctx, y)
        x, dx = unwrap(ctx, x)
        y, dy = unwrap(ctx, y)
        return Dual(ctx, f(x, y), propagate(dfdx(x, y), dx, dfdy(x, y), dy))
    elseif hascontext(ctx, x)
        x, dx = unwrap(ctx, x)
        return Dual(ctx, f(x, y), propagate(dfdx(x, y), dx)
    elseif hascontext(ctx, y)
        y, dy = unwrap(ctx, y)
        return Dual(ctx, f(x, y), propagate(dfdy(x, y), dy)
    else
        return f(x, y)
    end
end

# functional

function (ctx::DualCtx{f})(x)
    contextcall(ctx, x) do x, dx
        return Dual(ctx, f(x), df(x) * dx)
    end
end

# dispatch-based

(ctx::DualCtx)(args...) = unwrapcall(ctx, args...)

function (ctx::DualCtx{T,typeof(f)})(x::Dual{T}) where {T}
    x, dx = unwrap(ctx, x)
    return Dual(ctx, f(x), propagate(dfdx(x), dx))
end

function (ctx::DualCtx{T,typeof(f)})(x::Dual{T}, y::Dual{T}) where {T}
    x, dx = unwrap(ctx, x)
    y, dy = unwrap(ctx, y)
    return Dual(ctx, f(x, y), propagate(dfdx(x, y), dx, dfdy(x, y), dy))
end

function (ctx::DualCtx{T,typeof(f)})(x::Dual{T}, y) where {T}
    x, dx = unwrap(ctx, x)
    return Dual(ctx, f(x, y), propagate(dfdx(x, y), dx)
end

function (ctx::DualCtx{T,typeof(f)})(x, y::Dual{T}) where {T}
    y, dy = unwrap(ctx, y)
    return Dual(ctx, f(x, y), propagate(dfdy(x, y), dy)
end

# dispatch-based + sugar

@contextual (ctx::::DualCtx)(args...) = unwrapcall(ctx, args...)

@contextual function (ctx::typeof(f)::DualCtx)(x::::Dual)
    x, dx = unwrap(ctx, x)
    return Dual(ctx, f(x), propagate(dfdx(x), dx))
end

@contextual function (ctx::typeof(f)::DualCtx)(x::::Dual, y::::Dual)
    x, dx = unwrap(ctx, x)
    y, dy = unwrap(ctx, y)
    return Dual(ctx, f(x, y), propagate(dfdx(x, y), dx, dfdy(x, y), dy))
end

@contextual function (ctx::typeof(f)::DualCtx)(x::::Dual, y)
    x, dx = unwrap(ctx, x)
    return Dual(ctx, f(x, y), propagate(dfdx(x, y), dx)
end

@contextual function (ctx::typeof(f)::DualCtx)(x, y::::Dual)
    y, dy = unwrap(ctx, y)
    return Dual(ctx, f(x, y), propagate(dfdy(x, y), dy)
end

end # module
