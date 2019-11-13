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
const VALTYPE = Real
const IDXTYPE = TimeType
const FLDTYPE = Symbol
const VALARR = AbstractArray{<:VALTYPE}
const IDXARR = AbstractVector{<:IDXTYPE}
const FLDARR = AbstractArray{<:Union{Symbol,String,Char}}


# type definition/constructor
"""
Time series type aimed at efficiency and simplicity.

Motivated by the `xts` package in R and the `pandas` package in Python.
"""
mutable struct TS{V<:VALTYPE,T<:IDXTYPE}
    values::Matrix{V}
    index::Vector{T}
    fields::Vector{FLDTYPE}
    function TS(values::Matrix{V}, index::Vector{T}, fields::Vector{FLDTYPE}) where {V<:VALTYPE,T<:IDXTYPE}
        @assert size(values,1)==length(index) "Length of index not equal to number of value rows."
        @assert size(values,2)==length(fields) "Length of fields not equal to number of columns in values."
        order = sortperm(index)
        return new{V,T}(values[order,:], index[order], fields)
    end
end

# alias
const ts = TS

# basic utilities
collect(x::TS) = x
copy(x::TS) = TS(x.values, x.index, x.fields)
eltype(x::TS) = eltype(x.values)
first(x::TS) = x[1]
isempty(x::TS) = (isempty(x.index) && isempty(x.values))
iterate(x::TS) = size(x,1) == 0 ? nothing : (x.index[1], x.values[1,:]), 2
iterate(x::TS, i::Int) = i == lastindex(x, 1) + 1 ? nothing : ((x.index[i], x.values[i,:]), i+1)
last(x::TS) = x[end]
lastindex(x::TS) = lastindex(x.values)
lastindex(x::TS, d) = lastindex(x.values, d)
length(x::TS) = prod(size(x))::Int
ndims(::TS) = 2
ndims(::Type{TS{V,T}}) where {V<:VALTYPE,T<:IDXTYPE} = 2
size(x::TS) = size(x.values)
size(x::TS, dim::Int) = size(x.values, dim)