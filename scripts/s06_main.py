import sys
import os

# BASE_DIR = r'E:\2020\UNI'
# PROCESS_DIR = os.path.join(BASE_DIR, "process")
#
# path_cuenca = "6"
# RASTER_DIR = os.path.join(PROCESS_DIR, path_cuenca)
# SHP_DIR = os.path.join(PROCESS_DIR, path_cuenca, "shp")
# XLS_DIR = os.path.join(PROCESS_DIR, path_cuenca, "xls")



# path_cuenca = '{}'.format(sys.argv[1])
#
# BASE_DIR = r'E:\2020\UNI'
# PROCESS_DIR = os.path.join(BASE_DIR, "process")
#
# RASTER_DIR = os.path.join(PROCESS_DIR, path_cuenca)
# SHP_DIR = os.path.join(PROCESS_DIR, path_cuenca, "shp")
# XLS_DIR = os.path.join(PROCESS_DIR, path_cuenca, "xls")

from settings import *
import s02_generar_flowacc_mensual
import s04_potencial_hidrologico

s02_generar_flowacc_mensual.main()
s04_potencial_hidrologico.main()