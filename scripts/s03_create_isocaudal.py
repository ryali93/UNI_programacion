from settings import *

# Existing files
DEM = os.path.join(RASTER_DIR, "ra_dem.tif")
RED_HIDRICA = os.path.join(SHP_DIR, "gpl_red_hidrica.shp")
CURVAS = os.path.join(SHP_DIR, "gpl_curvas.shp")

# New files
INTERSECT = os.path.join(SHP_DIR, "gpt_puntos_intersect.shp")
AREA_BUFFER = os.path.join(SHP_DIR, "gpo_buffer_rio.shp")
ISOCAUDAL = os.path.join(SHP_DIR, "gpl_isocaudal.shp")


def create_points_intersect(river, curvas, buffer_pol, buff):
    '''
    :return: area de buffer y puntos de interseccion del rio con las curvas de nivel
    '''
    area_buffer = arcpy.Buffer_analysis(river, buffer_pol, '{} Meters'.format(buff), 'FULL', 'ROUND', 'ALL', '#', 'PLANAR')
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

def extract_q_values(interseccion, output):
    puntos_multipart = arcpy.MultipartToSinglepart_management(interseccion, output)
    LISTA_Q = [[os.path.join(RASTER_DIR, "facc_" + str(x).zfill(2) + "_min.tif"), "Q_" + str(x).zfill(2)] for x in range(1, 13)]
    list_raster = [[DEM, "Z_TOMA"]] + LISTA_Q
    arcpy.gp.ExtractMultiValuesToPoints_sa(puntos_multipart, list_raster)
    return puntos_multipart

def isocaudal_clip(river, curvas, buffer_pol, isocaudal, interseccion):
    curvas_clip = arcpy.Clip_analysis(curvas, buffer_pol, "in_memory\\curvas_clip")
    curvas_multipart = arcpy.MultipartToSinglepart_management(curvas_clip, "in_memory\\curvas_multipart")
    mfl_curvas = arcpy.MakeFeatureLayer_management(curvas_multipart, "mfl_curvas")
    mfl_rios = arcpy.MakeFeatureLayer_management(river, "mfl_rios")

    select_curvas = arcpy.SelectLayerByLocation_management(mfl_curvas, 'INTERSECT', mfl_rios, '#', 'NEW_SELECTION', 'NOT_INVERT')
    copy_curvas = arcpy.CopyFeatures_management(select_curvas, "in_memory\\curvas")

    print([x.name for x in arcpy.ListFields(copy_curvas)])

    arcpy.SpatialJoin_analysis(copy_curvas, interseccion, isocaudal,
        'JOIN_ONE_TO_ONE', 'KEEP_ALL',
        "#",
        'INTERSECT', '#', '#')

    arcpy.DeleteField_management(copy_curvas,'Join_Count;TARGET_FID;OBJECTID;Id;Shape_Leng;ORIG_FID;FID_red_hi;FID_gpl_cu;Contour_1;ORIG_FID_1')
    arcpy.SelectLayerByAttribute_management(mfl_curvas, "CLEAR_SELECTION")

def main():
    area_buffer, interseccion = create_points_intersect(RED_HIDRICA, CURVAS, AREA_BUFFER, 1000)
    inters = extract_q_values(interseccion, INTERSECT)
    isocaudal_clip(RED_HIDRICA, CURVAS, AREA_BUFFER, ISOCAUDAL, inters)

if __name__ == '__main__':
    main()