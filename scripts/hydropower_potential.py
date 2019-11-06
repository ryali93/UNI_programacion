import arcpy
import os
import pandas as pd
from create_points_from_polyline import create_points

arcpy.env.overwriteOutput = True
arcpy.env.outputCoordinateSystem = arcpy.SpatialReference(32717)

# Folders
BASE_DIR = r'E:\2019\UNI'
RASTER_DIR = os.path.join(BASE_DIR, "data", "raster")
SHP_DIR = os.path.join(BASE_DIR, "data", "shp")
XLS_DIR = os.path.join(BASE_DIR, "xlsx")

# Files
DEM = os.path.join(RASTER_DIR, "dem_area_17s.tif")
SLOPE = os.path.join(RASTER_DIR, "slope_deg_17s.tif")
FLOW_DIR = os.path.join(RASTER_DIR, "fdir_area.tif")
FLOW_ACC_MIN = os.path.join(RASTER_DIR, "facc_08.tif")
RED_HIDRICA = os.path.join(SHP_DIR, "red_hidrica_test_1.shp")
# POINTS_RED_HIDRICA = os.path.join(SHP_DIR, "points_red_hidrica_test_1.shp")
SPLIT_RED_HIDRICA = os.path.join(SHP_DIR, "split_red_hidrica_test_1.shp")

CURVAS = os.path.join(SHP_DIR, "gpl_curvas.shp")
# PUNTOS_CURVA = os.path.join(SHP_DIR, "puntos_curva_test.shp")
# PUNTOS_MAYOR = os.path.join(SHP_DIR, "puntos_mayor_test.shp")
# EVAL_AREA = os.path.join(SHP_DIR, "areas_test_1.shp")

# FIRST VERSION
PUNTOS_FIRST = os.path.join(SHP_DIR, "gpt_first_v.shp")
TABLA_FIRST = os.path.join(XLS_DIR, "tb_first.xls")

# SECOND VERSION
PUNTOS_SECOND = os.path.join(SHP_DIR, "gpt_second_v.shp")
PUNTOS_SECOND_EVAL = os.path.join(SHP_DIR, "gpt_second_eval.shp")
INTERSECT = os.path.join(SHP_DIR, "gpt_puntos_intersect.shp")
ISOCAUDAL = os.path.join(SHP_DIR, "gpl_isocaudales.shp")
TABLA_SECOND = os.path.join(XLS_DIR, "tb_second.xls")
# AREA_BUFFER = os.path.join(SHP_DIR, "gpo_buffer_2.shp")
# CURVAS_MULTIPART = os.path.join(SHP_DIR, "gpl_curvas_multipart.shp")


ID_EVAL = "ID_EVAL"
TIPO = "TIPO"

def flow_acc_month():
    for i in range(1,13):
        name = str(i).zfill(2)
        arcpy.gp.FlowAccumulation_sa(
            os.path.join(RASTER_DIR,"fdir_area.tif"), 
            os.path.join(RASTER_DIR, "facc_{}.tif".format(name)), 
            os.path.join(RASTER_DIR, "q_area_{}.tif".format(name)), 
            'FLOAT')
        print(name)


def create_river(flowacc, treshold=10):
    '''
    flowacc: Acumulacion de flujo de un mes de estiaje
    treshold: Umbral
    '''
    raster_in = arcpy.sa.Raster(flowacc) # r'E:\2019\UNI\data\raster\facc_08.tif'
    river_umbral = arcpy.sa.Con(raster_in >= treshold, 1, 0)
    arcpy.RasterToPolyline_conversion(river_umbral, 
        RED_HIDRICA, 
        'ZERO', '0', 'NO_SIMPLIFY', 'Value')


def create_interview_points(river, distance, output):
    '''
    river: Shapefile de eje de rios
    distance: Separacion entre los puntos del cauce
    output: Salida de puntos creados
    '''
    create_points(
        polyline=river,
        choice='INTERVAL BY DISTANCE', 
        start_from='BEGINNING', 
        distance=distance, 
        end_points='BOTH', 
        output=output)

def split_river(river, points, output):
    '''
    river: Shapefile de eje de rios
    '''
    # Cortar eje de rio en diferentes polilineas
    arcpy.SplitLineAtPoint_management(
        river, 
        points, 
        output,
        '5000 Meters')

