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
input_vect = arcpy.GetParameter(4)

# Get the values of the Input vectors parameter
vect_list = []
for row in range(input_vect.rowCount):
  vect_list.append(input_vect.getTrueRow(row))

# Create wtw id
arcpy.AddField_management(input_poly, "WTWID", "LONG")
with arcpy.da.UpdateCursor(input_poly, ["WTWID"]) as cursor:
  for i, row in enumerate(cursor, start=1):
      row[0] = i
      cursor.updateRow(row)

# Process each list item
l = len(vect_list)
counter = 1
for vector, short_name, unit in (vect_list):
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
