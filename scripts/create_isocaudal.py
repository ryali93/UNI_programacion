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
LISTA_Q = [[os.path.join(RASTER_DIR, "facc_" + str(x).zfill(2)+"_min.tif"), "Q_" + str(x).zfill(2)] for x in range(1, 13)]

RED_HIDRICA = os.path.join(SHP_DIR, "red_hidrica_test_1.shp")
CURVAS = os.path.join(SHP_DIR, "gpl_curvas.shp")

# New files
PUNTOS = os.path.join(SHP_DIR, "gpt_second_v.shp")
INTERSECT = os.path.join(SHP_DIR, "gpt_puntos_intersect.shp")
AREA_BUFFER = os.path.join(SHP_DIR, "gpo_buffer_rio.shp")
ISOCAUDAL = os.path.join(SHP_DIR, "gpl_isocaudal.shp")


ID_EVAL = "ID_EVAL"

def create_points_intersect(river, curvas, buffer_pol, buff):
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

def extract_q_values(interseccion):
    puntos_multipart = arcpy.MultipartToSinglepart_management(interseccion, INTERSECT)
    list_raster = [[DEM, "Z_TOMA"]] + LISTA_Q
    arcpy.gp.ExtractMultiValuesToPoints_sa(puntos_multipart, list_raster)

def isocaudal_clip(river, curvas, buffer_pol, isocaudal, interseccion):
    curvas_clip = arcpy.Clip_analysis(curvas, buffer_pol, "in_memory\\curvas_clip")
    curvas_multipart = arcpy.MultipartToSinglepart_management(curvas_clip, "in_memory\\curvas_multipart")

    mfl_curvas = arcpy.MakeFeatureLayer_management(curvas_multipart, "mfl_curvas")
    mfl_rios = arcpy.MakeFeatureLayer_management(river, "mfl_rios")

    select_curvas = arcpy.SelectLayerByLocation_management(mfl_curvas, 'INTERSECT', mfl_rios, '#', 'NEW_SELECTION', 'NOT_INVERT')

    copy_curvas = arcpy.CopyFeatures_management(select_curvas, "in_memory\\select_curvas")

    fms = arcpy.FieldMappings()
    fms.addTable(interseccion)
    fields_sequence = ['ID_EVAL','Z_TOMA','Q_01','Q_02','Q_03','Q_04','Q_05','Q_06','Q_07','Q_08','Q_09','Q_10','Q_11','Q_12']
    # fields_sequence = ['FID_red_hi', 'FID_gpl_c', 'ORIG_FID']
    # fields_to_delete = [f.name for f in fms.fields if f.name not in fields_sequence]
    # for field in fields_to_delete:
    #     fms.removeFieldMap(fms.findFieldMapIndex(field))
    fms_out = arcpy.FieldMappings()
    fms_out.addTable(copy_curvas)

    print(fms)
    print(fields_sequence)
    print([x.name for x in arcpy.ListFields(copy_curvas)])

    for field in fields_sequence:
        mapping_index = fms.findFieldMapIndex(field)
        field_map = fms.fieldMappings[mapping_index]
        fms_out.addFieldMap(field_map)
    arcpy.SpatialJoin_analysis(copy_curvas, interseccion, isocaudal, 
        'JOIN_ONE_TO_ONE', 'KEEP_ALL', 
        fms_out, 
        'INTERSECT', '#', '#')

    # arcpy.AddJoin_management(mfl_curvas, "ID_EVAL", mfl_rios, "ID_EVAL")
    # arcpy.CopyFeatures_management(mfl_curvas, isocaudal)
    arcpy.SelectLayerByAttribute_management(mfl_curvas, "CLEAR_SELECTION")

    # ********************************************************
    # Aqui falta terminar el spatial join
    # ********************************************************

def main():
    area_buffer, interseccion = create_points_intersect(RED_HIDRICA, CURVAS, AREA_BUFFER, 1000)
    extract_q_values(interseccion)
    isocaudal_clip(RED_HIDRICA, CURVAS, AREA_BUFFER, ISOCAUDAL, interseccion)

if __name__ == '__main__':
    main()