def create_eval_areas(river_split, output, buff):
    '''
    river_split: Secciones del rio
    output: salida de areas de evaluacion
    buff: area de influencia
    '''
    arcpy.Buffer_analysis(
        river_split, 
        output, 
        '{} Meters'.format(buff), 'FULL', 'ROUND', 'NONE', '#', 'PLANAR')
    arcpy.AddField_management(output, ID_EVAL, "TEXT", "#", "#", 20)
    n = 0
    arcid_tmp = 0
    with arcpy.da.UpdateCursor(output, [ID_EVAL, "arcid"]) as cursor:
        for x in cursor:
            n += 1
            x[0] = str(x[1]) + "_" + str(n)
            if arcid_tmp != x[1]:
                n = 0
            arcid_tmp = x[1]
            cursor.updateRow(x)

    # fields = [f.name for f in arcpy.ListFields(output) if f.name != ID_EVAL]
    fields = 'arcid;grid_code;from_node;to_node;BUFF_DIST;ORIG_FID'
    arcpy.DeleteField_management(output, fields)

def first_version(river_split):
    '''
    river_split: rio con cortes
    '''
    arcpy.AddField_management(river_split, ID_EVAL, "TEXT", "#", "#", 20)
    n = 0
    with arcpy.da.UpdateCursor(river_split, [ID_EVAL]) as cursor:
        for x in cursor:
            n += 1
            x[0] = str(n).zfill(4)
            cursor.updateRow(x)
    puntos_vertices = arcpy.FeatureVerticesToPoints_management(
        river_split, 
        PUNTOS_FIRST, 
        "BOTH_ENDS")

    LISTA_Q = [[os.path.join(RASTER_DIR, "facc_" + str(x).zfill(2)+".tif"), "Q_" + str(x).zfill(2)] for x in range(1, 13)]
    print(LISTA_Q)

    extract_points = arcpy.sa.ExtractMultiValuesToPoints(
        PUNTOS_FIRST, 
        [[DEM, "Z_TOMA"], [DEM, "Z_RIO"]] + LISTA_Q, 
        "NONE")

    # dicc = {}
    # with arcpy.da.SearchCursor(PUNTOS_FIRST, [ID_EVAL, "Z", "Q"]) as cursor:
    #     for x in cursor:
    #         if x[0] not in dicc.keys():
    #             dicc[x[0]] = {}
    #             dicc[x[0]]["Z"] = []
    #             dicc[x[0]]["Q"] = []
    #         dicc[x[0]]["Z"].append(x[1])
    #         dicc[x[0]]["Q"].append(x[2])

    # with open("ttt.csv", "w") as f:
    #     for d in dicc:
    #         delta_z = max(dicc[d]["Z"]) - min(dicc[d]["Z"])
    #         min_q = min(dicc[d]["Q"])
    #         f.write("{},{},{}".format(d, delta_z, min_q))
    #         f.write("\n")
    # f.close()
