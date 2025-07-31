
import arcpy
import os
import pandas as pd

# Set environments
arcpy.env.overwriteOutput = True

# Get user params
input_poly = arcpy.GetParameterAsText(0)
input_raster_planning_units = arcpy.GetParameterAsText(1)
input_multi_params = arcpy.GetParameterAsText(2)
input_batch = arcpy.GetParameterAsText(3)

# Set environments
arcpy.env.snapRaster = input_raster_planning_units
arcpy.env.cellSize = input_raster_planning_units

# Set emtpy lists to populate
field_lst = []
output_lst = []

# Shape tool input parameters
if input_multi_params:
  multi_params = input_multi_params.split(";")
  for x in multi_params:
      field, output_folder, tif_name = x.split(" ")
      field_lst.append(field)
      output_lst.append(os.path.join(output_folder, tif_name))

# Shape batch input paramters
if input_batch:
  batch_df = pd.read_csv(input_batch)
  field_lst.extend(batch_df['short_name'].tolist())
  output_lst.extend(batch_df['tif_output'].tolist())

# Process each list item
l = len(field_lst)
counter = 1
for field, output in zip(field_lst, output_lst):
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
