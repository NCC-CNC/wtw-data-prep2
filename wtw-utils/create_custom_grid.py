import arcpy
import math
import os

# convert units to cell width and height needed for fishnet
def punits(cell_size, units):
  if units == "km":
    return math.sqrt(cell_size * 1000000)
  elif units == "ha":
    return math.sqrt(cell_size * 10000)
  elif units == "m":
    return cell_size

# Get user params
input_poly = arcpy.GetParameterAsText(0)
input_cell_size = float(arcpy.GetParameterAsText(1))
input_units = arcpy.GetParameterAsText(2)
nested = arcpy.GetParameterAsText(3)
output_folder = arcpy.GetParameterAsText(4)

# set output coordinate system
arcpy.env.overwriteOutput = True
arcpy.env.outputCoordinateSystem = arcpy.Describe(input_poly).spatialReference

# Get cell width and height
cell_width_height = punits(input_cell_size, input_units)

# Get input polygon extnet
extent = arcpy.Describe(input_poly).extent

# Get extent properties
xmin = extent.XMin - cell_width_height
ymin = extent.YMin - cell_width_height
xmax = extent.XMax + cell_width_height
ymax = extent.YMax + cell_width_height

# Create fishnet
arcpy.AddMessage(f"... Building fishnet grid: {int(input_cell_size)}{input_units}")
fishnet = arcpy.management.CreateFishnet(
    out_feature_class = "memory/fishnet",
    origin_coord = f"{xmin} {ymin}",
    y_axis_coord = f"{xmin} {ymin + 0.0001}",
    cell_width = cell_width_height,
    cell_height = cell_width_height,
    number_rows = 0,
    number_columns = 0,
    corner_coord = f"{xmax} {ymax}",
    labels = "NO_LABELS",
    template = "#",
    geometry_type = "POLYGON"
)

# Add a constant field
arcpy.management.AddField(fishnet, "Constant", "SHORT")
with arcpy.da.UpdateCursor(fishnet, ["Constant"]) as cursor:
  for row in cursor:
    row[0] = 1
    cursor.updateRow(row)

# Get parametes for selecting grid cells
if nested == "true":
  overlap_type = "WITHIN"
else:
  overlap_type = "INTERSECT"

# Select grid cells that intersect the input polygon
arcpy.AddMessage("... Building vector grid")
fishnet_lyr = arcpy.management.MakeFeatureLayer(fishnet, "fishnet_lyr")
fishnet_x = arcpy.management.SelectLayerByLocation(
  in_layer = fishnet_lyr,
  overlap_type = overlap_type,
  select_features = input_poly,
  selection_type="NEW_SELECTION"
)

# Output
vgrid_output = os.path.join(output_folder, f"vgrid_{int(input_cell_size)}{input_units}.shp")
rgrid_output = os.path.join(output_folder, f"rgrid_{int(input_cell_size)}{input_units}.tif")

# Export selection
arcpy.management.CopyFeatures(
  in_features = fishnet_x,
  out_feature_class = vgrid_output
)

# Create raster grid
arcpy.AddMessage("... Building raster grid")
arcpy.conversion.PolygonToRaster(
  in_features = vgrid_output,
  value_field = "Constant",
  out_rasterdataset = rgrid_output,
  cell_assignment = "CELL_CENTER",
  cellsize = cell_width_height
)
