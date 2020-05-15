rm(list=ls())
require("raster")
require("ncdf4")
require("sf")
require("ggplot2")
require("mapview")
require("dplyr")
require("stringr")
require("dplyr")
require("stringr")
require("xts")
require("reshape2")

Resamplear = function(objetivo, plantilla){
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

runoff = function(PP, CN, ndias){
  # CREAR CAUDAL A PARTIR DE NC
  S = (25400 / CN) - 254
  IA = 0.2*S
  Q = (PP - IA)^2 / (PP - IA + S)
  Q2 = (Q * 10000)/ (ndias*24*60*60*1000)
  # CAUDAL MEDIA
  # Q3 = mean(Q2)
  # PERSISTENCIA AL 95%
  # Q3 = calc(Q2, fun=function(x) quantile(x, .05, na.rm=TRUE))
  return(Q2)
}
dates = seq(as.Date("1981-01-01"), as.Date("2016-12-31"), by="month")
numberOfDays <- function(date) {
  m <- format(date, format="%m")
  while (format(date, format="%m") == m) { date <- date + 1  }
  return(as.integer(format(date - 1, format="%d")))
}

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

setwd("E:/2020/uni")
# cn = raster("data/raster/ra_cn_cs_max.tif")
dem_total = raster("data/raster/SRTM_90.tif")
pisco = brick("data/raster/pisco_clip.tif")
cn_cs_min = raster("data/raster/ra_cn_cs_min.tif")
cn_ch_max = raster("data/raster/ra_cn_ch_max.tif")
cn_cs_max = raster("data/raster/ra_cn_cs_max.tif")
cn_cn_max = raster("data/raster/ra_cn_cn_max.tif")
area_cuencas = st_read("data/shp/gpo_cuencas_eval.shp")
area_cuencas_wgs = st_transform(area_cuencas, crs = proj4string(pisco))
area_cuencas_utm = st_transform(area_cuencas, crs = proj4string(cn_cs_min))


crear_caudales = function(i){
  i = 6
  cn1 = cn_cs_min
  cn2 = cn_cs_max
  cn3 = cn_ch_max
  cn4 = cn_cn_max

  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("cuencas5/", i)
  
  pathcn   = paste0(path_basin, "/ra_cn", ".tif")
  pathdem  = paste0(path_basin, "/ra_dem", ".tif")
  
  if(!file.exists("cuencas5")) dir.create("cuencas5")
  dir.create(path_basin)
  dir.create(paste0(path_basin, "/shp"))
  dir.create(paste0(path_basin, "/xls"))
  dir.create(paste0(path_basin, "/img"))
  
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = proj4string(pisco)))
  
  pisco_month_clip = crop(pisco, buf_wgs) %>% mask(buf_wgs)
  cn_clip_1 = crop(cn1, buf) %>% mask(buf)
  cn_clip_resam_1 = Resamplear(cn_clip_1, pisco_month_clip[[1]])
  
  cn_clip_2 = crop(cn2, buf) %>% mask(buf)
  cn_clip_resam_2 = Resamplear(cn_clip_2, pisco_month_clip[[1]])
  
  cn_clip_3 = crop(cn3, buf) %>% mask(buf)
  cn_clip_resam_3 = Resamplear(cn_clip_3, pisco_month_clip[[1]])
  
  cn_clip_4 = crop(cn4, buf) %>% mask(buf)
  cn_clip_resam_4 = Resamplear(cn_clip_4, pisco_month_clip[[1]])
  
  
  for(x in 1:432){
    if(x %% 12 %in% c(1,10,11,0)){
      cn = cn_clip_resam_1
    }else if(x %% 12 %in% c(2,3,6)){
      cn = cn_clip_resam_2
    }else if(x %% 12 %in% c(4,5)){
      cn = cn_clip_resam_3
    }else if(x %% 12 %in% c(7,8,9)){
      cn = cn_clip_resam_4
    }
    cat(x, ": mes ", x %% 12)
    q = runoff(pisco_month_clip[[x]], cn, numberOfDays(dates[x])) %>% Resamplear(cn_clip_1)
    writeRaster(q, 
                paste0(path_basin, "/q_", str_pad(as.character(x), 3, pad = "0") ,".tif"), 
                overwrite = TRUE)
  }
}

path_basin = "E:/2020/uni/cuencas5/6"
# Q3 = calc(Q2, fun=function(x) quantile(x, .05, na.rm=TRUE))
Q = stack(list.files("E:/2020/uni/cuencas5/6", pattern = "^facc_(.*)tif$", full.names = T))

q_st = c()
for (mes in c(seq(1,11), 0)){
  l = c()
  for(i in 1:432){
    if(i %% 12 == mes){
      l = c(l, Q[[i]])
    }
  }
  lista = stack(l)
  # lista = calc(stack(l), fun=function(x) quantile(x, .05, na.rm=TRUE))
  # writeRaster(lista, 
  #             paste0(path_basin, "/q_", str_pad(as.character(mes), 2, pad = "0") ,".tif"), 
  #             overwrite = TRUE)
  q_st = c(q_st, lista)
  print(mes)
}

annos = seq(as.Date("1981-01-01"),as.Date("2016-01-01"),by="year")
# coord = data.frame(x=-122729,y=9424388) # Piura - Sanchez Cerro
coord = data.frame(x=43144,y=9195485) # Jequetepeque - QN-603
xy = SpatialPoints(coordinates(coord))

serie_01 = t(extract(q_st[[1]], xy))
serie_02 = t(extract(q_st[[2]], xy))
serie_03 = t(extract(q_st[[3]], xy))
serie_04 = t(extract(q_st[[4]], xy))
serie_05 = t(extract(q_st[[5]], xy))
serie_06 = t(extract(q_st[[6]], xy))
serie_07 = t(extract(q_st[[7]], xy))
serie_08 = t(extract(q_st[[8]], xy))
serie_09 = t(extract(q_st[[9]], xy))
serie_10 = t(extract(q_st[[10]], xy))
serie_11 = t(extract(q_st[[11]], xy))
serie_12 = t(extract(q_st[[12]], xy))

df = data.frame(serie_01,serie_02,serie_03,serie_04,serie_05,serie_06,serie_07,serie_08,serie_09,serie_10,serie_11,serie_12)
row.names(df) = annos
names(df) = 1:12

df_xts = as.xts(df)

df2 = melt(df)
df2["fecha"] = annos

df3 = df2 %>%
  mutate(x = paste0(format(fecha, "%Y"), "-", str_pad(variable, 2, pad = "0"), "-01")) %>%
  select(c("x", "value")) %>%
  arrange(x)

write.csv(df, "E:/2020/uni/cuencas5/6/xls/datos_multianuales.csv")
write.csv(df3, "E:/2020/uni/cuencas5/6/xls/serie_QN_603.csv")


# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

q_month = function(Q){
  q_st = c()
  for (mes in c(seq(1,11), 0)){
    l = c()
    for(i in 1:432){
      if(i %% 12 == mes){
        l = c(l, Q[[i]])
      }
    }
    lista = calc(stack(l), fun=function(x) quantile(x, .05, na.rm=TRUE))
    q_st = c(q_st, lista)
    print(mes)
  }
  return(q_st)
}


Q = stack(list.files("E:/2020/uni/cuencas5/1", pattern = "^facc_(.*)tif$", full.names = T))
q_quantil = q_month(Q)

for(i in 1:12){
  writeRaster(q_quantil[[i]], paste0("E:/2020/uni/cuencas5/1/facc_", paste0(str_pad(i, 2, pad = "0")), ".tif"))
}


