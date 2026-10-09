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
- **ArcGIS Pro 3.7.1 (Python 3.13)**:   
Used for displaying layers and running custom ArcGIS script tools. The toolbox is
tested with Pro 3.7.1 and runs in Pro's default `arcgispro-py3` environment with no
extra setup. Other Pro versions that use Python 3.13 are expected to work; see
[ArcGIS toolbox Python environment](#arcgis-toolbox-python-environment).
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
package. A copy is bundled in `wtw-utils/vendor` (exactextract 0.3.0, built for
Python 3.13), so the tool runs in Pro's default `arcgispro-py3` environment with
no setup. The tool's first message shows which copy it is using, e.g.
`Using exactextract 0.3.0 (bundled)`.

**Optional: using a local environment.** If exactextract is installed in Pro's
active environment, the tool uses that copy instead of the bundled one, and reports
`(environment)`. This is not needed for normal use. Use it to try a different
exactextract version, or to keep working if a Pro upgrade changes the Python
version before the bundled copy is updated. From the ArcGIS Pro Python Command
Prompt:

```
conda create --clone arcgispro-py3 --name wtw-dev
activate wtw-dev
pip install exactextract --no-deps
```

Then in Pro go to Project > Package Manager > Active Environment and set `wtw-dev`
as the active environment, and restart Pro. Use `pip install --no-deps` rather than
`conda install`, which can replace Pro's numpy or GDAL and break arcpy.

**Updating the bundled copy.** The bundled copy only works with the Python version
it was built for. If Pro moves to a new Python version, the tool reports that it
could not load the bundled exactextract. To update it, run the following from the
repo folder in the ArcGIS Pro Python Command Prompt (replacing `3.13` with Pro's
Python version):

```
rmdir /s /q wtw-utils\vendor
pip install exactextract --target wtw-utils\vendor --only-binary=:all: --python-version 3.13 --platform win_amd64 --no-deps
```

This downloads the exactextract build for that Python version and unpacks it into
`wtw-utils/vendor`, without changing any Python environment.
