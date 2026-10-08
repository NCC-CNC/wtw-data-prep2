
import arcpy
import os
import pandas as pd

# Set environments
arcpy.env.overwriteOutput = True

# Get user params
input_poly = arcpy.GetParameterAsText(0)
input_raster_planning_units = arcpy.GetParameterAsText(1)
input_mode = arcpy.GetParameterAsText(2)
output_folder = arcpy.GetParameterAsText(4)

# Set environments
arcpy.env.snapRaster = input_raster_planning_units
arcpy.env.cellSize = input_raster_planning_units

# Set empty lists to populate
field_lst = []
output_lst = []

if input_mode == "csv":
  # Batch CSV: every row of dataprep.csv
  input_csv = arcpy.GetParameterAsText(3)
  arcpy.AddMessage(f"{os.path.basename(input_csv)} provided, using batch inputs.")
  batch_df = pd.read_csv(input_csv)
  field_lst.extend(batch_df['short_name'].tolist())
  output_lst.extend(batch_df['tif_output'].tolist())
else:
  # Batch table: rows of the fields parameter
  arcpy.AddMessage("Using batch table inputs.")
  input_fields = arcpy.GetParameter(5)
  for r in range(input_fields.rowCount):
    field_lst.append(input_fields.getValue(r, 0))
    output_lst.append(os.path.join(output_folder, input_fields.getValue(r, 1)))

# Process each list item
l = len(field_lst)
counter = 1
for field, output in zip(field_lst, output_lst):
  # .tif sets the output format in a folder, so add it if left off
  if not str(output).lower().endswith(".tif"):
    output = f"{output}.tif"
  arcpy.AddMessage(f"... Rasterizing {counter} of {l}: {field}")
  arcpy.conversion.PolygonToRaster(
    in_features = input_poly,
    value_field = field,
    out_rasterdataset = output,
    cell_assignment = "CELL_CENTER",
    cellsize = input_raster_planning_units
  )
  ## advance counter
  counter += 1
