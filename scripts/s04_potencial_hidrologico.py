from settings import *
from s00_funciones import *

# Existing files
DEM = os.path.join(RASTER_DIR, "ra_dem.tif")
SLOPE = os.path.join(RASTER_DIR, "slope_deg_17s.tif")
FLOW_ACC_MIN = os.path.join(RASTER_DIR, "facc_03.tif")  # Acumulacion de flujo para mes 8 (agosto)

# New files
RED_HIDRICA = os.path.join(SHP_DIR, "gpl_red_hidrica.shp") # output
POINTS_RED_HIDRICA = os.path.join(SHP_DIR, "gpt_red_hidrica_puntos.shp") # output
SPLIT_RED_HIDRICA = os.path.join(SHP_DIR, "gpl_red_hidrica_split.shp") # output

# OLD VERSION
# CURVAS = os.path.join(SHP_DIR, "gpl_curvas.shp")
# PUNTOS_CURVA = os.path.join(SHP_DIR, "puntos_curva_test.shp")
# PUNTOS_MAYOR = os.path.join(SHP_DIR, "puntos_mayor_test.shp")
# EVAL_AREA = os.path.join(SHP_DIR, "gpo_area_eval.shp")

# FIRST VERSION
# PUNTOS_FIRST = os.path.join(SHP_DIR, "gpt_first_5000.shp")
# TABLA_FIRST = os.path.join(XLS_DIR, "tb_first_5000.xls")

# SECOND VERSION
# PUNTOS_SECOND = os.path.join(SHP_DIR, "gpt_second.shp")
# INTERSECT = os.path.join(SHP_DIR, "gpt_puntos_intersect.shp")
# ISOCAUDAL = os.path.join(SHP_DIR, "gpl_isocaudal.shp")
# TABLA_SECOND = os.path.join(XLS_DIR, "tb_second.xls")

def create_river(flowacc, output, treshold=0.5):
    '''
    flowacc: Acumulacion de flujo de un mes de estiaje
    treshold: Umbral
    '''
    raster_in = arcpy.sa.Raster(flowacc) # r'E:\2019\UNI\data\raster\facc_08.tif'
    river_umbral = arcpy.sa.Con(raster_in >= treshold, 1, 0)
    arcpy.RasterToPolyline_conversion(river_umbral,
        output,
        'ZERO', '0', 'NO_SIMPLIFY', 'Value')

def create_interview_points(river, distance, output):
    '''
    river: Shapefile de eje de rios
    distance: Separacion entre los puntos del cauce
    output: Salida de puntos creados
    '''
    arcpy.GeneratePointsAlongLines_management(
        river,
        output,
        'DISTANCE',
        Distance='{} meters'.format(distance))

def split_river(river, points, output):
    '''
    river: Shapefile de eje de rios
    '''
    # Cortar eje de rio en diferentes polilineas
    arcpy.SplitLineAtPoint_management(
        river, 
        points, 
        output,
        '10 Meters')

    with arcpy.da.UpdateCursor(output, ["SHAPE@"], spatial_reference=arcpy.SpatialReference(32718)) as cursor:
        for x in cursor:
            longitud = x[0].getLength('PLANAR', 'METERS')
            if longitud < 1000:
                cursor.deleteRow()


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

def first_version(river_split, output):
    '''
    river_split: rio con cortes
    '''
    arcpy.AddField_management(river_split, ID_EVAL, "TEXT", "#", "#", 20)
    n = 0
    with arcpy.da.UpdateCursor(river_split, [ID_EVAL]) as cursor:
        for x in cursor:
            n += 1
            x[0] = "ID" + str(n).zfill(4)
            cursor.updateRow(x)
    puntos_vertices = arcpy.FeatureVerticesToPoints_management(
        river_split, 
        output,
        "BOTH_ENDS")

    LISTA_Q = [[os.path.join(RASTER_DIR, "facc_" + str(x).zfill(2) + ".tif"), "Q_" + str(x).zfill(2)] for x in range(1, 13)]
    print(LISTA_Q)

    extract_points = arcpy.sa.ExtractMultiValuesToPoints(
        output,
        [[DEM, "Z_TOMA"], [DEM, "Z_RIO"]] + LISTA_Q, 
        "NONE")

