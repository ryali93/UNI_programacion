from settings import *
from s02_generar_flowacc_mensual import *
from s04_potencial_hidrologico import *

BASE_DIR = r'E:\2020\UNI'
PROCESS_DIR = os.path.join(BASE_DIR, "process")

path_cuenca = "6"
RASTER_DIR = os.path.join(PROCESS_DIR, path_cuenca)
SHP_DIR = os.path.join(PROCESS_DIR, path_cuenca, "shp")
XLS_DIR = os.path.join(PROCESS_DIR, path_cuenca, "xls")
