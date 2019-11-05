import os, arcpy

arcpy.env.overwriteOutput = True
arcpy.env.outputCoordinateSystem = arcpy.SpatialReference(32717)

# Folders
BASE_DIR = r'E:\2019\UNI'
RASTER_DIR = os.path.join(BASE_DIR, "data", "raster")
SHP_DIR = os.path.join(BASE_DIR, "data", "shp")

SCRATCH = arcpy.env.scratchGDB

# Existing files
DEM = os.path.join(RASTER_DIR, "dem_area_17s.tif")
FLOW_ACC_MIN = os.path.join(RASTER_DIR, "facc_08.tif")

# New files
PUNTOS = os.path.join(SHP_DIR, "gpt_second_v.shp")
INTERSECT = os.path.join(SHP_DIR, "gpt_puntos_intersect.shp")

ID_EVAL = "ID_EVAL"

cursor = arcpy.da.InsertCursor(INTERSECT, ["SHAPE@XY", ID_EVAL, "DEM", "Q"])

puntos_multipart = arcpy.MultipartToSinglepart_management(PUNTOS, "in_memory\\puntos_multipart")

list_ideval = [x[0] for x in arcpy.da.SearchCursor(puntos_multipart, [ID_EVAL])]

for ideval in list_ideval:
    mfl = arcpy.MakeFeatureLayer_management(puntos_multipart, "punto_eval", "{} = '{}'".format(ID_EVAL, ideval))
    points = arcpy.CopyFeatures_management(mfl, os.path.join(SCRATCH, "gpt_points"))
    list_raster = [[DEM, "DEM"], [FLOW_ACC_MIN, "Q"]]
    arcpy.gp.ExtractMultiValuesToPoints_sa(points, list_raster)

    inters = [x for x in arcpy.da.SearchCursor(points, ["SHAPE@XY", "DEM", "Q"])]

    for i in inters:
        cursor.insertRow([i[0], ideval, i[1], i[2]])
    print(ideval)

del cursor
