import arcpy
import os
import importlib.util
import pandas as pd
# Load the helper from this folder by path: Pro shares one Python between
# toolboxes, so importing it by name could pick up another toolbox's copy
script_folder = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location(
  "fct_extract_raster", os.path.join(script_folder, "fct_extract_raster.py"))
er = importlib.util.module_from_spec(spec)
spec.loader.exec_module(er)
arcpy.AddMessage(f"Using {er.exactextract_info}")

# Allow overwrite
arcpy.env.overwriteOutput = True

# Get user params
path_to_poly = arcpy.GetParameterAsText(0)
input_mode = arcpy.GetParameterAsText(1)

# Build input table
if input_mode == "csv":
  # Batch CSV: raster rows of dataprep.csv
  input_csv = arcpy.GetParameterAsText(6)
  arcpy.AddMessage(f"Accessing data in: {os.path.basename(input_csv)}")
  input_df = pd.read_csv(input_csv)
  input_df = input_df[input_df["datatype"] == "raster"]
elif input_mode == "table":
  # Batch table: rows of the Input rasters parameter
  arcpy.AddMessage("Using batch table inputs.")
  input_rasters = arcpy.GetParameter(9)
  rows = []
  for r in range(input_rasters.rowCount):
    raster, col_name, stat = input_rasters.getTrueRow(r)[:3]
    # read cell value as text: a blank cell would otherwise come back as 0
    cell_value = input_rasters.getValue(r, 3)
    rows.append({
      "conversion_ready_input": arcpy.Describe(raster).catalogPath,
      "short_name": col_name,
      "stat": stat,
      "cell_value": None if cell_value in ("", "#") else float(cell_value)
    })
  input_df = pd.DataFrame(rows)
else:
  # Single layer
  path_to_raster = arcpy.GetParameterAsText(2)
  stat = arcpy.GetParameterAsText(3)
  cell_value = arcpy.GetParameterAsText(4)
  col_name = arcpy.GetParameterAsText(5)
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

# Edit the polygon through the input as given (as 01a does), so a layer in the
# map sees its new fields. Read the polygons from the dataset by its full path.
input_poly = path_to_poly
if arcpy.Describe(path_to_poly).dataType == "FeatureLayer":
  path_to_poly = arcpy.Describe(path_to_poly).catalogPath
# get polygon file name
poly_file_name = os.path.basename(path_to_poly)

# Create wtw id
arcpy.AddField_management(input_poly, "WTWID", "LONG")
with arcpy.da.UpdateCursor(input_poly, ["WTWID"]) as cursor:
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
  arcpy.AddField_management(input_poly, field, "DOUBLE")

# Update polygon with extracted values
arcpy.AddMessage(f"Joining extractions to {poly_file_name}")
arcpy.AddMessage(f"Fields: {col_name}")
fields = ["WTWID"] + col_name
with arcpy.da.UpdateCursor(input_poly, fields) as cursor:
    for row in cursor:
        wtwid = row[0]
        for i, field in enumerate(col_name, start=1):
            row[i] = extracts[field].get(wtwid, 0)
        cursor.updateRow(row)
