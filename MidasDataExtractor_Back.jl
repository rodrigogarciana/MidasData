using CSV, DataFrames, DelimitedFiles, Dates

##Need to check where the header is or check if it is standard


#function extractDataMidas(sites::Array{String,1},properties::Array{String,1},years::Array{Int64,1},DataSet::String,Version::String,QC::String;timestep::Int64=30)
function extractDataMidas(files::Array{String,1},properties::Array{String,1},year::Int64;timestep::Int64=30,outputfile="$(pwd())/Output")

    allProperties::Array{Array{Float64,1},1}=Array{Array{Float64,1},1}();
    propCols::Array{Int64,1}=Int64[];
    normTime::Array{String,1}=String[];
    normTimeUnix::Array{Float64,1}=Array{Float64,1}();

    for f in eachindex(files)
        allProperties=Array{Array{Float64},1}();
        input_file=readdlm(files[f],',');
        hL=findfirst(input_file.=="data")[1]+1 ## Finding the header row
        eL=findfirst(input_file.=="end data")[1]-1 ## Finding the last row with actual data
        timeCol=findfirst("ob_time".==a[hL,:]) ##Finding the column in header with the timestamp
        propCols=Int64[];
        for p in eachindex(properties)
            push!(propCols,findfirst(properties[p].==a[hL,:])) #Getting all the columns for the required properties
        end

        normTime=input_file[hL+1:eL,timeCol]; ## "normalised metoffice time"
        unique!(normTime); ## Removing duplicates (if any)
        normTimeUnix=Array{Float64,1}(undef,length(normTime))
        for i in eachindex(normTime) #Converting the existing timestamps to unix format
            normTimeUnix[i]=datetime2unix(DateTime(parse(Int64,normTime[i][1:4]),parse(Int64,normTime[i][6:7]),parse(Int64,normTime[i][9:10]),parse(Int64,normTime[i][12:13]),parse(Int64,normTime[i][15:16]),parse(Int64,normTime[i][18:19])))
        end

        startingUnix=datetime2unix(DateTime(year)); #Starting period of the year in unix format
        requiredPoints=datetime2unix.(range(DateTime(year),DateTime(year+1)-Minute(timestep),step=Minute(timestep))); #Spacing required

        propertyValues=[Array{Float64,1}(undef,length(requiredPoints)) for p in eachindex(properties)];

        for p in eachindex(properties)
            propertyTimeUnix=deepcopy(normTimeUnix);
            rowsProperty=collect(hL+1:eL);
            propertyData=input_file[rowsProperty,propCols[p]];

            dataNA=findall(propertyData.=="NA")
            dataMissing=findall(ismissing.(propertyData));
            rowstoremove=sort(vcat(dataNA,dataMissing),rev=true)

            for i in 1:length(rowstoremove)
                popat!(propertyData,rowstoremove[i])
                popat!(propertyTimeUnix,rowstoremove[i])
            end


            propertyDataN=Array{Float64,1}(undef,length(propertyData));
            for j in eachindex(propertyData)
                if typeof(propertyData[j])==String
                    propertyDataN[j]=parse(Float64,propertyData[j]);
                elseif typeof(propertyData[i])==Float64
                    propertyDataN[j]=propertyData[j]
                else
                    println("Warning, check datatypes, $((propertyData[j]))")
                end
            end


            propertyOutput=Array{Float64,1}(undef,length(requiredPoints))
            for i in eachindex(propertyOutput)
                temp=searchsorted(propertyTimeUnix,requiredPoints[i]);
                start,stop=(temp.stop,temp.start)


                if start==0
                    propertyOutput[i]=propertyDataN[stop]
                elseif stop>=length(unixrT) || stop==start
                    propertyOutput[i]=propertyDataN[start]
                else
                    propertyOutput[i]=round(propertyDataN[start]-(propertyTimeUnix[start]-requiredPoints[i])/(propertyTimeUnix[start]-propertyTimeUnix[stop])*(propertyDataN[start]-propertyDataN[stop]),digits=3) #interpolation
                end
            end

            ###
            push!(allProperties,propertyOutput)

        end
        open(outputfile*"_file$(f)_year$year.csv", "w") do k
            write(k,"period") #header
            for p in eachindex(properties) write(k,",$(properties[p])") end
            write(k,"\n");

            for i in eachindex(requiredPoints)
                write(k, "$i")
                for p in eachindex(properties) write(k,",$(allProperties[p][i])")end
                write(k,"\n");
            end
        end

    end
