import Base:
    +,
    -,
    *,
    /,
    ^,
    %,
    !,
    >,
    <,
    >=,
    <=,
    ==,
    !=,
    ===,
    !==,
    all,
    any,
    cumprod,
    cumsum,
    falses,
    findall,
    findfirst,
    findlast,
    isnan,
    log,
    maximum,
    minimum,
    ones,
    prod,
    rand,
    randn,
    round,
    sign,
    sum,
    trues,
    zeros

import Base.Broadcast:
    BroadcastStyle,
    DefaultArrayStyle,
    Broadcasted,
    broadcasted,
    broadcastable,
    broadcast,
    result_style

import Statistics:
    mean

# enable use of functions using dot operator
struct TemporalBroadcastStyle <: BroadcastStyle end
Base.BroadcastStyle(::Type{TS{V,T}}) where {V<:VALTYPE,T<:IDXTYPE} = TemporalBroadcastStyle
BroadcastStyle(::TemporalBroadcastStyle) = TemporalBroadcastStyle()
BroadcastStyle(::TemporalBroadcastStyle, ::TemporalBroadcastStyle) = TemporalBroadcastStyle()
BroadcastStyle(::DefaultArrayStyle, ::TemporalBroadcastStyle) = TemporalBroadcastStyle()
broadcastable(x::ts) = x
broadcast(f::Function, X::ts) = TS(f.(X.values), X.index, X.fields)
broadcast(f::Function, X::ts, Y::ts) = opjoined(X, Y, f)
broadcasted(::TemporalBroadcastStyle, f, X::ts) = TS(f.(X.values), X.index, X.fields)
broadcasted(::TemporalBroadcastStyle, f, X::ts, Y::ts) = opjoined(X, Y, f)
result_style(::Type{TemporalBroadcastStyle}) = TemporalBroadcastStyle()

# passthrough functions
all(x::ts) = all(x.values)
any(x::ts) = any(x.values)
findall(x::ts) = findall(x.values)
findfirst(x::ts) = findfirst(x.values)
findlast(x::ts) = findlast(x.values)

# equivalently-shaped convenience functions
ones(x::ts) = TS(ones(size(x)), x.index, x.fields)
ones(::Type{TS}, n::Int) = TS(ones(n))
ones(::Type{TS}, dims::Tuple{Int,Int}) = TS(ones(dims))
ones(::Type{TS}, r::Int, c::Int) = TS(ones(r, c))
zeros(x::ts) = TS(zeros(size(x.values)), x.index, x.fields)
zeros(::Type{TS}, n::Int) = TS(zeros(n))
zeros(::Type{TS}, r::Int, c::Int) = TS(zeros(r, c))
zeros(::Type{TS}, dims::Tuple{Int,Int}) = TS(zeros(dims))
trues(x::ts) = TS(trues(size(x)), x.index, x.fields)
falses(x::ts) = TS(falses(size(x)), x.index, x.fields)

# random numbers
rand(::Type{TS}, n::Int=1) = TS(rand(Float64, n))
rand(::Type{TS}, r::Int, c::Int) = TS(rand(Float64, r, c))
rand(::Type{TS}, dims::Tuple{Int,Int}) = TS(rand(Float64, dims))
randn(::Type{TS}, n::Int=1) = TS(randn(Float64, n))
randn(::Type{TS}, r::Int, c::Int) = TS(randn(Float64, r, c))
randn(::Type{TS}, dims::Tuple{Int,Int}) = TS(randn(Float64, dims))

# number functions
round(x::ts; digits::Int=0) = TS(round.(x.values, digits=digits), x.index, x.fields)
round(R::Type, x::ts) = TS(round.(R, x.values), x.index, x.fields)
sum(x::ts) = sum(x.values)
sum(x::ts, dim::Int) = sum(x.values, dim)
sum(f::Function, x::ts) = sum(f, x.values)
prod(x::ts) = prod(x.values)
prod(x::ts, dim::Int) = prod(x.values, dim)
maximum(x::ts) = maximum(x.values)
maximum(x::ts, dim::Int) = maximum(x.values, dim)
minimum(x::ts) = minimum(x.values)
minimum(x::ts, dim::Int) = minimum(x.values, dim)
cumsum(x::ts; dims::Int=1) = TS(cumsum(x.values, dims=dims), x.index, x.fields)
cumprod(x::ts; dims::Int=1) = TS(cumprod(x.values, dims=dims), x.index, x.fields)
mean(x::ts) = mean(x.values)

