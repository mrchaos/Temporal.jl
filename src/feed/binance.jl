import HTTP
import DataFrames
import URIs
import JSON
import TimeZones

using DataFrames: DataFrame,transform!,select
using Chain: @chain
using Decimals: Decimal, decimal
using Printf: @sprintf
using TimeZones: @tz_str,ZonedDateTime,astimezone,TimeZone


const BINANCE_URL = "https://api.binance.com/api/v3/klines"

"HTTP response to JSON"
function r2j(response)
    JSON.Parser.parse(String(response))
end

"timestamp to datetime"
function ts2dt(timestamp::Int64)::DateTime
    unix2datetime(timestamp/1_000)
end

"datetime to timestamp"
function dt2ts(dt::DateTime)::Int64
    Int64(floor(datetime2unix(dt)*1_000))
end

"yyyy-mm-dd hh:mm:ss (UTC) string to timestamp"
function st2ts(st::String)
    dt = DateTime(st,dateformat"y-m-d H:M:S")
    dt2ts(dt)
end

"dict to params"
function d2p(dict::Dict)::String
    #?a=1&b=2 ==> a=1&b=2
    string(URIs.URI(query=dict))[2:end]
end

str2float(x) = parse.(Float64,x)

""" local datetime to UTC datetime
local yyyy-mm-dd hh:mm:ss string to UTC datetime """
function local_st2utc_dt(st::String;
                        timezone::String="Asia/Seoul")::DateTime
    zdt= ZonedDateTime(
            DateTime(st,dateformat"y-m-d H:M:S"),
            TimeZone("$(timezone)")
          )
    dt = DateTime(zdt,Dates.UTC)
end


""" UTC datetime to local datetime
utc yyyy-mm-dd hh:mm:ss string to local datetime """
function utc_st2local_dt(st::String;
                        timezone::String="Asia/Seoul")::DateTime
    zdt= ZonedDateTime(
            DateTime(st,dateformat"y-m-d H:M:S"),
            TimeZone("UTC")
          )
    dt = DateTime(astimezone(zdt,TimeZone(timezone)))
end

""" 
UTC time stamp to local datetime
timestamp (UTC) string to datetime
"""
function utc_ts2local_dt(ts::Int64;
                        timezone::String="Asia/Seoul")::DateTime
    zdt= ZonedDateTime(
            ts2dt(ts),
            tz"UTC"
          )
    DateTime(
      astimezone(zdt, TimeZone("$(timezone)")))
end

"""
Kline/Candlestick data
Close Time  내림차순 정렬
freq : 1m 3m 5m 15m 30m 1h 2h 4h 6h 8h 12h 1d 3d 1w 1M 
[
  [
    1499040000000,      // open_time
    "0.01634790",       // open
    "0.80000000",       // high
    "0.01575800",       // low
    "0.01577100",       // close
    "148976.11427815",  // volume
    1499644799999,      // close_time
    "2434.19055334",    // quote_asset_volume
    308,                // number_of_trades
    "1756.87402397",    // taker_buy_base_asset_volume
    "28.46694368",      // taker_buy_quote_asset_volume
    "17928899.62484339" // ignore
  ]
]
limit : max=1000
"""
function binance(symb::String;
    from::String="2012-01-01",
    thru::String=string(Dates.today()),
    freq::String="1m", # 1m 3m 5m 15m 30m 1h 2h 4h 6h 8h 12h 1d 3d 1w 1M 
    limit::Int64=500,
    timezone::String="Asia/Seoul")::TS  # max : 1000
  
    d = Dict{String,Any}()
    if symb != ""
      d["symbol"] = symb
    end
  
    if freq != ""
      d["interval"] = freq
    end
  
    if from != ""
      d["startTime"] = st2ts(from)
    end
  
    if thru != ""
      d["endTime"] = st2ts(thru)
    end  
  
    if limit > 0
      d["limit"] = limit
    end  
  
    if d.count > 0
      query = string("?",d2p(d))
    else
      query = ""
    end
  
    r = HTTP.request("GET",string(BINANCE_URL,query))
    j = r2j(r.body)

    if size(j)[1] > 0
      d = j[1]
      # reshape :  [1,2,3] -> [[1],[2],[3]]
      df = DataFrame([[x] for x in d],
        [:open_time,:open,:high,:low,:close,:volume,
        :close_time,:quote_asset_volume,:number_of_trades,
        :taker_buy_base_asset_volume,:taker_buy_quote_asset_volume,:ignore])
      for d in j[2:end]
        push!(df,d)
      end
    else
      df = DataFrame()
    end
    header=[:open,:high,:low,:close,:volume,:quote_asset_volume,
    :taker_buy_base_asset_volume,:taker_buy_quote_asset_volume]

    if size(df)[begin] > 0
      # time관련 columns    
      dtnms1 = [:open_time,:close_time]
      # local datetime
      dtnms2 = [:open_time_local,:close_time_local]
      @chain df begin
        transform!(header.=>str2float.=>header)
        transform!(dtnms1.=>(t->utc_ts2local_dt.(t;timezone=timezone)).=>dtnms2)      
        sort!(:open_time,rev=true)
      end    
    end

    
    df_sub = select(df,header,copycols=false)    

    # TS(values, index, fields)
    # TS(Matrix{Float64},Vector{DateTime},Vector{String})
    return TS(Matrix{Float64}(df_sub),
              Matrix(select(df,[:open_time_local]))[:,1], 
              header)
end