def first_version_table(layer, tabla):
    df = table_to_data_frame(layer)
    df = df.groupby("ID_EVAL").agg(
        {
             'Z_TOMA':max,
             'Z_RIO': min,
             'Q_01': lambda x: round(max(x), 2),
             'Q_02': lambda x: round(max(x), 2),
             'Q_03': lambda x: round(max(x), 2),
             'Q_04': lambda x: round(max(x), 2),
             'Q_05': lambda x: round(max(x), 2),
             'Q_06': lambda x: round(max(x), 2),
             'Q_07': lambda x: round(max(x), 2),
             'Q_08': lambda x: round(max(x), 2),
             'Q_09': lambda x: round(max(x), 2),
             'Q_10': lambda x: round(max(x), 2),
             'Q_11': lambda x: round(max(x), 2),
             'Q_12': lambda x: round(max(x), 2),
        }
    )
    df["Z_DELTA"] = df["Z_TOMA"] - df["Z_RIO"]
    df["POT_01"] = df["Q_01"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_02"] = df["Q_02"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_03"] = df["Q_03"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_04"] = df["Q_04"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_05"] = df["Q_05"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_06"] = df["Q_06"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_07"] = df["Q_07"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_08"] = df["Q_08"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_09"] = df["Q_09"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_10"] = df["Q_10"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_11"] = df["Q_11"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_12"] = df["Q_12"] * df["Z_DELTA"] * 9810 / 1000000

    df["POT_AN"] = df["POT_01"]+df["POT_02"]+df["POT_03"]+df["POT_04"]+df["POT_05"]+df["POT_06"]+df["POT_07"]+df["POT_08"]+df["POT_09"]+df["POT_10"]+df["POT_11"]+df["POT_12"]

    df = df[df['Z_DELTA'].notnull()]
    df.to_excel(tabla)


def second_version(river, interseccion, isocaudal, output, buff):
    salida = arcpy.CopyFeatures_management(interseccion, output)
    arcpy.DeleteRows_management(salida)

    mfl_curvas = arcpy.MakeFeatureLayer_management(isocaudal, "mfl_curvas")

    list_ids = list(set([x[0] for x in arcpy.da.SearchCursor(interseccion, [ID_EVAL])]))
    print(list_ids)

    lista_q = ["Q_" + str(x).zfill(2) for x in range(1, 13)]
    cursorM = arcpy.da.InsertCursor(output, ["SHAPE@XY", ID_EVAL, "Z_TOMA"] + lista_q)

    for ideval in list_ids:
        print(ideval)
        mfl_pt = arcpy.MakeFeatureLayer_management(interseccion, "point_mfl", "{} = '{}'".format(ID_EVAL, ideval))
        curvas_select = arcpy.SelectLayerByLocation_management(
                mfl_curvas, 'WITHIN_A_DISTANCE', mfl_pt, '70 Meters', 'NEW_SELECTION', 'NOT_INVERT')

        feature_vertex = arcpy.FeatureVerticesToPoints_management(
            mfl_curvas, 
            "in_memory\\points_vertex", 'BOTH_ENDS')

        valor_z = [x[0] for x in arcpy.da.SearchCursor(curvas_select, ["Contour"])][0]

        # Feature Vertex
        t = 0
        with arcpy.da.SearchCursor(feature_vertex, ["SHAPE@XY"] + lista_q) as cursor:
            for m in cursor:
                t += 1
                qs = [m[q+1] for q in range(len(lista_q))]
                cursorM.insertRow([m[0], ideval + "_{}".format(t), valor_z] + qs)
                punto_curva = arcpy.Snap_edit(feature_vertex, "{} EDGE '1000 Meters'".format(river))
                coord_rio = [x[0] for x in arcpy.da.SearchCursor(feature_vertex, ["SHAPE@XY"])][0]
                cursorM.insertRow([coord_rio, ideval + "_{}".format(t), valor_z] + qs)

        arcpy.SelectLayerByAttribute_management(mfl_curvas, "CLEAR_SELECTION")

    arcpy.gp.ExtractMultiValuesToPoints_sa(output, [[DEM, "Z_RIO"]])
    arcpy.DeleteField_management(output, 'FID_red_hi;FID_gpl_cu;Contour;ORIG_FID')

    del cursor
    del cursorM
    return output

def second_version_table(layer, tabla):
    df = table_to_data_frame(layer)
    df = df.groupby("ID_EVAL").agg(
        {
             'Z_TOMA':max,
             'Z_RIO': min,
             'Q_01': lambda x: round(max(x), 2),
             'Q_02': lambda x: round(max(x), 2),
             'Q_03': lambda x: round(max(x), 2),
             'Q_04': lambda x: round(max(x), 2),
             'Q_05': lambda x: round(max(x), 2),
             'Q_06': lambda x: round(max(x), 2),
             'Q_07': lambda x: round(max(x), 2),
             'Q_08': lambda x: round(max(x), 2),
             'Q_09': lambda x: round(max(x), 2),
             'Q_10': lambda x: round(max(x), 2),
             'Q_11': lambda x: round(max(x), 2),
             'Q_12': lambda x: round(max(x), 2),
        }
    )
    df["Z_DELTA"] = df["Z_TOMA"] - df["Z_RIO"]
    df["POT_01"] = df["Q_01"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_02"] = df["Q_02"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_03"] = df["Q_03"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_04"] = df["Q_04"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_05"] = df["Q_05"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_06"] = df["Q_06"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_07"] = df["Q_07"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_08"] = df["Q_08"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_09"] = df["Q_09"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_10"] = df["Q_10"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_11"] = df["Q_11"] * df["Z_DELTA"] * 9810 / 1000000
    df["POT_12"] = df["Q_12"] * df["Z_DELTA"] * 9810 / 1000000

    df["POT_AN"] = df["POT_01"]+df["POT_02"]+df["POT_03"]+df["POT_04"]+df["POT_05"]+df["POT_06"]+df["POT_07"]+df["POT_08"]+df["POT_09"]+df["POT_10"]+df["POT_11"]+df["POT_12"]

    df = df[df['Z_DELTA'].notnull()]
    df.to_excel(tabla)

def eval_area(area):
    arcpy.DeleteRows_management(PUNTOS_MAYOR)
    idevals = [x[0] for x in arcpy.da.SearchCursor(area, [ID_EVAL])]
    cursor = arcpy.da.InsertCursor(PUNTOS_MAYOR, ['SHAPE@XY', ID_EVAL, "D_ZTZR", TIPO])
    cursorC = arcpy.da.InsertCursor(PUNTOS_CURVA, ['SHAPE@XY', ID_EVAL])
    mfl_curvas = arcpy.MakeFeatureLayer_management(CURVAS, "mfl_curvas")

    print(len(idevals))

    for idev in idevals:
        try:
            mfl = arcpy.MakeFeatureLayer_management(area, "mfl_area", "{} = '{}'".format(ID_EVAL, idev))
            slope_clip = arcpy.Clip_management(
                SLOPE, '#', "in_memory\\slope_clip", mfl, '#', 'ClippingGeometry', 'MAINTAIN_EXTENT')
            mayor = arcpy.Raster(slope_clip).maximum
            raster_con = arcpy.gp.Con_sa(
                slope_clip, '1', "in_memory\\slope_clip_con", '0', 'value = {}'.format(mayor))

            # Punto de camara de carga
            punto_mayor = arcpy.RasterToPoint_conversion(
                raster_con, "in_memory\\punto_mayor", "Value")
            coord = [x[0] for x in arcpy.da.SearchCursor(punto_mayor, ["SHAPE@XY"], "grid_code = 1")][0]

            # # Punto en curva
            # punto_curva = arcpy.Snap_edit(punto_mayor, "{} EDGE '50 Meters'".format(CURVAS))
            
            # mfl_pt = arcpy.MakeFeatureLayer_management(punto_curva, "mfl_pt")

            # coord_curva_ini = [x[0] for x in arcpy.da.SearchCursor(punto_curva, ["SHAPE@XY"])][0]
            # print(coord_curva_ini)
            # curvas_select = arcpy.SelectLayerByLocation_management(
            #     mfl_curvas, 'WITHIN_A_DISTANCE', mfl_pt, '30 Meters', 'NEW_SELECTION', 'NOT_INVERT')
            # punto_curva_fin = arcpy.Intersect_analysis(
            #     [RED_HIDRICA, curvas_select], "in_memory\\point_intersect_river", 'ALL', '#', 'POINT')
            # coord_curva_fin = [x[0] for x in arcpy.da.SearchCursor(punto_curva_fin, ["SHAPE@XY"])][0]

            # cursorC.insertRow([coord_curva_ini, idev])
            # cursorC.insertRow([coord_curva_fin, idev])

            # Punto en el eje del rio
            punto_river = arcpy.Snap_edit(punto_mayor, "{} EDGE '500 Meters'".format(RED_HIDRICA))
            coord_riv = [x[0] for x in arcpy.da.SearchCursor(punto_river, ["SHAPE@XY"])][0]

            dist = ((coord[0] - coord_riv[0])**2 + (coord[1] - coord_riv[1])**2) ** 0.5
            print(dist)
            cursor.insertRow([coord, idev, round(dist, 2), "TOMA"])
            cursor.insertRow([coord_riv, idev, round(dist, 2), "RIO"])

            arcpy.SelectLayerByAttribute_management(mfl_curvas, "CLEAR_SELECTION")
        except:
            pass

    del cursor
    del cursorC

def extract_from_raster(points):

    list_raster = [os.path.join(RASTER_DIR, "facc_"+str(x).zfill(2)+".tif") for x in range(1, 13)]
    list_raster += [DEM]
    arcpy.gp.ExtractMultiValuesToPoints_sa(
        points, list_raster)

def table_to_data_frame(in_table, input_fields=None, where_clause=None):
    OIDFieldName = arcpy.Describe(in_table).OIDFieldName
    if input_fields:
        final_fields = [OIDFieldName] + input_fields
    else:
        final_fields = [field.name for field in arcpy.ListFields(in_table)]
    data = [row for row in arcpy.da.SearchCursor(in_table, final_fields, where_clause=where_clause)]
    fc_dataframe = pd.DataFrame(data, columns=final_fields)
    fc_dataframe = fc_dataframe.set_index(OIDFieldName, drop=True)
    return fc_dataframe

def main():
    # flow_acc_month()

    # create_river(FLOW_ACC_MIN)
    # create_interview_points(RED_HIDRICA, 5000, POINTS_RED_HIDRICA)
    # split_river(RED_HIDRICA, POINTS_RED_HIDRICA, SPLIT_RED_HIDRICA)
    # create_eval_areas(SPLIT_RED_HIDRICA, EVAL_AREA, 500)
    # eval_area(EVAL_AREA)
    # extract_from_raster(PUNTOS_MAYOR)

    first_version(SPLIT_RED_HIDRICA)
    first_version_table(PUNTOS_FIRST, TABLA_FIRST)

    # second = second_version(RED_HIDRICA, INTERSECT, ISOCAUDAL, PUNTOS_SECOND_EVAL, 1000)
    # Antes, hacer Extract MultiValues to Point y arreglar el Z_RIO
    # second_version_table(PUNTOS_SECOND_EVAL, TABLA_SECOND)


if __name__ == '__main__':
    main()