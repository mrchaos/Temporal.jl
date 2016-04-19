VERSION >= v"0.4.0" && __precompile__(true)

using Base.Dates
module Temporal

export
    TS, ts, size, overlaps,
    ojoin, ijoin, ljoin, rjoin, merge, hcat, vcat,
    nanrows, nancols, dropnan,
    numfun, arrfun, op,
    ones, zeros, trues, falses, isnan,
    sum, mean, maximum, minimum, prod, cumsum, cumprod, diff, lag, nans,
    mondays, tuesdays, wednesdays, thursdays, fridays, saturdays, sundays, 
    bow, eow, bom, eom, boq, eoq, boy, eoy,
    toweekly, tomonthly, toquarterly, toyearly, aggregate,
    tsread, tswrite

include("ts.jl")
include("indexing.jl")
include("combine.jl")
include("collapse.jl")
include("operations.jl")
include("slice.jl")
include("io.jl")

end
