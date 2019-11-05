library(raster)

# cAMBIANDO ENTORNO DE TRABAJO
setwd("E:/2019/UNI/data")

# REGISTRANDO VARIABLES
p = brick("raster/piscoclip.tif")
dem  = raster("raster/dem.tif")
fdir = raster("raster/flowdir.tif")
cn = raster("raster/cn_area.tif")
area = shapefile("shp/gpo_area_n.shp")
cuencas = shapefile("shp/gpo_cuencas.shp")

p_clip = crop(p, area)
dem_clip = crop(dem, area)
fdir_clip = crop(fdir, area)

# CARGANDO FUNCION PARA NORMALIZAR DATOS
Resamplear<-function(objetivo, plantilla){
  #Verificar la proyección
  if(proj4string(plantilla)!=proj4string(objetivo)){
    print("las proyecciones son diferentes")
    objetivo_proj<-projectRaster(objetivo,crs=CRS(proj4string(plantilla)))
    # print(proj4string(hasta_proj))
  }else{
    print("Tienen la misma proyeccion")
    objetivo_proj<-objetivo
  }
  #Verificando Extensión
  if(extent(plantilla)!=extent(objetivo_proj)){
    print("las resoluciones son diferentes")
    objetivo_resam<-resample(objetivo_proj,plantilla)
  }else{
    print("las resoluciones son las mismas")
    objetivo_resam<-objetivo_proj
  }
  return(objetivo_resam)
}

# writeRaster(p_resamp, "raster/pisco_area.nc", overwrite=T)
writeRaster(dem_clip, "raster/dem_area.tif", overwrite=T)
writeRaster(fdir_clip, "raster/fdir_area.tif", overwrite=T)
writeRaster(cn_resamp, "raster/cn_area_n.tif", overwrite=T)

##############################################################################
############################ GENERACIÓN DE CAUDALES  #########################
##############################################################################

# CARGAR PISCO PRECIPITACION
p_area = brick("raster/pisco_area.gri")

p_resamp = Resamplear(p_clip, dem_clip)
cn_resamp = Resamplear(cn, dem_clip)
cn_resamp = raster("raster/cn_area_n.tif")
# GENERAR PRECIPITACION PROMEDIO MENSUAL POR MESES
pp_mean_month = function(mes, salida){
  l = c()
  for(i in 1:432){
    if(i %% 12 == mes){
      l = c(l, p_resamp[[i]])
    }
  }
  lista = stack(l)

  # PERSISTENCIA AL 95%
  p = calc(lista, fun=function(x) quantile(x, .05, na.rm=TRUE))

  # CREAR CAUDAL A PARTIR DE NC
  S = (25400 / cn_resamp) - 254
  IA = 0.2*S
  Q = (p - IA)^2 / (p - IA + S)
  Q2 = (Q * 10000)/ (30*60*60*1000)
  writeRaster(Q2, salida, overwrite=T)
}

# Caudales espacializados
pp_mean_month(1, "raster/q_area_01.tif")
pp_mean_month(2, "raster/q_area_02.tif")
pp_mean_month(3, "raster/q_area_03.tif")
pp_mean_month(4, "raster/q_area_04.tif")
pp_mean_month(5, "raster/q_area_05.tif")
pp_mean_month(6, "raster/q_area_06.tif")
pp_mean_month(7, "raster/q_area_07.tif")
pp_mean_month(8, "raster/q_area_08.tif")
pp_mean_month(9, "raster/q_area_09.tif")
pp_mean_month(10, "raster/q_area_10.tif")
pp_mean_month(11, "raster/q_area_11.tif")
pp_mean_month(0, "raster/q_area_12.tif")

##############################################################################
########################### CREAR CAUDALES   #################################
##############################################################################

# ******************************************
# Realizar funcion que llame a reticulate para usar flowaccumulation
# ******************************************

# q_cummulate = function(raster_facc, umbral, salida){
#   facc[facc > umbral] = 1
#   facc[facc <= umbral] = 0
#   writeRaster(facc, salida, overwrite=T) # "raster/eje_rio.tif"
# }



##############################################################################
############################ CREAR CAUDALES ##################################
##############################################################################


# Se tiene
# precipiptacion, dem, caudales

# Se requiere
# Generar ejes de rio a partir del flowacc (lineas)
# Dividir las lineas y generar puntos (1km)
# Buffer de 3 km
# Generar curvas de nivel para cada uno de esos puntos


# Se requiere
# Definir umbral de caudales para rios
# Dividir las lineas y generar puntos (1km)
# Buffer de 1 km
# * Matriz de costos con Flow direction
# 1 punto por area de evaluacion


##############################################################################
############################ CREAR CAUDALES ##################################
##############################################################################

library(sf)
library(raster)
library(dplyr)

dem  = raster("raster/dem_area_17s.tif")
flowdir = raster("raster/fdir_area.tif")
flowdir = projectRaster(flowdir, crs=crs(areas))
areas = st_read("shp/areas_test.shp")

plot(crop(flowdir, areas[3,]))
plot(areas[3,], add = T)


areadir = crop(flowdir, areas[3,])
plot(areadir)
