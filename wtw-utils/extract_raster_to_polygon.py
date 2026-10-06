import arcpy
import sys
import os
import pandas as pd
script_folder = os.path.dirname(os.path.abspath(__file__))
sys.path.append(script_folder)
import fct_extract_raster as er
import importlib
importlib.reload(er)
arcpy.AddMessage(f"Using {er.exactextract_info}")

# Allow overwrite
arcpy.env.overwriteOutput = True

# Get user params
path_to_poly = arcpy.GetParameterAsText(0)
path_to_raster = arcpy.GetParameterAsText(1)
stat = arcpy.GetParameterAsText(2)
cell_value = arcpy.GetParameterAsText(3)
col_name = arcpy.GetParameterAsText(4)
csv = arcpy.GetParameterAsText(5)

# Build input table
if csv:
  csv_file_name = os.path.basename(csv)
  arcpy.AddMessage(f"Accessing data in: {csv_file_name}")
  input_df = pd.read_csv(csv)
  input_df = input_df[input_df["datatype"] == "raster"]
else:
  # cell value must be provided if the statistic is area
  if stat == "area" and not cell_value:
    arcpy.AddError("Please provide a cell value for area stat.")
    raise ValueError("Cell value is required for area stat.")
  # Get the full path (Raster Layer or dataset)
  path_to_raster = arcpy.Describe(path_to_raster).catalogPath
  input_df = pd.DataFrame([{
    "conversion_ready_input": path_to_raster,
    "short_name": col_name,
    "stat": stat,
    "cell_value": cell_value or None
  }])

# If user submited a feature class, get the full path
if arcpy.Describe(path_to_poly).dataType == "FeatureLayer":
  path_to_poly = arcpy.Describe(path_to_poly).catalogPath
# get polygon file name
poly_file_name = os.path.basename(path_to_poly)

# Create wtw id
arcpy.AddField_management(path_to_poly, "WTWID", "LONG")
with arcpy.da.UpdateCursor(path_to_poly, ["WTWID"]) as cursor:
  for i, row in enumerate(cursor, start=1):
      row[0] = i
      cursor.updateRow(row)

# --- EXTRACTION LOOP ---
extracts = {} # field -> {WTWID: value}
for row in input_df.itertuples():
  file_name = os.path.basename(row.conversion_ready_input)
  cell_value = None if pd.isna(row.cell_value) else float(row.cell_value)
  arcpy.AddMessage(f"Extracting {file_name}: {row.stat}")
  extracts[row.short_name] = er.extract_raster(
    path_to_poly, row.conversion_ready_input, row.stat, cell_value
  )

# Add new fields as DOUBLE
col_name = list(extracts)
for field in col_name:
  arcpy.AddField_management(path_to_poly, field, "DOUBLE")

# Update polygon with extracted values
arcpy.AddMessage(f"Joining extractions to {poly_file_name}")
arcpy.AddMessage(f"Fields: {col_name}")
fields = ["WTWID"] + col_name
with arcpy.da.UpdateCursor(path_to_poly, fields) as cursor:
    for row in cursor:
        wtwid = row[0]
        for i, field in enumerate(col_name, start=1):
            row[i] = extracts[field].get(wtwid, 0)
        cursor.updateRow(row)