def first_version_table(layer, tabla):
    df = table_to_data_frame(layer)
    df = df.groupby("ID_EVAL").agg(
        {
             'Z_TOMA': max,
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
    df["POT_01"] = df["Q_01"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_02"] = df["Q_02"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_03"] = df["Q_03"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_04"] = df["Q_04"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_05"] = df["Q_05"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_06"] = df["Q_06"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_07"] = df["Q_07"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_08"] = df["Q_08"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_09"] = df["Q_09"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_10"] = df["Q_10"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_11"] = df["Q_11"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000
    df["POT_12"] = df["Q_12"] * df["Z_DELTA"] * 0.8 * 9810 / 1000000

    df["POT_AN"] = df["POT_01"]+df["POT_02"]+df["POT_03"]+df["POT_04"]+df["POT_05"]+df["POT_06"]+df["POT_07"]+df["POT_08"]+df["POT_09"]+df["POT_10"]+df["POT_11"]+df["POT_12"]
    df["POT_MEDIO"] = df["POT_AN"].apply(lambda x: x/12)
    df["POT_MAX"] = pd.DataFrame([df["POT_01"],df["POT_02"],df["POT_03"],df["POT_04"],df["POT_05"],df["POT_06"],df["POT_07"],df["POT_08"],df["POT_09"],df["POT_10"],df["POT_11"],df["POT_12"]]).max()
    df["POT_MIN"] = pd.DataFrame([df["POT_01"],df["POT_02"],df["POT_03"],df["POT_04"],df["POT_05"],df["POT_06"],df["POT_07"],df["POT_08"],df["POT_09"],df["POT_10"],df["POT_11"],df["POT_12"]]).min()

    df = df[df['Z_DELTA'].notnull()]

    df['CATEG'] = ""
    df.loc[(df["Z_DELTA"] <= 15), 'CATEG'] = str('BAJO')
    df.loc[(df["Z_DELTA"].between(15, 50)), 'CATEG'] = str('MEDIO')
    df.loc[(df["Z_DELTA"] >= 50), 'CATEG'] = str('ALTO')

    df_coords = first_coordenadas_post(layer)

    df = pd.merge(df, df_coords, on='Z_TOMA', how='inner')
    df.to_csv(tabla)

def first_coordenadas_post(layer):
    df_np = pd.DataFrame(arcpy.da.FeatureClassToNumPyArray(layer, ["ID_EVAL", "Z_TOMA", "SHAPE@X", "SHAPE@Y"]))
    df_min = df_np.groupby(['ID_EVAL']).agg({'Z_TOMA': 'min'})
    ival_ztoma = zip(list(df_min.Z_TOMA.index), list(df_min.Z_TOMA))

    dicc = {"ID_EVAL": [], "Z_TOMA": [], "X": [], "Y": []}
    with arcpy.da.SearchCursor(layer, ["ID_EVAL", "Z_TOMA", "SHAPE@X", "SHAPE@Y"]) as cursor:
        for x in cursor:
            if (x[0], x[1]) not in ival_ztoma:
                dicc["ID_EVAL"].append(x[0])
                dicc["Z_TOMA"].append(x[1])
                dicc["X"].append(x[2])
                dicc["Y"].append(x[3])
    return pd.DataFrame(dicc)

def first_version_post(puntos, tabla):
    df = pd.read_csv(tabla)
    dicc = {
        "BAJO": list(df[df["Z_DELTA"] <= 15][ID_EVAL]),
        "MEDIO": list(df[df["Z_DELTA"].between(15, 50)][ID_EVAL]),
        "ALTO": list(df[df["Z_DELTA"] >= 15][ID_EVAL])
    }

    arcpy.AddField_management(puntos, "CATEG", "TEXT", "#", "#", 50)
    with arcpy.da.UpdateCursor(puntos, [ID_EVAL, "CATEG"]) as cursor:
        for x in cursor:
            if x[0] in dicc["BAJO"]:
                x[1] = "BAJO"
            elif x[0] in dicc["MEDIO"]:
                x[1] = "MEDIO"
            elif x[0] in dicc["ALTO"]:
                x[1] = "ALTO"
            else:
                x[1] = "SIN CATEGORIA"
            cursor.updateRow(x)

def first_version_post_2(puntos, tabla):
    xy_event = arcpy.MakeXYEventLayer_management(tabla, "X", "Y", "in_memory\\puntos", arcpy.SpatialReference(32718))
    arcpy.CopyFeatures_management(xy_event, puntos)

def second_version(river, interseccion, isocaudal, output):
    arcpy.CopyFeatures_management(interseccion, output)
    salida = arcpy.CopyFeatures_management(output, "in_memory\\salida")
    arcpy.DeleteRows_management(salida)

    mfl_curvas = arcpy.MakeFeatureLayer_management(isocaudal, "mfl_curvas")

    list_ids = list(set([x[0] for x in arcpy.da.SearchCursor(interseccion, [ID_EVAL])]))
    print(list_ids)

    lista_q = ["Q_" + str(x).zfill(2) for x in range(1, 13)]
    cursorM = arcpy.da.InsertCursor(salida, ["SHAPE@XY", ID_EVAL, "Z_TOMA"] + lista_q)

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

    arcpy.gp.ExtractValuesToPoints_sa(salida,
                                      DEM,
                                      output, 'NONE',
                                      'VALUE_ONLY')
    # arcpy.gp.ExtractMultiValuesToPoints_sa(output, [[DEM, "Z_RIO"]])
    arcpy.DeleteField_management(output, 'FID_red_hi;FID_gpl_cu;Contour;ORIG_FID')

    del cursor
    del cursorM
    return output

def second_version_table(layer, tabla):
    df = table_to_data_frame(layer)
    df['Z_RIO'] = df['RASTERVALU']
    df = df.groupby("ID_EVAL").agg(
        {
             'Z_TOMA': max,
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

    df['CATEG'] = ""
    df.loc[(df["Z_DELTA"] <= 15), 'CATEG'] = str('BAJO')
    df.loc[(df["Z_DELTA"].between(15, 50)), 'CATEG'] = str('MEDIO')
    df.loc[(df["Z_DELTA"] >= 50), 'CATEG'] = str('ALTO')

    df.to_excel(tabla)

def second_version_post(puntos, tabla):
    df = pd.read_excel(tabla)
    dicc = {
        "BAJO": list(df[df["Z_DELTA"] <= 15][ID_EVAL]),
        "MEDIO": list(df[df["Z_DELTA"].between(15, 50)][ID_EVAL]),
        "ALTO": list(df[df["Z_DELTA"] >= 15][ID_EVAL])
    }
    arcpy.AddField_management(puntos, "CATEG", "TEXT", "#", "#", 50)
    with arcpy.da.UpdateCursor(puntos, [ID_EVAL, "CATEG"]) as cursor:
        for x in cursor:
            if x[0] in dicc["BAJO"]:
                x[1] = "BAJO"
            elif x[0] in dicc["MEDIO"]:
                x[1] = "MEDIO"
            elif x[0] in dicc["ALTO"]:
                x[1] = "ALTO"
            else:
                x[1] = "SIN CATEGORIA"
            cursor.updateRow(x)


def eval_area(area, curvas, puntos_valor, puntos_curva):
    arcpy.DeleteRows_management(puntos_valor)
    idevals = [x[0] for x in arcpy.da.SearchCursor(area, [ID_EVAL])]
    cursor = arcpy.da.InsertCursor(puntos_valor, ['SHAPE@XY', ID_EVAL, "D_ZTZR", TIPO])
    cursorC = arcpy.da.InsertCursor(puntos_curva, ['SHAPE@XY', ID_EVAL])
    mfl_curvas = arcpy.MakeFeatureLayer_management(curvas, "mfl_curvas")

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
    list_raster = [os.path.join(RASTER_DIR, "facc_"+str(x).zfill(2) + ".tif") for x in range(1, 13)]
    list_raster += [DEM]
    arcpy.gp.ExtractMultiValuesToPoints_sa(
        points, list_raster)

def main():
    # Crear variables
    create_river(FLOW_ACC_MIN, RED_HIDRICA)
    # create_interview_points(RED_HIDRICA, 5000, POINTS_RED_HIDRICA)
    # split_river(RED_HIDRICA, POINTS_RED_HIDRICA, SPLIT_RED_HIDRICA)

    # Version antigua
    # create_eval_areas(SPLIT_RED_HIDRICA, EVAL_AREA, 500)
    # eval_area(EVAL_AREA, CURVAS, PUNTOS_MAYOR, PUNTOS_CURVA)
    # extract_from_raster(PUNTOS_MAYOR)
    # extract_from_raster(PUNTOS_CURVA)

    # Primera version
    # lista_distancia = [500, 1000, 5000]
    lista_distancia = [5000]
    for distancia in lista_distancia:
        create_interview_points(RED_HIDRICA, distancia, POINTS_RED_HIDRICA)
        split_river(RED_HIDRICA, POINTS_RED_HIDRICA, SPLIT_RED_HIDRICA)

        print(len([x for x in arcpy.da.SearchCursor(POINTS_RED_HIDRICA, ["FID"])]))

        PUNTOS_FIRST = os.path.join(SHP_DIR, "gpt_first_{}_qmean.shp".format(distancia))
        PUNTOS_FIRST_Q = os.path.join(SHP_DIR, "gpt_{}_q.shp".format(distancia))
        TABLA_FIRST = os.path.join(XLS_DIR, "tb_first_{}_qmean.csv".format(distancia))

        first_version(SPLIT_RED_HIDRICA, PUNTOS_FIRST)
        first_version_table(PUNTOS_FIRST, TABLA_FIRST)
        first_version_post(PUNTOS_FIRST, TABLA_FIRST)
        first_version_post_2(PUNTOS_FIRST_Q, TABLA_FIRST)

    # Segunda version
    # second_version(RED_HIDRICA, INTERSECT, ISOCAUDAL, PUNTOS_SECOND)
    # second_version_table(PUNTOS_SECOND, TABLA_SECOND)
    # second_version_post(PUNTOS_SECOND, TABLA_SECOND)


# if __name__ == '__main__':
#     main()