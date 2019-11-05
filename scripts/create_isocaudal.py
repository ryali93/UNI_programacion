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
LISTA_Q = [[os.path.join(RASTER_DIR, "facc_" + str(x).zfill(2)+".tif"), "Q_" + str(x).zfill(2)] for x in range(1, 13)]

RED_HIDRICA = os.path.join(SHP_DIR, "red_hidrica_test_1.shp")
CURVAS = os.path.join(SHP_DIR, "gpl_curvas.shp")

# New files
PUNTOS = os.path.join(SHP_DIR, "gpt_second_v.shp")
INTERSECT = os.path.join(SHP_DIR, "gpt_puntos_intersect.shp")

ID_EVAL = "ID_EVAL"

def create_points_intersect(river, curvas, buff):
    area_buffer = arcpy.Buffer_analysis(river, "in_memory\\buffer", '{} Meters'.format(buff), 'FULL', 'ROUND', 'ALL', '#', 'PLANAR')
    interseccion = arcpy.Intersect_analysis([river, curvas], "in_memory\\interseccion", 'ALL', '#', 'POINT')
    arcpy.AddField_management(interseccion, ID_EVAL, "TEXT", "#", "#", 20)
    n = 0
    with arcpy.da.UpdateCursor(interseccion, [ID_EVAL]) as cursor:
        for x in cursor:
            n += 1
            x[0] = "ID" + str(n).zfill(4)
            cursor.updateRow(x)

    fields = 'FID_red_hi;arcid;grid_code;from_node;to_node;FID_gpl_cu;OBJECTID;Id;Shape_Leng'
    arcpy.DeleteField_management(interseccion, fields)

    return area_buffer, interseccion

# def add_q_fields(layer):
#     lista_q_fields = [f[1] for f in LISTA_Q]
#     name_fields = [x.name for x in arcpy.ListFields(layer)]
#     for field in lista_q_fields:
#         if field not in name_fields:
#             arcpy.AddField_management(layer, field, "DOUBLE")

def extract_q_values(interseccion):
    # lista_q_fields = [f[1] for f in LISTA_Q]
    # add_q_fields(interseccion)
    # cursor = arcpy.da.InsertCursor(interseccion, [ID_EVAL, "SHAPE@XY", "DEM"] + lista_q_fields)
    # puntos_multipart = arcpy.MultipartToSinglepart_management(interseccion, "in_memory\\puntos_multipart")
    puntos_multipart = arcpy.MultipartToSinglepart_management(interseccion, INTERSECT)

    list_raster = [[DEM, "Z_TOMA"]] + LISTA_Q
    # print(os.path.join(SCRATCH, "gpt_points"))
    print(list_raster)
    arcpy.gp.ExtractMultiValuesToPoints_sa(puntos_multipart, list_raster)

    # list_ideval = [x[0] for x in arcpy.da.SearchCursor(puntos_multipart, [ID_EVAL])]

    # for ideval in list_ideval:
    #     mfl = arcpy.MakeFeatureLayer_management(puntos_multipart, "punto_eval", "{} = '{}'".format(ID_EVAL, ideval))
    #     points = arcpy.CopyFeatures_management(mfl, os.path.join(SCRATCH, "gpt_points"))

    #     list_raster = [[DEM, "Z_TOMA"]] + LISTA_Q
    #     print(os.path.join(SCRATCH, "gpt_points"))
    #     print(list_raster)

    #     arcpy.gp.ExtractMultiValuesToPoints_sa(points, list_raster)
    #     inters = [x for x in arcpy.da.SearchCursor(points, ["SHAPE@XY", "DEM"] + lista_q_fields)]
    #     for i in inters:
    #         cursor.insertRow([ideval] + [inters[m] for m in range(len(inters))])
    #     print(ideval)

    # del cursor

def main():
    area_buffer, interseccion = create_points_intersect(RED_HIDRICA, CURVAS, 1000)
    extract_q_values(interseccion)

if __name__ == '__main__':
    main()