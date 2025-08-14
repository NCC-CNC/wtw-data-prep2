import arcpy
import os
import subprocess
import pandas as pd

# Allow overwrite
arcpy.env.overwriteOutput = True

# Get user params
path_to_poly = arcpy.GetParameterAsText(0)
path_to_raster = arcpy.GetParameterAsText(1)
stat = arcpy.GetParameterAsText(2)          
col_name = arcpy.GetParameterAsText(3)       
path_to_temp = arcpy.GetParameterAsText(4)
csv = arcpy.GetParameterAsText(5)           

# If user submited a feature class, get the full path
if (arcpy.Describe(path_to_poly).dataType == "FeatureLayer"):
  path_to_poly = arcpy.Describe(path_to_poly).catalogPath

# Create wtw id
arcpy.AddField_management(path_to_poly, "WTWID", "LONG")
with arcpy.da.UpdateCursor(path_to_poly, ["WTWID"]) as cursor:
  for i, row in enumerate(cursor, start=1):
      row[0] = i
      cursor.updateRow(row)

# Path to R script
script_folder = os.path.dirname(os.path.abspath(__file__))
r_script = os.path.join(script_folder, "run_extract_raster.R")

# Build command
cmd = [
    "Rscript",
    r_script,
    path_to_poly,
    path_to_raster,
    stat,
    col_name,
    path_to_temp,
]
# append csv path if provided
if csv:
    cmd.append(csv)

# Run R script
arcpy.AddMessage("... Running R script")
result = subprocess.run(cmd, capture_output=True, text=True)

# Log R output/errors
arcpy.AddMessage("R Output:\n" + result.stdout)
if result.stderr:
    arcpy.AddWarning("R:\n" + result.stderr)

# Exit if R failed
if result.returncode != 0:
    arcpy.AddError(f"R script failed with code {result.returncode}")

# Get column names from csv (if provided)
if csv:
  batch_csv = pd.read_csv(csv)
  col_name = batch_csv["short_name"].tolist()

# Convert one-off col name to list  
if isinstance(col_name, str):
    col_name = [col_name]
  
# Delete existing fields if they exists
existing_fields = [f.name for f in arcpy.ListFields(path_to_poly)]
for field in col_name:
    if field in existing_fields:
        arcpy.DeleteField_management(path_to_poly, field)
        arcpy.AddMessage(f"... Deleting existing field: {field}")
    # Add field as DOUBLE        
    arcpy.AddField_management(path_to_poly, field, "DOUBLE")
    
# Read-in r_extract.csv
df = pd.read_csv(os.path.join(path_to_temp, "r_extract.csv"))
# Create dictionary: WTWID -> {field: value, ...}
r_dict = df.set_index("WTWID")[col_name].to_dict(orient="index")
# Get list of fields
fields = ["WTWID"] + col_name

# Update polygon with values from r_extract.csv, dicitonary
arcpy.AddMessage("... Joining extractions to polygon")
with arcpy.da.UpdateCursor(path_to_poly, fields) as cursor:
    for row in cursor:
        wtwid = row[0]
        if wtwid in r_dict:
            for i, field in enumerate(col_name, start=1):
                row[i] = r_dict[wtwid][field]  # assign numeric value
            cursor.updateRow(row)
  
