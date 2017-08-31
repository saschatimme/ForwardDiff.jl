__precompile__()

module ForwardDiff

#=
This is a mock implementation of forward-mode AD using Cassette. This code does not
actually run yet, but it hopefully will in a week or so.

The below implementation constitutes a nearly complete replacement of ForwardDiff's dual
numbers for unary and binary functions. Besides being drastically simpler code, note in
particular the following advantages:

- It doesn't require any extraneous method overloads, such as hashing, conversion/promotion
predicates, irrelevant numeric methods (e.g. `one`/`zero`).

- Safe nested differentiation is baked in, since metadata extraction is contextualized. This
implementation can compute the correct result even in the presence of perturbation confusion.

- It doesn't require dealing with any type ambiguities; new types and even other Cassette
contexts can be completely unaware of `DiffCtx` and still compose correctly.

TODO: What happens when the target function stores values in an array?

The idea is to wrap EVERY non-isbits variable with a lightweight wrapper with an
uninitialized metadata storage field that can be instantiated later. The type of
this storage is a kind of dict (maybe immutable? named tuple?) where the keys are
the original access point (field name, array index etc.) and the value type is
the union of possible meta data types. Then, every call to either `arrayset!`
and `setfield!` (Julia's lowest level mutating primitives) can store metadata
in this dict for later retrieval.

@contextual DiffCtx function @ctx(c)(args...)
    output = Cassette.ctxcall(value(c), c, args...)
    if isbits(typeof(output))
        return output
    else
        return wrap(c, output)
    end
end

=#

using Cassette: @context, @primitive, value, meta, Meta, @execute
using SpecialFunctions
using DiffRules # see https://github.com/JuliaDiff/DiffRules.jl

@context DiffCtx

for (M, f, arity) in DiffRules.diffrules()
    if arity == 1
        dfdx = DiffRules.diffrule(M, f, :vx)
        @eval begin
            @primitive ctx::DiffCtx function (::typeof($f))(x::@Meta)
                vx, dx = value(ctx, x), meta(ctx, x)
                return Meta(ctx, $f(vx), propagate($dfdx, dx))
            end
        end
    elseif arity == 2
        dfdx, dfdy = DiffRules.diffrule(M, f, :vx, :vy)
        @eval begin
            @primitive ctx::DiffCtx function (::typeof($f))(x::@Meta, y::@Meta)
                vx, dx = value(ctx, x), meta(ctx, x)
                vy, dy = value(ctx, y), meta(ctx, y)
                return Meta(ctx, $f(vx, vy), propagate($dfdx, dx, $dfdy, dy))
            end
            @primitive ctx::DiffCtx function (::typeof($f))(x::@Meta, vy)
                vx, dx = value(ctx, x), meta(ctx, x)
                return Meta(ctx, $f(vx, vy), propagate($dfdx, dx))
            end
            @primitive ctx::DiffCtx function (::typeof($f))(vx, y::@Meta)
                vy, dy = value(ctx, y), meta(ctx, y)
                return Meta(ctx, $f(vx, vy), propagate($dfdy, dy))
            end
        end
    end
end

propagate(dfdx::Number, dx::AbstractVector) = dfdx * dx

propagate(dfdx::Number, dx::AbstractVector, dfdy::Number, dy::AbstractVector) = propagate(dfdx, dx) + propagate(dfdy, dy)

end # module ForwardDiff
