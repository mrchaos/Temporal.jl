import DataFrames
import Arrow

"""
arrow_read(file::String;index_column_name::String="")::ts

Read contents from a arrow file into a TS object.

# Arguments
- `file::String`: path to the input file (arrow file)
Optional args:
- `index_column_name::String=""`: column name of index, default: "Index"

# Example

    X = arrow_read("data.arrow")

"""
function arrow_read(file::String;index_column_name::String="")::ts
    df = DataFrames.DataFrame(Arrow.Table(file))
    if index_column_name==""
        index_column_name = "Index"
    end
    df_sub = DataFrames.select(df,DataFrames.Not(index_column_name),copycols=false)

    # TS(Vector{String},Matrix{Float64},Vector{DateTime})
    return TS(Matrix{Float64}(df_sub),
            Matrix(DataFrames.select(df,[index_column_name],copycols=false))[:,1], 
            names(df_sub))    
end


"""
    arrow_write(X::ts,file::String)::Nothing

Write time series data to a arrow file.

# Arguments
- `x::ts`: time series object to write to a file
- `file::String`: filepath to which object shall be written

# Example

    X = TS(randn(252, 4))
    arrow_write(X, "data.arrow")

"""
function arrow_write(X::Type{TS},file::String)::Nothing
    df = DataFrames.DataFrame(X.values,X.fields)
    DataFrames.insertcols!(df,1,:Index=>X.index)
    Arrow.write(file,df)
    nothing
end
