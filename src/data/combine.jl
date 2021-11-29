#=
Utilities for combining and manipulating TS objects with their indexes
=#

import Base: hcat, vcat, merge

# function partner(x::ts, y::ts)
#     yy = !overlaps(x.index, y.index) .* NaN
#     yy[!isnan(yy),:] = y.values
#     return ts(yy, x.index, y.fields)
# end

"""
    ojoin(x::ts,y::ts)::ts

Outer join two TS objects by index.

Equivalent to `x` OUTER JOIN `y` ON `x.index` = `y.index`.

...
# Arguments
- `x::ts`: Left side of the join.
- `y::ts`: Right side of the join.
...
"""
function ojoin(x::ts, y::ts)::ts
    if isempty(x) && !isempty(y)
        return y
    elseif isempty(y) && !isempty(x)
        return x
    elseif isempty(x) && isempty(y)
        return ts()
    end
    idx = union(x.index, y.index)
    xna = setdiff(idx, x.index)
    yna = setdiff(idx, y.index)
    xi = sortperm(unique([x.index; xna]))
    yi = sortperm(unique([y.index; yna]))
    xvals = [x.values; fill(NaN, (length(xna), size(x,2)))][xi,:]
    yvals = [y.values; fill(NaN, (length(yna), size(y,2)))][yi,:]
    return ts([xvals yvals], sort(idx), [x.fields; y.fields])
end

"""
    ijoin(x::ts,y::ts)::ts

Inner join two TS objects by index.

Equivalent to `x` INNER JOIN `y` on `x.index` = `y.index`.

...
# Arguments
- `x::ts`: Left side of the join.
- `y::ts`: Right side of the join.
...
"""
function ijoin(x::ts, y::ts)::ts
    if isempty(x) && !isempty(y)
        return y
    elseif isempty(y) && !isempty(x)
        return x
    elseif isempty(x) && isempty(y)
        return ts()
    end
    idx = intersect(x.index, y.index)
    return ts([x[idx].values y[idx].values], idx, [x.fields; y.fields])
end

"""
    ljoin(x::ts, y::ts)::ts

Left join two TS objects by index.

Equivalent to `x` LEFT JOIN `y` ON `x.index` = `y.index`.

...
# Arguments
- `x::ts`: Left side of the join.
- `y::ts`: Right side of the join.
...
"""
function ljoin(x::ts, y::ts)::ts
    return [x y[intersect(x.index, y.index)]]
end

"""
    rjoin(x::ts, y::ts)::ts

Right join two TS objects by index.

Equivalent to `x` RIGHT JOIN `y` ON `x.index` = `y.index`.

...
# Arguments
- `x::ts`: Left side of the join.
- `y::ts`: Right side of the join.
...
"""
function rjoin(x::ts, y::ts)::ts
    return [x[intersect(x.index, y.index)] y]
end

hcat(x::ts, y::ts)::ts = ojoin(x, y)
hcat(x::ts)::ts = x
function hcat(series::ts...)
    out = series[1]
    @inbounds for j = 2:length(series)
        out = [out series[j]]
    end
    return out
end
function vcat(x::ts, y::ts)
    @assert size(x,2) == size(y,2) "Dimension mismatch: Number of columns must be equal."
    return TS([x.values;y.values], [x.index;y.index], x.fields)
end
function vcat(series::ts...)
    out = series[1]
    @inbounds for j = 2:length(series)
        out = vcat(out, series[j])
    end
    return out
end

"""
    merge(x::ts,y::ts;join::Char='o')::ts

Merge two time series objects together by index with an optionally specified join type parameter.

...
# Arguments
- `x::ts`: Left side of the join.
- `y::ts`: Right side of the join.
Optional args:
- `join::Char='o'::ts`: Specifies the logic used to perform the merge, and may take on the values 'o' (outer join), 'i' (inner join), 'l' (left join), or 'r' (right join). Defaults to outer join, whose result is the same as `hcat(x, y)` or `[x y]`.
...
"""
function merge(x::ts, y::ts; join::Char='o')::ts
    @assert join == 'o' || join == 'i' || join == 'l' || join == 'r' "`join` must be 'o', 'i', 'l', or 'r'."
    if join == 'o'
        return ojoin(x, y)
    elseif join == 'i'
        return ijoin(x, y)
    elseif join == 'l'
        return ljoin(x, y)
    elseif join == 'r'
        return rjoin(x, y)
    end
end

#===============================================================================
                COMBINING/MERGING WITH OTHER TYPES
===============================================================================#
hcat(x::ts, y::AbstractArray)::ts = ojoin(x, ts(y, x.index))
hcat(y::AbstractArray, x::ts)::ts = ojoin(ts(y, x.index), x)
hcat(x::ts, y::Number)::ts = ojoin(x, ts(fill(y,size(x,1)), x.index))
hcat(y::Number, x::ts)::ts = ojoin(ts(fill(y,size(x,1)), x.index), x)

function getmaxtype(arrs)::Type
    result::Type = Any
    @inbounds for k in 2:length(arrs)
        result = eltype(promote(arrs[k-1][1], arrs[k][1]))
    end
    return result
end

function hcat(series::ts, arrs::AbstractArray...)::ts
    n = size(series,1)
    cols = map(arr->size(arr,2), arrs)
    rows = map(arr->size(arr,1), arrs)
    @assert all(rows.==n) "All arrays must have same number of rows as TS object."
    out = zeros(getmaxtype(arrs), (n, sum(cols)))
    first_col, last_col = 0, 0
    @inbounds for j in 1:length(arrs)
        last_col = first_col + cols[j]
        first_col = last_col - first_col
        out[:,first_col:last_col] = arrs[j]
    end
    return [series out]
end

function hcat(series::ts, nums::Number...)::ts
    n = size(series,1)
    k = length(nums)
    T::Type = getmaxtype(nums)
    out = zeros(T, (n,k))
    @inbounds for j in 1:k
        out[:,j] = ones(T,n) * nums[j]
    end
    return [series out]
end
