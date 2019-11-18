import os, arcpy
import pandas as pd

arcpy.env.overwriteOutput = True
arcpy.env.outputCoordinateSystem = arcpy.SpatialReference(32717)

ID_EVAL = "ID_EVAL"
TIPO = "TIPO"

# Folders
BASE_DIR = r'E:\2019\UNI'
RASTER_DIR = os.path.join(BASE_DIR, "data", "raster")
SHP_DIR = os.path.join(BASE_DIR, "data", "shp")
XLS_DIR = os.path.join(BASE_DIR, "xlsx")
