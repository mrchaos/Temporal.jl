# utilities for altering existing TS objects

# in place
function rename!(t::ts, args::Pair{Symbol, Symbol}...)
    d = Dict{Symbol, Symbol}(args...)
    flag = false
    for (i, field) in enumerate(t.fields)
        if field in keys(d)
            t.fields[i] = d[field]
            flag = true
        end
    end
end

function rename!(f::Base.Callable, t::ts, colnametyp::Type{Symbol} = Symbol)
    for (i, field) in enumerate(t.fields)
        t.fields[i] = f(field)
    end
end

function rename!(f::Base.Callable, t::ts, colnametyp::Type{String})
    f = Symbol ∘ f ∘ string
    rename!(f, t)
end

# not in place
function rename(t::ts, args::Pair{Symbol, Symbol}...)
    ts2 = copy(t)
    rename!(ts2, args...)
    ts2
end

function rename(f::Base.Callable, t::ts, colnametyp::Type{Symbol} = Symbol)
    ts2 = copy(t)
    rename!(f, ts2, colnametyp)
    ts2
end

function rename(f::Base.Callable, t::ts, colnametyp::Type{String})
    ts2 = copy(t)
    rename!(f, ts2, colnametyp)
    ts2
end
