import arcpy
import sys
import os
script_folder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(script_folder)
import fct_vector_pull as vp
import importlib
importlib.reload(vp)

# Get user params
input_poly = arcpy.GetParameterAsText(0)
input_multi_vector_params = arcpy.GetParameterAsText(1)
arcpy.AddMessage(input_multi_vector_params)
arcpy.AddMessage(type(input_multi_vector_params))
input_batch = arcpy.GetParameterAsText(2)

# Set environments
arcpy.env.overwriteOutput = True

# Shape and transfrom input data
# Set emtpy lists to populate
vector_lst = []
name_lst = []
metric_lst = []

# Split vector features
multi_vector_params = input_multi_vector_params.split(";")

# Extract vector parameters
for x in multi_vector_params:
    vector, name, metric = x.split(" ")
    vector_lst.append(vector)
    name_lst.append(name)
    metric_lst.append(metric)

# Create wtw id
arcpy.AddField_management(input_poly, "WTWID", "LONG")
with arcpy.da.UpdateCursor(input_poly, ["WTWID"]) as cursor:
  for i, row in enumerate(cursor, start=1):
      row[0] = i
      cursor.updateRow(row)

# Process each list item
for vector, name, metric in zip(vector_lst, name_lst, metric_lst):
  file_name = arcpy.Describe(vector).name
  arcpy.AddMessage(f"... Processing: {file_name}")

  # Extract vector to polygon
  vp.vector_pull(
    vector = vector,
    polygon = input_poly,
    col_name = name,
    metric = metric
  )
  



