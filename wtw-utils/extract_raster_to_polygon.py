import arcpy
import os
import subprocess

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
    
# Join feilds to polygon
arcpy.AddMessage("... Joining extractions to polygon")
arcpy.management.JoinField(
  in_data=path_to_poly,
  in_field="WTWID",
  join_table= os.path.join(path_to_temp, "r_extract.csv"),
  join_field="WTWID",
  fields=col_name
)
