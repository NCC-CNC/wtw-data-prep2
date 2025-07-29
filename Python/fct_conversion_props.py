import arcpy

def conversion_props(vector, unit):
  # get geometry
  geometry_type = arcpy.Describe(vector).shapeType
  # return geometry type and unit conversion properties
  if geometry_type == "Polygon" and unit == "m2":
    return ["SHAPE@AREA", 1]
  elif geometry_type == "Polygon" and unit == "ha":
    return ["SHAPE@AREA", 10000]
  elif geometry_type == "Polygon" and unit == "km2":
    return ["SHAPE@AREA", 1000000]
  elif geometry_type == "Polyline" and unit == "m":
    return ["SHAPE@LENGTH", 1]
  elif geometry_type == "Polyline" and unit == "km":
    return ["SHAPE@LENGTH", 1000]
  elif geometry_type == "Point" or geometry_type == "MultiPoint" and unit == "count":
    return ["SHAPE@XY", 1]
  else:
    raise ValueError(f"Error: unsupported, {geometry_type} / {unit}")
