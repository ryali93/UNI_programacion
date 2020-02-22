rm(list=ls())

# Cargar librerías
require("raster")
require("ncdf4")
require("sf")
require("ggplot2")
require("mapview")
require("dplyr")
require("stringr")

setwd("E:/2020/uni")

# ESCENARIO
ESCENARIO = "ra_cn_cs_min"
PROCESO = "process_cs_min"

# Sistemas de coordenadas
crs_wgs84 = "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"
crs_utm18s = "+proj=utm +zone=18 +south +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"

# Variables locales
cn = raster(paste0("data/raster/", ESCENARIO, ".tif"))
dem_total = raster("data/raster/SRTM_90.tif")
area_cuencas = st_read("data/shp/gpo_cuencas_eval.shp")
area_cuencas_utm = st_transform(area_cuencas, crs = crs_utm18s)

# Lectura de caudales totales
files_q = list.files(paste0("data/raster/", ESCENARIO), full.names = T)

for(i in 1:10){
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0(PROCESO, "/", i)
  pathcn   = paste0(path_basin, "/ra_cn.tif")
  pathdem  = paste0(path_basin, "/ra_dem.tif")
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = crs_wgs84))
  
  dir.create(path_basin)
  dir.create(paste0(path_basin, "/shp"))
  dir.create(paste0(path_basin, "/xls"))
  dir.create(paste0(path_basin, "/img"))
  
  if(!file.exists(pathcn)){
    cn_clip = mask(crop(cn, buf), buf)
    writeRaster(cn_clip, pathcn, overwrite=TRUE)
  }else{
    cn_clip = raster(pathcn)
  }
  
  if(!file.exists(pathdem)){
    dem_clip  = Resamplear(mask(crop(dem_total, buf_wgs), buf_wgs), cn_clip)
    writeRaster(dem_clip, pathdem, overwrite=TRUE)
  }
  
  mes = 0
  for(f in files_q){
    print(f)
    mes = mes + 1
    path_q_clip = paste0(path_basin, "/", str_pad(mes, 2, pad = "0"), ".tif")
    q = raster(f)
    q_clip = mask(crop(raster(f), buf), buf)
    writeRaster(q_clip, path_q_clip, overwrite=T)
  }
}