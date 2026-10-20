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
- **Rtools 4.4**:  
Required for building and installing R packages from source. It is recommended to install Rtools directly on the C: drive.
- **ArcGIS Pro 3.x**:   
Used for displaying layers and running custom ArcGIS script tools. The toolbox is
tested with Pro 3.7.1. It needs a Python environment with exactextract installed;
see [ArcGIS toolbox Python environment](#arcgis-toolbox-python-environment).
- **Git**:   
For version control and managing code repositories.
- **Personal GitHub account**:   
Needed to clone and sync IT managed GitHub repos locally.

#### Data Dependencies
- NAT_DATA bundle (S:\CONS_TECH\PRZ\DATA\NAT_DATA\__VERSIONS__) 
- Conversion-ready regional vector/raster layers
- Area of Interest (AOI) shapefile polygon

#### ArcGIS toolbox Python environment
The toolbox uses only Python and arcpy; R is not required. `01b Extract Raster to
Polygon` uses the [exactextract](https://pypi.org/project/exactextract/) Python
package, which is not included in Pro's default `arcgispro-py3` environment (and
that environment cannot be modified). Each user needs to set up a cloned
environment with exactextract installed, once per Pro installation:

1. Close ArcGIS Pro.
2. From the Start menu, open **ArcGIS > Python Command Prompt** and run:

   ```
   conda create --clone arcgispro-py3 --name wtw-data-prep
   activate wtw-data-prep
   pip install exactextract --no-deps
   ```

   Cloning can take several minutes. pip installs the exactextract build that
   matches your Pro's Python version.
3. Open ArcGIS Pro, go to **Project > Package Manager**, set **Active Environment**
   to `wtw-data-prep`, and restart Pro.

The tool's first message shows the exactextract version and location it is using,
e.g. `Using exactextract 0.3.0 (C:\Users\...\envs\wtw-data-prep\...)`. If exactextract cannot
be loaded, the tool reports the active environment and Python version.

Use `pip install --no-deps` rather than `conda install`, which can replace Pro's
numpy or GDAL and break arcpy.

**After upgrading ArcGIS Pro**, the cloned environment still contains the old
Pro's packages and may no longer work. Delete it and repeat the steps above:

```
conda env remove --name wtw-data-prep
```
