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
input_multi_params = arcpy.GetParameterAsText(1)
input_batch = arcpy.GetParameterAsText(2)

# Set emtpy lists to populate
vector_lst = []
short_name_lst = []
unit_lst = []


# Shape tool input vector parameters
if input_multi_params:
  multi_params = input_multi_params.split(";")
  for x in multi_params:
      vector, short_name, unit = x.split(" ")
      vector_lst.append(vector)
      short_name_lst.append(short_name)
      unit_lst.append(unit)

# Shape batch input paramters    
if input_batch:
  batch_df = pd.read_csv(input_batch)
  vector_lst.extend(batch_df['conversion_ready_input'].tolist())
  short_name_lst.extend(batch_df['short_name'].tolist())
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
  
