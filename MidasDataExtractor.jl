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
using FTPClient

dataset="uk-hourly-weather-obs";
version="dataset-version-202007";
sites=["00009","00251"]
qc_version="qc-version-1"

ftp_server="ftp.ceda.ac.uk/badc/ukmo-midas-open/data"  # MetOffice Open Datasets
#user=ENV["CEDA_USER"];
#password=ENV["CEDA_PASSWORD"];
user="orei"
password="orei2021"

ftp=FTP(hostname=ftp_server,username=user,password=password)
startingDir=pwd(ftp);

cd(ftp,dataset*"/"*version*"/")
regionDirs=readdir(ftp); setdiff!(regionDirs,regionDirs[findall(occursin.(".",regionDirs))]);
sourceFiles=String[];

for i in eachindex(regionDirs)
    cd(ftp,regionDirs[i]);
    siteDirs=readdir(ftp);
    if findfirst(occursin.(sites[1]*"_",siteDirs))!=nothing
        cd(ftp,siteDirs[findfirst(occursin.(sites[1],siteDirs))]*"/"*qc_version)
        fileList=readdir(ftp);
        if findfirst(occursin.(string(year)*".csv",fileList))!=nothing
            fNumber=findfirst(occursin.(string(year)*".csv",fileList));
            fLRemote="$(pwd(ftp))/$(fileList[fNumber])"
            fLLocal="$(pwd())/$(fileList[fNumber])"
            command=`curl -u $user:$password ftp://ftp.ceda.ac.uk$fLRemote -o $fLLocal`
            st=run(command);
            if st.exitcode==0
                println("Site $(sites[1]) information downloaded successfully\n")
            end
            break
        else
            println("File for the requested year not found, please verify data (stopping)")
            break;
        end
    else
        cd(ftp,"..")
    end
end
