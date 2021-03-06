# MIDAS Open Data Downloader

## Brief Description

The scripts found in this repository help to navigate, download and automate the process of extracting data from the open datasets: Met Office Integrated Data Archive System (MIDAS).

There are two julia executable files: MidasDownloader.jl and MidasDataExtractor.jl. Each file serves a different function.

The file MidasDownloader.jl is a tool that helps navigate the FTP server manually and download the requested original files.

The file MidasDataExtractor.jl helps to automate the process of data extraction for a list of sites and properties desired, it also performs linear interpolation for missing datapoints or when the required time-steps are shorter that the original data.

## Prerequisites

Install [Julia 1.x](https://julialang.org/downloads/), and then the script will automatically request the package [FTPClient](https://github.com/invenia/FTPClient.jl) if not already installed.

An account with CEDA is also required. To get a free CEDA username and password go to https://services.ceda.ac.uk/cedasite/register/info/

Finally, clone or download this respository:
```ShellSession
$ git clone https://github.com/rodrigogarciana/MidasData.git
```

## Running the Downloader script

Open the terminal and set your environment variables.
```ShellSession
$ export CEDA_USER=your_ceda_username
$ export CEDA_PASSWORD=your_ceda_password
```
Execute Julia with the name of the desired script
```ShellSession
$ julia MidasDownloader.jl
```

Navigate in the tree and download the desired files.

Setting environment variables is a straightforward process in Linux and macOS, not so much in Windows. As an alternative, start julia in the folder where the script is located or navigate to this folder.

```ShellSession
cd ~/path_to_folder/MidasData/
```

```ShellSession
julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.x.x (xxxx-xx-xx)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> ENV["CEDA_USER"]="your_ceda_username"
julia> ENV["CEDA_PASSWORD"]="your_ceda_password"
julia> include("MidasDownloader.jl")
```

## Running the Data extractor script

Open the terminal and set your environment variables.
(If the environment variables can't be easily set then set them inside julia) [read previous script description].

```ShellSession
$ export CEDA_USER=your_ceda_username
$ export CEDA_PASSWORD=your_ceda_password
```
Execute Julia with the name of the desired script
```ShellSession
$ julia MidasDataExtractor.jl
```

Steps:

1) First, the script will ask for the ID of the sites where the information is needed. There are 3 options in knowing what are the site ids corresponding to different sites:

a) To view an interactive map of the location of the stations go to (Chrome/Firefox, Incognito).
http://dap.ceda.ac.uk/badc/ukmo-midas-open/metadata/midasmap/map.html

b) To search for specific information about stations go to:
https://archive.ceda.ac.uk/midas_stations/

c) To see a CSV file list with this information check the file stationList.csv in this repository.

Please note that different sites have different years of activity, please make sure that the site you are choosing has the data for the required year.

```ShellSession
Desired sites (by ID) separated by commas, (e.g. 9,253,367):
9,253
```
In this example we are asking for sites 9 and 253, corresponding to Lerwick and Edinburgh RBG stations.


2) The script will ask the years when data is needed:

```ShellSession
Desired years separated by commas, (e.g. 2014,2015):
2010,2011,2012
```
In this example we are asking for years 2010-2012.


3) The script will ask for the properties ([column names] from the tables in the original CSV files), the easiest way to get the properties is to use the MidasDownloader.jl script and download a file (any file) in the wanted dataset and see which information is found in those tables.

```ShellSession
Desired properties separated by commas, (e.g. air_temperature,dewpoint):
air_temperature
```
In this example we are only asking air temperature (air_temperature).

4) Set the "resolution" of the interpolated data:

```ShellSession
Required time resolution (time-step) in minutes, (e.g. 30):
15
```
In here we want a 15 minute resolution.

5-7) Select (with numbers) the dataset, version and quality control version for the source files.

After that, the script will start to download the source files (original datasets) in the subfolder "source_files". After finishing the downloads, the processed output files will be stored in the subfolder "output_files".

That's it!


## Output file contents

The output files will be in the CSV format, with the first column corresponding to the consecutive period of the year starting from 1 (Jan-01, 00:00) and each consecutive period will increase the time according to the desired time-step. The period will start from 1, with a corresponding hour of the year starting from 0, and a timestamp plus all the requested properties in consecutive columns.

Output example (first rows):
```
period,hour,timestamp,air_temperature,dewpoint
1,0.0,2015-01-01T00:00:00,6.3,4.0
2,0.5,2015-01-01T00:15:00,6.5,4.35
3,1.0,2015-01-01T00:30:00,6.7,4.7
```

Period 1 corresponds to Jan-01, 00:00, and period 2 to Jan-01, 00:15.. and so on up to period 35040, (as the time-step was 15 minutes).

## Interpolation methodology

The script will create a list of required timepoints (in unix format) as requested by the user (with the time-step chosen), and those points will be compared to the times reported in the original Met Office file (under column "ob_time") in unix format.

Once a property has been passed, the script will remove the "NA" points and the missing points. And do a linear interpolation of each property in the required points. If the required point falls exactly on an input_file time point, then the property will be brought back unmodified. If the point doesn't exist in the input_file, the script will find the 2 closest existing points in the original dataset and do a linear interpolation of the property.

The interpolation process helps filling the required points which can happen if the time-steps are shorter than the original data or if the original data contains missing points.
