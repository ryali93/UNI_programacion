from settings import *

def create_points(polyline, choice='INTERVAL BY DISTANCE', start_from='BEGINNING', distance=1000, end_points='BOTH', output=''):
    '''
    polyline : eje del rio
    choice : [DISTANCE, PERCENTAGE, INTERVAL BY DISTANCE, INTERVAL BY PERCENTAGE, START/END POINTS]
    start_from : [BEGINNING, END]
    distance : distancia
    end_points : [NO, START, END, BOTH]
    output : salida
    '''
    print(arcpy.Describe(polyline))
    spatial_ref = arcpy.Describe(polyline).spatialReference
    mem_point = arcpy.CreateFeatureclass_management("in_memory", "mem_point", "POINT", "", "DISABLED", "DISABLED", spatial_ref)
    arcpy.AddField_management(mem_point, "LineOID", "LONG")
    arcpy.AddField_management(mem_point, "Value", "FLOAT")
    result = arcpy.GetCount_management(polyline)
    features = int(result.getOutput(0))

    search_fields = ["SHAPE@", "OID@"]
    insert_fields = ["SHAPE@", "LineOID", "Value"]

    reverse_line = False
    if start_from == "END":
        reverse_line = True

    with arcpy.da.SearchCursor(polyline, (search_fields)) as search:
        with arcpy.da.InsertCursor(mem_point, (insert_fields)) as insert:
            for row in search:
                try:
                    line_geom = row[0]
                    length = float(line_geom.length)
                    count = distance
                    oid = str(row[1])
                    start = arcpy.PointGeometry(line_geom.firstPoint)
                    end = arcpy.PointGeometry(line_geom.lastPoint)
                    if reverse_line == True:
                       reversed_points = []
                       for part in line_geom:
                           for p in part:
                               reversed_points.append(p)
                       reversed_points.reverse()
                       array = arcpy.Array([reversed_points])
                       line_geom = arcpy.Polyline(array, spatial_ref)
                    if choice == "DISTANCE":
                        point = line_geom.positionAlongLine(count, False)
                        insert.insertRow((point, oid, count))
                    elif choice == "PERCENTAGE":
                        point = line_geom.positionAlongLine(count, True)
                        insert.insertRow((point, oid, count))
                    elif choice == "INTERVAL BY DISTANCE":
                        while count <= length:
                            point = line_geom.positionAlongLine(count, False)
                            insert.insertRow((point, oid, count))
                            count += distance
                    elif choice == "INTERVAL BY PERCENTAGE":
                        percentage = float(count * 100.0)
                        total_runs = int(100.0 / percentage)

                        run = 1
                        while run <= total_runs:
                            current_percentage = float((percentage * run) / 100.0)
                            point = line_geom.positionAlongLine(current_percentage, True)
                            insert.insertRow((point, oid, current_percentage))
                            run += 1

                    elif choice == "START/END POINTS":
                        insert.insertRow((start, oid, 0))
                        insert.insertRow((end, oid, length))

                    if end_points == "START":
                        insert.insertRow((start, oid, 0))
                    elif end_points == "END":
                        insert.insertRow((end, oid, length))
                    elif end_points == "BOTH":
                        insert.insertRow((start, oid, 0))
                        insert.insertRow((end, oid, length))
                    arcpy.SetProgressorPosition()
                except Exception as e:
                    arcpy.AddMessage(str(e.message))
    line_keyfield = str(arcpy.ListFields(polyline, "", "OID")[0].name)
    mem_point_fl = arcpy.MakeFeatureLayer_management(mem_point, "Points_memory")
    arcpy.AddJoin_management(mem_point_fl, "LineOID", polyline, line_keyfield)
    if "in_memory" in output:
        arcpy.SetParameter(8, mem_point_fl)
    else:
        arcpy.CopyFeatures_management(mem_point_fl, output)
        arcpy.Delete_management(mem_point)
        arcpy.Delete_management(mem_point_fl)

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
