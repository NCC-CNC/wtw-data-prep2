import arcpy
import importlib
import fct_conversion_props as cp
importlib.reload(cp)

def vector_pull(vector, polygon, col_name, metric):
  
  #
  
  # set environments
  sr = arcpy.Describe(polygon).spatialReference
  arcpy.env.outputCoordinateSystem = sr  
  
  # Retrieve measure and unit conversion
  conversion_props = cp.conversion_props(vector = vector, metric = metric)
  measure = conversion_props[0]
  unit_conversion = conversion_props[1]
  
  # Intersection
  arcpy.AddMessage("... intersecting")
  vector_x = arcpy.analysis.Intersect([vector, polygon], "C:/Github/wtw-data-prep2/tests/data/vector.gdb/int")
  
  # Build dictionary
  arcpy.AddMessage(measure)
  dim = {}
  with arcpy.da.SearchCursor(vector_x, ["WTWID", measure]) as cursor:
      for row in cursor:
          oid, _measure = row[0], row[1]
          if oid not in dim:
              dim[oid] = round(_measure / unit_conversion, 4) 
          else:
              dim[oid] += round(_measure / unit_conversion, 4)
  
  # Join dictionary to polygon 
  arcpy.management.AddField(polygon, col_name, "DOUBLE")
  with arcpy.da.UpdateCursor(polygon, ["WTWID", col_name]) as cursor:
      for row in cursor:
          oid = row[0]
          if oid in dim:
              row[1] = dim[oid]
          else:
              row[1] = 0
          cursor.updateRow(row)  