end





######
#function extractDataMidas(sites::Array{String,1},properties::Array{String,1},year::Int64,dataset::String,version::String,QC::String;timestep::Int64=30)

#(["00009","00251"],["air_temperature","dew_point"],[2015],"uk-hourly-weather-obs","dataset-version-202007","qc-version-1";timestep=30)
using FTPClient, DelimitedFiles

dataset="uk-hourly-weather-obs";
version="dataset-version-202007";
sites=[9,253]
qc_version="qc-version-1"
years=[2015,2016]

### Geting station general information
stationData=readdlm("stationList.csv",',');
colNames=stationData[1,:];
colsrc=findfirst(colNames.=="src_id") ##Station source id
colstname=findfirst(colNames.=="station_name") ##Station name
colstfilename=findfirst(colNames.=="station_file_name") ##filename
colcounty=findfirst(colNames.=="historic_county") ##County
colfstyr=findfirst(colNames.=="first_year") ##First year
collstyr=findfirst(colNames.=="last_year") ##Last year
###

source_directory="source_files"
output_directory="output_files"
try
    cd(source_directory)
    cd("..")
catch
    mkdir(source_directory)
end

try
    cd(output_directory)
    cd("..")
catch
    mkdir(output_directory)
end


ftp_server="ftp.ceda.ac.uk/badc/ukmo-midas-open/data"  # MetOffice Open Datasets
#user=ENV["CEDA_USER"];
#password=ENV["CEDA_PASSWORD"];
user="orei"
password="orei2021"

ftp=FTP(hostname=ftp_server,username=user,password=password)
startingDir=pwd(ftp);


siteRow=[Int64[] for y in eachindex(years)];
actualSites=[Int64[] for y in eachindex(years)];

for s in eachindex(sites)
    for y in eachindex(years)
        if findfirst(sites[s].==stationData[:,colsrc])==nothing
            println("Warning: site $(sites[s]) not found, please verify.")
        else
            siteRowTemp=findfirst(sites[s].==stationData[:,colsrc]);
            if !(years[y] in collect(stationData[siteRowTemp,colfstyr]:stationData[siteRowTemp,collstyr]))
                println("Warning: Year $(years[y]) not included in site $(sites[s]), please verify your request.")
            else
                push!(actualSites[y],sites[s])
                push!(siteRow[y],siteRowTemp)
            end
        end
    end
end

downloadedFiles=String[];

println("\n$(repeat("-",50))\n$(repeat(" ",5))Downloading source files\n$(repeat("-",50))\n\n")
for y in eachindex(years)
    for s in eachindex(actualSites[y])
        cd(ftp,startingDir*"/"*dataset*"/"*version*"/"*stationData[siteRow[y][s],colcounty]*"/"*string(stationData[siteRow[y][s],colsrc],pad=5)*"_"*stationData[siteRow[y][s],colstfilename]*"/"*qc_version*"/")
        fileList=readdir(ftp);
        fNumber=findfirst(occursin.(string(years[y])*".csv",fileList));
        fLRemote="$(pwd(ftp))/$(fileList[fNumber])"
        fLLocal="$(pwd())/$source_directory/$(fileList[fNumber])"
        push!(downloadedFiles,fLLocal)
        command=`curl -u $user:$password ftp://ftp.ceda.ac.uk$fLRemote -o $fLLocal`
        st=run(command);
        if st.exitcode==0
            println("Site $(sites[s]) ($(stationData[siteRow[y][s],colstname]), $(years[y])) information downloaded successfully in folder $source_directory\n")
        end
    end
end
println("\n$(repeat("-",50))\n$(repeat(" ",5))Download complete\n$(repeat("-",50))\n\n")

println("\n$(repeat("-",50))\n$(repeat(" ",5))Data preparation\n$(repeat("-",50))\n\n")
