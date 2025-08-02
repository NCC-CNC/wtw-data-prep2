import arcpy
import importlib
import fct_conversion_props as cp
importlib.reload(cp)

def vector_pull(vector, polygon, col_name, unit):
  
  # delete WTWID on vector
  arcpy.DeleteField_management(vector, "WTWID")
  
  # set environments
  sr = arcpy.Describe(polygon).spatialReference
  arcpy.env.outputCoordinateSystem = sr  
  
  # Retrieve measure and unit conversion
  conversion_props = cp.conversion_props(vector = vector, unit = unit)
  measure = conversion_props[0]
  unit_conversion = conversion_props[1]
  
  # Intersection
  arcpy.AddMessage("...                    intersecting")
  vector_x = arcpy.analysis.Intersect([vector, polygon], "memory/i")
  
  # Build dictionary
  dim = {}
  with arcpy.da.SearchCursor(vector_x, ["WTWID", measure]) as cursor:
      for row in cursor:
          wtwid, _measure, digits = row[0], row[1], 4
          if isinstance(_measure, tuple):
              _measure = 1 # counts points
              digits = 1
          if wtwid not in dim:
              dim[wtwid] = round(_measure / unit_conversion, digits) 
          else:
              dim[wtwid] += round(_measure / unit_conversion, digits)
  
  # Join dictionary to polygon 
  arcpy.management.AddField(polygon, col_name, "DOUBLE")
  with arcpy.da.UpdateCursor(polygon, ["WTWID", col_name]) as cursor:
      for row in cursor:
          wtwid = row[0]
          if wtwid in dim:
              row[1] = dim[wtwid]
          else:
              row[1] = 0
          cursor.updateRow(row)  
