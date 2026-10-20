import math
import os
import site
import sys
import threading
import arcpy
from osgeo import gdal

# Pro's embedded Python skips the user site-packages (pip install --user), so
# add it, after the environment's own packages so Pro's copies always win
user_site = site.getusersitepackages()
if os.path.isdir(user_site) and user_site not in sys.path:
  site.addsitedir(user_site)

# exactextract must be installed in Pro's active Python environment or the user
# site-packages (see README)
try:
  import exactextract
except ImportError as e:
  py = f"{sys.version_info.major}.{sys.version_info.minor}"
  msg = (f"Could not load exactextract in the active ArcGIS Pro environment "
         f"({sys.prefix}, Python {py}): {e}. Set up a Python environment with "
         "exactextract installed and make it Pro's active environment (see "
         "README, ArcGIS toolbox Python environment).")
  arcpy.AddError(msg)
  raise ImportError(msg) from e
from exactextract import exact_extract
from exactextract.feature import JSONFeatureSource
exactextract_info = f"exactextract {exactextract.__version__} ({exactextract.__file__})"

gdal.UseExceptions()

# Tool stat names that differ from exactextract op names
STAT_OPS = {"var": "variance"}

def read_polygons(path_to_poly, sr):
  # Read polygons as GeoJSON-like features, projected to the raster CRS
  features = []
  with arcpy.da.SearchCursor(path_to_poly, ["WTWID", "SHAPE@"], spatial_reference = sr) as cursor:
      for wtwid, shape in cursor:
          if shape is None:
              continue # skip null geometries
          features.append({
              "type": "Feature",
              "properties": {"WTWID": wtwid},
              "geometry": shape.__geo_interface__
          })
  return features

def extract_raster(path_to_poly, path_to_raster, stat, cell_value = None):
  # Run the extraction on a thread started by Python. exactextract (and GDAL's
  # bindings) call back into Python from native code, which needs a thread
  # Python's GIL state API knows. ArcGIS Pro's geoprocessing threads aren't,
  # and repeated runs on them crashed Pro: "Fatal Python error: non-NULL old
  # thread state". Read the polygons with arcpy here, on the calling thread:
  # on older Pro versions a cursor opened on the worker thread kept its lock,
  # so adding the result fields failed (ERROR 000464: Cannot get exclusive
  # schema lock).
  sr = arcpy.Describe(path_to_raster).spatialReference
  polygons = read_polygons(path_to_poly, sr)
  outcome = {}
  def run():
    try:
      outcome["vals"] = _extract_raster(polygons, sr, path_to_raster, stat, cell_value)
    except BaseException as e:
      outcome["error"] = e
  thread = threading.Thread(target = run, name = "wtw-extract-raster")
  thread.start()
  thread.join()
  if "error" in outcome:
    raise outcome["error"]
  return outcome["vals"]

def _extract_raster(polygons, sr, path_to_raster, stat, cell_value = None):

  # Polygons were read projected to the raster CRS (sr)
  wkt = gdal.Open(path_to_raster).GetProjection()
  features = JSONFeatureSource(polygons, srs_wkt = wkt)

  # -- AREA ---
  if stat == "area":
    if cell_value is None:
      raise ValueError(f"Cell value is required for area stat: {path_to_raster}")
    # area-weighted coverage: count = covered area (m2), frac = share per unique value
    weight = "area_spherical_m2" if sr.type == "Geographic" else "area_cartesian"
    ops = [f"{op}(coverage_weight={weight})" for op in ["unique", "frac", "count"]]
    results = exact_extract(path_to_raster, features, ops, include_cols = ["WTWID"])

    vals = {}
    for f in results:
      p = f["properties"]
      area = sum(fr for v, fr in zip(p["unique"], p["frac"]) if v == cell_value) * p["count"]
      vals[p["WTWID"]] = round(area / 10000, 2) # Convert m2 to hectares
    return vals

  # -- ALL OTHER STATS ---
  op = STAT_OPS.get(stat, stat)
  # read as Float64, otherwise exactextract returns stats (e.g. median) in the
  # raster's own type and truncates integer rasters, unlike exactextractr
  vrt = "/vsimem/extract_raster.vrt"
  gdal.Translate(vrt, path_to_raster, format = "VRT", outputType = gdal.GDT_Float64)
  try:
    results = exact_extract(vrt, features, [op], include_cols = ["WTWID"])
  finally:
    gdal.Unlink(vrt)

  vals = {}
  for f in results:
    p = f["properties"]
    val = p[op]
    if val is None or math.isnan(val):
      val = 0 # replace NA with 0
    vals[p["WTWID"]] = round(float(val), 4)
  return vals