# artithmetic operators
function opjoined(x::ts, y::ts, f::Function)
    z = [x y]
    xcols = 1:size(x,2)
    ycols = size(x,2)+1:size(x,2)+size(y,2)
    a = z[:,xcols].values
    b = z[:,ycols].values
    return TS(f.(a, b), z.index)
end

# negatiion
-(x::ts) = TS(-x.values, x.index, x.fields)
!(x::ts) = TS(.!x.values, x.index, x.fields)

# ts + ts arithmetic
+(x::ts, y::ts) = opjoined(x, y, +)
-(x::ts, y::ts) = opjoined(x, y, -)
*(x::ts, y::ts) = opjoined(x, y, *)
/(x::ts, y::ts) = opjoined(x, y, /)
^(x::ts, y::ts) = opjoined(x, y, ^)
%(x::ts, y::ts) = opjoined(x, y, %)
# ts + ts logical
==(x::ts, y::ts) = x.values == y.values && x.index == y.index && x.fields == y.fields
!=(x::ts, y::ts) = x.values != y.values || x.index != y.index || x.fields != y.fields
>(x::ts, y::ts) = opjoined(x, y, >)
<(x::ts, y::ts) = opjoined(x, y, <)
>=(x::ts, y::ts) = opjoined(x, y, >=)
<=(x::ts, y::ts) = opjoined(x, y, <=)

# ts + array
+(x::ts, y::Y) where {Y<:VALARR} = x + TS(y, x.index, x.fields)
-(x::ts, y::Y) where {Y<:VALARR} = x - TS(y, x.index, x.fields)
*(x::ts, y::Y) where {Y<:VALARR} = x * TS(y, x.index, x.fields)
/(x::ts, y::Y) where {Y<:VALARR} = x / TS(y, x.index, x.fields)
%(x::ts, y::Y) where {Y<:VALARR} = x % TS(y, x.index, x.fields)
^(x::ts, y::Y) where {Y<:VALARR} = x ^ TS(y, x.index, x.fields)

+(y::Y, x::ts) where {Y<:VALARR} = TS(y, x.index, x.fields) + x
-(y::Y, x::ts) where {Y<:VALARR} = TS(y, x.index, x.fields) - x
*(y::Y, x::ts) where {Y<:VALARR} = TS(y, x.index, x.fields) * x
/(y::Y, x::ts) where {Y<:VALARR} = TS(y, x.index, x.fields) / x
%(y::Y, x::ts) where {Y<:VALARR} = TS(y, x.index, x.fields) % x
^(y::Y, x::ts) where {Y<:VALARR} = TS(y, x.index, x.fields) ^ x

+(x::ts, y::Y) where {Y<:VALTYPE} = TS(x.values .+ y, x.index, x.fields)
-(x::ts, y::Y) where {Y<:VALTYPE} = TS(x.values .- y, x.index, x.fields)
*(x::ts, y::Y) where {Y<:VALTYPE} = TS(x.values .* y, x.index, x.fields)
/(x::ts, y::Y) where {Y<:VALTYPE} = TS(x.values ./ y, x.index, x.fields)
%(x::ts, y::Y) where {Y<:VALTYPE} = TS(x.values .% y, x.index, x.fields)
^(x::ts, y::Y) where {Y<:VALTYPE} = TS(x.values .^ y, x.index, x.fields)

+(y::Y, x::ts) where {Y<:VALTYPE} = x + y
-(y::Y, x::ts) where {Y<:VALTYPE} = TS(y .- x.values, x.index, x.fields)
*(y::Y, x::ts) where {Y<:VALTYPE} = x * y
/(y::Y, x::ts) where {Y<:VALTYPE} = TS(y ./ x.values, x.index, x.fields)
%(y::Y, x::ts) where {Y<:VALTYPE} = TS(y .% x.values, x.index, x.fields)
^(y::Y, x::ts) where {Y<:VALTYPE} = TS(y .^ x.values, x.index, x.fields)
