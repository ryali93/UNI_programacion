import subprocess
import sys
import os

PROCESO = "process_cs_min"

listidcuencas = range(1,11)
for idcuenca in listidcuencas:
    print "Corriendo la cuenca : {}".format(idcuenca)
    proceso = subprocess.Popen("python s06_main.py {} {}".format(PROCESO, idcuenca), shell=True, stderr=subprocess.PIPE)
    errores = proceso.stderr.read()
    errores_print = '{}'.format(errores)
    print errores_print