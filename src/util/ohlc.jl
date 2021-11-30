# Methods to more easily handle financial data

# Check for various key financial field names
has_open(x::ts)::Bool = any([occursin(r"(op)"i, String(f)) for f in x.fields])
has_high(x::ts)::Bool = any([occursin(r"(hi)"i, String(f)) for f in x.fields])
has_low(x::ts)::Bool = any([occursin(r"(lo)"i, String(f)) for f in x.fields])
has_volume(x::ts)::Bool = any([occursin(r"(vo)"i, String(f)) for f in x.fields])
function has_close(x::ts; allow_settle::Bool=true, allow_last::Bool=true)::Bool
    columns = String.(x.fields)
    if allow_settle && allow_last
        # return any(occursin.(r"(cl)|(last)|(settle)"i, columns))
        return any([occursin(r"(cl)|(last)|(settle)"i, column) for column in columns])
    end
    if allow_last && !allow_settle
        return any([occursin(r"(cl)|(last)"i, column) for column in columns])
    end
    if allow_settle && !allow_last
        return any([occursin(r"(cl)|(settle)"i, column) for column in columns])
    end
    if !allow_last && !allow_settle
        return any([occursin(r"(cl)"i, column) for column in columns])
    end
    return false
end

# Identify OHLC(V) formats
is_ohlc(x::ts)::Bool = has_open(x) && has_high(x) && has_low(x) && has_close(x)
is_ohlcv(x::ts)::Bool = is_ohlc(x) && has_volume(x)

# Extractor functions
op(x::ts)::ts = x[:,findfirst([occursin(r"(op)"i, String(field)) for field in x.fields])]
hi(x::ts)::ts = x[:,findfirst([occursin(r"(hi)"i, String(field)) for field in x.fields])]
lo(x::ts)::ts = x[:,findfirst([occursin(r"(lo)"i, String(field)) for field in x.fields])]
vo(x::ts)::ts = x[:,findfirst([occursin(r"(vo)"i, String(field)) for field in x.fields])]
function cl(x::ts; use_adj::Bool=true, allow_settle::Bool=true, allow_last::Bool=true)::ts
    columns = String.(x.fields)
    if use_adj
        j = findfirst([occursin(r"(adj((usted)|\s|)+)(cl)?"i, column) for column in columns])
        if !isa(j, Nothing)
            return x[:,j]
        end
    else
        j = findfirst([occursin(r"(?!adj)*(cl(ose|))"i, column) for column in columns])
        if !isa(j, Nothing)
            return x[:,j]
        end
    end
    if allow_settle
        j = findfirst([occursin(r"(settle)"i, column) for column in columns])
        if !isa(j, Nothing)
            return x[:,j]
        end
    end
    if allow_last
        j = findfirst([occursin(r"(last)"i, column) for column in columns])
        if !isa(j, Nothing)
            return x[:,j]
        end
    end
    j = findfirst([occursin(r"(cl)"i, column) for column in columns])
    if !isa(j, Nothing)
        return x[:,j]
    end
    error("No closing prices found.")
end
ohlc(x::ts)::ts = [op(x) hi(x) lo(x) cl(x)]
ohlcv(x::ts)::ts = [op(x) hi(x) lo(x) cl(x) vo(x)]
hlc(x::ts)::ts = [hi(x) lo(x) cl(x)]
hl(x::ts)::ts = [hi(x) lo(x)]
hl2(x::ts)::ts = (hi(x) + lo(x)) * 0.5
hlc3(x::ts; args...)::ts = (hi(x) + lo(x) + cl(x; args...)) / 3
ohlc4(x::ts; args...)::ts = (op(x) + hi(x) + lo(x) + cl(x; args...)) * 0.25
