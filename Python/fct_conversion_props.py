import arcpy

def conversion_props(vector, metric):
  # get geometry
  geometry_type = arcpy.Describe(vector).shapeType
  arcpy.AddMessage(f"Geometry type: {geometry_type}")
  # return geometry type and unit conversion properties
  if geometry_type == "Polygon" and metric == "m2":
    return ["SHAPE@AREA", 1]
  elif geometry_type == "Polygon" and metric == "ha":
    return ["SHAPE@AREA", 10000]
  elif geometry_type == "Polygon" and metric == "km2":
    return ["SHAPE@AREA", 1000000]
  elif geometry_type == "Polyline" and metric == "m":
    return ["SHAPE@LENGTH", 1]
  elif geometry_type == "Polyline" and metric == "km":
    return ["SHAPE@LENGTH", 1000]
  elif geometry_type == "Point" or geometry_type == "MultiPoint" and metric == "count":
    return ["SHAPE@XY", 1]
  else:
    raise ValueError(f"Error: unsupported, {geometry_type} / {metric}")
