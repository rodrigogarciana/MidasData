a=readdlm("DataProcess/midas-open_uk-hourly-weather-obs_dv-202007_northamptonshire_00578_northampton-moulton-park_qcv-1_2015.csv",',')

##Select ob_time as normalised time (end-1 because the last row contains "end data")
normTime=df.ob_time[1:end-1];
##Select ob_time as normalised time
unique!(normTime);
rT=Array{DateTime,1}(undef,length(normTime))
unixrT=Array{Float64,1}(undef,length(normTime))

baseT=DateTime(2015)
unixBase=datetime2unix(baseT)

datesChecked=range(DateTime(2015),DateTime(2016)-Minute(30),step=Minute(30));
consecChecked=[i for i in eachindex(datesChecked)]
datesCheckedUnix=datetime2unix.(datesChecked)

for i in eachindex(normTime)
    rT[i]=DateTime(parse(Int64,normTime[i][1:4]),parse(Int64,normTime[i][6:7]),parse(Int64,normTime[i][9:10]),parse(Int64,normTime[i][12:13]),parse(Int64,normTime[i][15:16]),parse(Int64,normTime[i][18:19]))
    unixrT[i]=datetime2unix(rT[i])
end

dataNA=findall(df.air_temperature[1:end-1].=="NA")
dataMissing=findall(ismissing.(df.air_temperature[1:end-1]))
rowstoremove=sort(vcat(dataNA,dataMissing),rev=true)

aTempS=df.air_temperature[1:end-1];
for i in 1:length(rowstoremove)
    popat!(aTempS,rowstoremove[i])
    popat!(rT,rowstoremove[i])
    popat!(unixrT,rowstoremove[i])
end


aTempOutput=Array{Float64,1}(undef,length(datesChecked))
for i in eachindex(aTempOutput)
    start,stop=[searchsorted(unixrT,datesCheckedUnix[i]).stop,searchsorted(unixrT,datesCheckedUnix[i]).start]
    #println([start,stop])
    aTemp=parse.(Float64,aTempS);
    if start==0
        aTempOutput[i]=aTemp[stop]
    elseif stop>=length(unixrT)
        aTempOutput[i]=aTemp[start]
    elseif stop==start
        aTempOutput[i]=aTemp[start]
    else
        aTempOutput[i]=round(aTemp[start]-(unixrT[start]-datesCheckedUnix[i])/(unixrT[start]-unixrT[stop])*(aTemp[start]-aTemp[stop]),digits=3)
    end

    #if isnan(aTempOutput[i])
    # println(i,",start=$start,stop=$stop,aTemp=$(aTemp[start]),$(aTemp[stop]),$(unixrT[start]),$(unixrT[stop])",aTempOutput[i])
    #end
end

open("DataProcess/00578_2015.csv", "w") do f
    write(f,"period,air_temperature\n") #header
    for i in eachindex(aTempOutput)
        write(f, "$i, $(aTempOutput[i])\n")
    end
end
