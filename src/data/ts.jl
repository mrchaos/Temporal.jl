import Dates:
    Date,
    DateTime,
    TimeType

import Base:
    collect,
    convert,
    copy,
    eltype,
    float,
    isempty,
    iterate,
    lastindex,
    length,
    ndims,
    show,
    size

# outermost allowed element type
const VALTYPE = Union{Float64,Int64,Bool}
const IDXTYPE = Union{Date,DateTime}
const FLDTYPE = Union{Symbol,String,Char}
const VALARR = AbstractArray{<:VALTYPE}
const IDXARR = AbstractVector{<:IDXTYPE}
const FLDARR = AbstractVector{<:FLDTYPE}


# type definition/constructor
@doc """
Time series type aimed at efficiency and simplicity.

_Fields_:

    - `values`: 2-dimensional array of numerical data
    - `index`: 1-dimensional array of `Date` or `DateTime` representing index where element t corresponds t'th row of `values`
    - `fields`: 1-dimensional array of `Symbol` representing columns where element j corresponds to j'th column of `values`
""" ->
mutable struct TS{V<:VALTYPE,T<:IDXTYPE}
    values::Matrix{V}
    index::Vector{T}
    fields::Vector{Symbol}
    function TS(values::Matrix{V}, index::Vector{T}, fields::Vector{Symbol}) where {V<:VALTYPE, T<:IDXTYPE}
        @assert size(values,1)==length(index) "Length of index not equal to number of value rows."
        @assert size(values,2)==length(fields) "Length of fields not equal to number of columns in values."
        order = sortperm(index)
        return new{V,T}(values[order,:], index[order], fields)
    end
end

# alias
const ts = TS{V<:VALTYPE,T<:IDXTYPE}

# basic utilities
collect(x::ts) = x
copy(x::ts) = TS(copy(x.values), copy(x.index), copy(x.fields))
eltype(x::ts) = eltype(x.values)
first(x::ts) = x[1]
isempty(x::ts) = (isempty(x.index) && isempty(x.values))
iterate(x::ts) = size(x,1) == 0 ? nothing : (x.index[1], x.values[1,:]), 2
iterate(x::ts, i::Int) = i == lastindex(x, 1) + 1 ? nothing : ((x.index[i], x.values[i,:]), i+1)
last(x::ts) = x[end]
lastindex(x::ts) = lastindex(x.values)
lastindex(x::ts, d) = lastindex(x.values, d)
length(x::ts) = prod(size(x))::Int
ndims(::ts) = 2
ndims(::Type{TS{V,T}}) where {V<:VALTYPE,T<:IDXTYPE} = 2
size(x::ts) = size(x.values)
size(x::ts, dim::Int) = size(x.values, dim)
