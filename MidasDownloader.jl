using Printf
run(`clear`);

okflag=true

try
    using FTPClient
catch
    println("\nWarning: Dependency missing")
    println("Package FTPClient not intalled, installing it (only once).")
    using Pkg
    Pkg.add("FTPClient")
    using FTPClient
    println("\nDone.\n")
end

try
    ENV["CEDA_USER"];
    ENV["CEDA_PASSWORD"];
catch
    println("\nError: Environment Variables CEDA_USER and CEDA_PASSWORD not set")
    println("Please set them in terminal with the command 'export CEDA_USER=*****' and 'export CEDA_PASSWORD=*****'")
    println("Alternatively plug in your user and password in the corresponding line of the function in this script.")
    println("To get a CEDA username and password go to 'https://services.ceda.ac.uk/cedasite/register/info/'")
    global okflag=false
end



#Structure of the tree https://help.ceda.ac.uk/article/4982-midas-open-user-guide
function downloadMIDAS()
    ### FTP server information
    ftp_server="ftp.ceda.ac.uk/badc/ukmo-midas-open/data"  # MetOffice Open Datasets
    user=ENV["CEDA_USER"];
    password=ENV["CEDA_PASSWORD"];

    #user="rgarcia005"
    #password="rodrigo1"

    ### General dataset structure information

    ftp=FTP(hostname=ftp_server,username=user,password=password)
    levelDescription=["Dataset","Release-Version","Historic County","Site","QC-Version","Files"]
    notes=["","","","","Quality control version, qc-v0=original data, qc-v1=revised data",""]

    ### Declarations
    datasetIndex::String="";
    selections=Int64[];
    dirs::Array{String,1}=String[];
    selections::Array{Int64,1}=Int64[];
    exitFlag::Bool=false;
    level::Int64=1;
    nolist::Bool=false;
    fpath::String=ftp_server*"/";

    println("\n$(repeat("-",50))\n$(repeat(" ",5))MetOffice (MIDAS Open) Data Downloader\n$(repeat("-",50))\n")

    while !exitFlag

        if !nolist
            printstyled("$(levelDescription[level]):"; bold = true, color=:blue)
            if level==5
                printstyled(" ($(notes[level]))", color=:light_blue)
            end
            println();

            dirs=readdir(ftp); if level!=length(levelDescription); setdiff!(dirs,dirs[findall(occursin.(".",dirs))]); end
            for i in eachindex(dirs)
                @printf("%4i %s\n",i,dirs[i])
            end
            if level!=1
                #@printf("%4s %s\n","B","Back")
                printstyled("   B Back\n"; bold = false, color=:red)
            end
            #@printf("%4s %s\n","Q","Quit")
            printstyled("   Q Quit\n"; bold = false, color=:red)

            print("\nSelect number of $(levelDescription[level]) (1-$(length(dirs))): ")

        else
            print("Select another file to download (1-$(length(dirs))), back (B) or quit (Q): ")
        end
        datasetIndex = readline();
        if (datasetIndex=="B" || datasetIndex=="b") && level!=1
                ###Back navigation
                fpath=fpath[1:findlast('/',fpath[1:end-1])]
                nolist=false
                if level!=length(levelDescription)
                    pop!(selections)
                end
                cd(ftp,"..")
                level-=1
                println("$(repeat("-",40))\n")
        elseif datasetIndex=="Q" || datasetIndex=="q"
                ###Quit navigation
                exitFlag=true
                println("$(repeat("-",40))\n")
        elseif (datasetIndex in string.(1:length(dirs))) && level!=length(levelDescription)
                ###Progress navigation
                push!(selections,parse(Int64,datasetIndex))
                fpath*=dirs[selections[end]]*"/"
                print("You have selected $(dirs[selections[end]]) [Navigation path: ")
                for i in eachindex(selections) print(selections[i]); if i!=length(selections) print(",") else println("]") end end
                cd(ftp,dirs[selections[end]])
                level+=1
                println("$(repeat("-",40))\n")


        elseif (datasetIndex in string.(1:length(dirs))) && level==length(levelDescription)

                push!(selections,parse(Int64,datasetIndex))
                print("Download:  $(dirs[selections[end]]) [Navigation path: ")
                for i in eachindex(selections) print(selections[i]); if i!=length(selections) print(",") else println("]") end end
                pop!(selections)
                print("Select a filename and path or leave it blank to keep the original name at the current path: ")
                filename=readline();
                println("\n$(repeat("-",40))\n")
                if filename==""
                    command=`curl -u $user:$password ftp://$fpath$(dirs[selections[end]]) -o $(dirs[selections[end]])`
                else
                    command=`curl -u $user:$password ftp://$fpath$(dirs[selections[end]]) -o $(filename)`
                end
                st=run(command);
                println("\n$(repeat("-",40))\n")
                if st.exitcode==0
                    println("Download completed successfully\n")
                end
                nolist=true

        else
            println("Invalid selection, please select a valid option from the list")
        end

    end
end

if okflag downloadMIDAS() end
