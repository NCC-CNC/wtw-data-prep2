import math
import os
import sys
import arcpy
from osgeo import gdal

# Use exactextract from the active env if installed, otherwise fall back to the
# vendored copy (unpacked wheel, built for one Python version, see README)
vendor_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vendor")
try:
  import exactextract
except ImportError:
  if vendor_dir not in sys.path:
    sys.path.append(vendor_dir)
  try:
    import exactextract
  except ImportError as e:
    py = f"{sys.version_info.major}.{sys.version_info.minor}"
    msg = (f"Could not load the bundled exactextract for Python {py}. "
           "ArcGIS Pro may have been upgraded: replace wtw-utils/vendor "
           f"with the exactextract wheel for Python {py} (see README).")
    arcpy.AddError(msg)
    raise ImportError(msg) from e
from exactextract import exact_extract
from exactextract.feature import JSONFeatureSource
is_bundled = os.path.normcase(exactextract.__file__).startswith(os.path.normcase(vendor_dir))
source = "bundled" if is_bundled else "environment"
exactextract_info = f"exactextract {exactextract.__version__} ({source})"

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

  # Raster CRS, used to project polygons on read
  sr = arcpy.Describe(path_to_raster).spatialReference
  wkt = gdal.Open(path_to_raster).GetProjection()
  features = JSONFeatureSource(read_polygons(path_to_poly, sr), srs_wkt = wkt)

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
