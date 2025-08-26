# Where To Work Data Prep (wtw-data-prep2)
R pipeline for generating WTW projects, supported by a custom ArcGIS toolbox
for including regional data.

**Refer to the Where To Work Data Prep Manual for complete instructions.**

#### Hardware Dependencies
-	Windows 11.
- It is recommended to have at least 16 GB of RAM.
- It is recommended to have adequate local storage. Required space varies based on the number of active projects, the size of each WTW project, and the number of spatial layers included.

#### Software Dependencies
- **R version 4.4.1**:   
The R version currently used to run the WTW web application. 
It is recommended to install R directly on the C: drive.
- **RStudio**:   
Recommended IDE for running and editing R scripts.
- **Set the System PATH for Rscript.exe**:   
Add the R bin folder (where Rscript.exe is located) to the system PATH so that Rscript can be called directly from the ArcGIS script tools.
- **Rtools 4.4**:  
Required for building and installing R packages from source. It is recommended to install Rtools directly on the C: drive.
- **ArcGIS Pro >= 3.5**:   
Used for displaying layers and running custom ArcGIS script tools.
- **Git**:   
For version control and managing code repositories.
- **Personal GitHub account**:   
Needed to clone and sync IT managed GitHub repos locally.

#### Data Dependencies
- NAT_DATA bundle (S:\CONS_TECH\PRZ\DATA\NAT_DATA\__VERSIONS__) 
- Conversion-ready regional vector/raster layers
- Area of Interest (AOI) shapefile polygon
