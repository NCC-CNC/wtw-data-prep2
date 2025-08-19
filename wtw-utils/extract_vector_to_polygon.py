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
input_vect = arcpy.GetParameterAsText(1)
input_unit = arcpy.GetParameterAsText(2)
input_colname = arcpy.GetParameterAsText(3)
input_csv = arcpy.GetParameterAsText(4)

# Set emtpy lists to populate
vector_lst = []
short_name_lst = []
unit_lst = []

# Shape csv input paramters    
if input_csv:
  csv_file_name = os.path.basename(input_csv)
  arcpy.AddMessage(f"{csv_file_name} provided, using batch inputs.")
  batch_df = pd.read_csv(input_csv)
  batch_df = batch_df[batch_df["datatype"] == "vector"] # needed to filter
  vector_lst.extend(batch_df['conversion_ready_input'].tolist())
  unit_lst.extend(batch_df['unit'].tolist())
  short_name_lst.extend(batch_df['short_name'].tolist())
else:
  arcpy.AddMessage("No dataprep.csv provided, using single vector input.")
  # If no csv provided, use single vector input
  vector_lst.append(input_vect)
  short_name_lst.append(input_colname)
  unit_lst.append(input_unit)

# Create wtw id
arcpy.AddField_management(input_poly, "WTWID", "LONG")
with arcpy.da.UpdateCursor(input_poly, ["WTWID"]) as cursor:
  for i, row in enumerate(cursor, start=1):
      row[0] = i
      cursor.updateRow(row)

# Process each list item
l = len(vector_lst)
counter = 1
for vector, short_name, unit in zip(vector_lst, short_name_lst, unit_lst):
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
  
