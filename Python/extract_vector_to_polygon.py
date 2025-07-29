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
input_multi_vector_params = arcpy.GetParameterAsText(1)
input_batch = arcpy.GetParameterAsText(2)

# Set emtpy lists to populate
vector_lst = []
name_lst = []
unit_lst = []

# Split vector features
multi_vector_params = input_multi_vector_params.split(";")

# Extract vector parameters
for x in multi_vector_params:
    vector, name, unit = x.split(" ")
    vector_lst.append(vector)
    name_lst.append(name)
    unit_lst.append(unit)
    
if input_batch:
  batch_df = pd.read_csv(input_batch)
  vector_lst.extend(batch_df['full_path'].tolist())
  name_lst.extend(batch_df['shp_name'].tolist())
  unit_lst.extend(batch_df['unit'].tolist())

# Create wtw id
arcpy.AddField_management(input_poly, "WTWID", "LONG")
with arcpy.da.UpdateCursor(input_poly, ["WTWID"]) as cursor:
  for i, row in enumerate(cursor, start=1):
      row[0] = i
      cursor.updateRow(row)

# Process each list item
l = len(vector_lst)
counter = 1
for vector, name, unit in zip(vector_lst, name_lst, unit_lst):
  file_name = arcpy.Describe(vector).name
  arcpy.AddMessage(f"... Processing {counter} of {l}: {file_name}")

  # Extract vector to polygon
  vp.vector_pull(
    vector = vector,
    polygon = input_poly,
    col_name = name,
    unit = unit
  )
  
  counter += 1
  



