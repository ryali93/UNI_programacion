rm(list=ls())
install.packages("rgdal")
install.packages("raster")
install.packages("sf")
install.packages("ncdf4")
require("raster")
require("ncdf4")
require("sf")

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
pp_mean_month = function(PP){
  pp_st = c()
  for (mes in seq(0,11)){
    l = c()
    for(i in 1:432){
      if(i %% 12 == mes){
        l = c(l, PP[[i]])
      }
    }
    lista = stack(l)
    # PRECIPITACION MEDIA
    # p = mean(lista)
    # PERSISTENCIA AL 95%
    p = calc(lista, fun=function(x) quantile(x, .05, na.rm=TRUE))
    # writeRaster(p, salida, overwrite=T)
    pp_st = c(pp_st, p)
  }
  pp_st = stack(pp_st)
  return(pp_st)
}
runoff = function(PP, CN){
  # CREAR CAUDAL A PARTIR DE NC
  S = (25400 / CN) - 254
  IA = 0.2*S
  Q = (PP - IA)^2 / (PP - IA + S)
  Q2 = (Q * 10000)/ (30*24*60*60*1000) 
  return(Q2)
}

setwd("E:/2020/uni")

cn = raster("data/raster/ra_cn.tif")
dem_total = raster("data/raster/SRTM_90.tif")
area_cuencas = st_read("data/shp/gpo_cuencas_eval.shp")
pisco = brick("E:/BASE_DATOS/PISCO/PISCOpm21.nc")

# dem_utm = Resamplear(dem_total, cn)
area_cuencas_wgs = st_transform(area_cuencas, crs = proj4string(pisco))
area_cuencas_utm = st_transform(area_cuencas, crs = proj4string(cn))

# faltan del 4to en adelante
for(i in seq(nrow(area_cuencas_utm))){
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("process/", i)
  pathdem  = paste0(path_basin, "/ra_dem.tif")
  pathfdir = paste0(path_basin, "/ra_fdir.tif")
  pathppst = paste0(path_basin, "/ra_ppst.tif")
  pathqst  = paste0(path_basin, "/ra_qst.tif")
  pathcn   = paste0(path_basin, "/ra_cn.tif")
  
  dir.create(path_basin)
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = proj4string(pisco)))
  
  # plantilla res=100 | crs=utm8
  cn_clip = mask(crop(cn, buf), buf)
  
  dem_clip  = Resamplear(mask(crop(dem_total, buf_wgs), buf_wgs), cn_clip)
  pp_clip  = mask(crop(pisco, buf_wgs), buf_wgs)
  
  pp_st = Resamplear(pp_mean_month(pp_clip), cn_clip)
  q_st = runoff(pp_st, cn)
  
  # guardar archivos
  writeRaster(dem_clip, pathdem, overwrite=TRUE)
  terrain(dem_clip, opt="flowdir", unit="radians", neighbors=8, filename=pathfdir)
  writeRaster(pp_st, pathppst, overwrite=TRUE)
  writeRaster(q_st, pathqst, overwrite=TRUE)
  
  writeRaster(q_st[[12]], paste0(path_basin, "/q_01_min.tif"))
  writeRaster(q_st[[1]], paste0(path_basin, "/q_02_min.tif"))
  writeRaster(q_st[[2]], paste0(path_basin, "/q_03_min.tif"))
  writeRaster(q_st[[3]], paste0(path_basin, "/q_04_min.tif"))
  writeRaster(q_st[[4]], paste0(path_basin, "/q_05_min.tif"))
  writeRaster(q_st[[5]], paste0(path_basin, "/q_06_min.tif"))
  writeRaster(q_st[[6]], paste0(path_basin, "/q_07_min.tif"))
  writeRaster(q_st[[7]], paste0(path_basin, "/q_08_min.tif"))
  writeRaster(q_st[[8]], paste0(path_basin, "/q_09_min.tif"))
  writeRaster(q_st[[9]], paste0(path_basin, "/q_10_min.tif"))
  writeRaster(q_st[[10]], paste0(path_basin, "/q_11_min.tif"))
  writeRaster(q_st[[11]], paste0(path_basin, "/q_12_min.tif"))
}

