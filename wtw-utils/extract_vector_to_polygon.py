import arcpy
import sys
import os
import pandas as pd
script_folder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(script_folder)
import fct_vector_pull as vp
import importlib
importlib.reload(vp)

# Set environments
arcpy.env.overwriteOutput = True

# Get user params
input_poly = arcpy.GetParameterAsText(0)
input_mode = arcpy.GetParameterAsText(1)

# List of [vector, short_name, unit] to process
vect_list = []

if input_mode == "csv":
  # Batch CSV: vector rows of dataprep.csv
  input_csv = arcpy.GetParameterAsText(5)
  arcpy.AddMessage(f"{os.path.basename(input_csv)} provided, using batch inputs.")
  batch_df = pd.read_csv(input_csv)
  batch_df = batch_df[batch_df["datatype"] == "vector"] # needed to filter
  vect_list = batch_df[["conversion_ready_input", "short_name", "unit"]].values.tolist()
elif input_mode == "table":
  # Batch table: rows of the Input vector features parameter
  arcpy.AddMessage("Using batch table inputs.")
  input_vect = arcpy.GetParameter(9)
  for row in range(input_vect.rowCount):
    vect_list.append(input_vect.getTrueRow(row))
else:
  # Single layer
  arcpy.AddMessage("Using single vector input.")
  vect_list.append([
    arcpy.GetParameterAsText(2),
    arcpy.GetParameterAsText(4),
    arcpy.GetParameterAsText(3)
  ])

# Create wtw id
arcpy.AddField_management(input_poly, "WTWID", "LONG")
with arcpy.da.UpdateCursor(input_poly, ["WTWID"]) as cursor:
  for i, row in enumerate(cursor, start=1):
      row[0] = i
      cursor.updateRow(row)

# Process each list item
l = len(vect_list)
counter = 1
for vector, short_name, unit in vect_list:
  file_name = arcpy.Describe(vector).name
  arcpy.AddMessage(f"... Processing {counter} of {l}: {file_name}")

  ## extract vector to polygon
  vp.vector_pull(
    vector = vector,
    polygon = input_poly,
    col_name = short_name,
    unit = unit
  )
  ## advance counter
  counter += 1
