rm(list=ls())
install.packages("rgdal")
install.packages("raster")
install.packages("sf")
install.packages("ncdf4")
install.packages("ggplot2")
install.packages("mapview")
install.packages("gdalcubes")
install.packages("stars")
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

#------------------------------------------------------------------------
# CARGANDO FUNCION PARA NORMALIZAR DATOS
Resamplear = function(objetivo, plantilla){
  #Verificar la proyecci√≥n
  if(proj4string(plantilla)!=proj4string(objetivo)){
    print("las proyecciones son diferentes")
    objetivo_proj<-projectRaster(objetivo,crs=CRS(proj4string(plantilla)))
    # print(proj4string(hasta_proj))
  }else{
    print("Tienen la misma proyeccion")
    objetivo_proj<-objetivo
  }
  #Verificando Extensi√≥n
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
    # p = calc(lista, fun=function(x) quantile(x, .05, na.rm=TRUE))
    # writeRaster(p, salida, overwrite=T)
    pp_st = c(pp_st, p)
  }
  pp_st = stack(pp_st)
  return(pp_st)
}

# "1","Cuenca Piura"              --> "Sanchez Cerro 2" (21)
# "2","Cuenca Chira"              --> "QN-2701" (17)
# "3","Cuenca Motupe"             --> "Puchaca" (6)
# "4","Cuenca Chancay-Lambayeque" --> "QN-603" (15), "QN-606" (16)
# "5","Cuenca ZaÒa"               --> "Batan" (5)
# "6","Cuenca Jequetepeque"       --> "QN-501" (14)
# "7","Cuenca Vir˙"               --> "Huacopongo" (8)
# "8","Cuenca Santa"              --> "Condorcerro" (9), "QN-403" (12)
# "9","Cuenca Pativilca"          --> "Yanapampa" (10), "QN-304" (18)
# "10","Cuenca Moche"             --> "Quirihuac" (7)

## ------------------------------------------------------------------ ##

##############################
##############################
# ********* GRAFICOS *********
##############################
##############################

shp = sf::st_read("E:/2020/uni/data/shp/gpt_estaciones.shp")
xls = read.csv("E:/2020/uni/data/xls/series_estaciones.csv", sep = ";")

# cuencas = sf::st_read("E:/2020/uni/data/shp/gpo_cuencas_eval.shp")
# mapview(list(shp, cuencas))


proceso = "process_ch_min"
df = data.frame(seq(1,12))
extract_data_serie = function(i, row){
  facc = stack(list.files(paste0("E:/2020/uni/", proceso, "/", as.character(i)), pattern = "(facc_[0,1][0-9]).tif$", full.names = T))
  e = t(as.data.frame(extract(facc, shp[row,])))
  if (length(row) == 1){
    colnames(e) = paste0("C_", as.character(i))
    rownames(e) = seq(1,12)
  }else{
    colnames(e) = c(paste0("C_", as.character(i)), paste0("C_", as.character(i),"_1"))
    rownames(e) = seq(1,12)
  }
  df = cbind(df, e)
  return(df)
}

df = extract_data_serie(1, 21)
df = extract_data_serie(2, 17)
df = extract_data_serie(3, 6)
df = extract_data_serie(4, c(15, 16))
df = extract_data_serie(5, 5)
df = extract_data_serie(6, 14)
df = extract_data_serie(7, 8)
df = extract_data_serie(8, c(9, 12))
df = extract_data_serie(9, c(10, 18))
df = extract_data_serie(10, 7)
colnames(df)[1] = "mes"

valoresC_1 = c(as.vector(df$C_1), as.vector(xls$SanchezCerro))        # "1","Cuenca Piura"
valoresC_2 = c(as.vector(df$C_2), as.vector(xls$QN2701))              # "2","Cuenca Chira"
valoresC_3 = c(as.vector(df$C_3), as.vector(xls$Puchaca))             # "3","Cuenca Motupe"
valoresC_4 = c(as.vector(df$C_4), as.vector(xls$QN603))               # "4","Cuenca Chancay-Lambayeque"
valoresC_4_1 = c(as.vector(df$C_4_1), as.vector(xls$QN606))           # "4","Cuenca Chancay-Lambayeque"
valoresC_5 = c(as.vector(df$C_5), as.vector(xls$Batan))               # "5","Cuenca ZaÒa"
valoresC_6 = c(as.vector(df$C_6), as.vector(xls$QN501))               # "6","Cuenca Jequetepeque"
valoresC_7 = c(as.vector(df$C_7), as.vector(xls$Huacapongo))          # "7","Cuenca Vir˙"
valoresC_8 = c(as.vector(df$C_8), as.vector(xls$Condorcerro))         # "8","Cuenca Santa"
valoresC_8_1 = c(as.vector(df$C_8_1), as.vector(xls$QN403))           # "8","Cuenca Santa"
valoresC_9 = c(as.vector(df$C_9), as.vector(xls$Yanapampa))           # "9","Cuenca Pativilca"
valoresC_9_1 = c(as.vector(df$C_9_1), as.vector(xls$QN304))           # "9","Cuenca Pativilca"
valoresC_10 = c(as.vector(df$C_10), as.vector(xls$Quirihuac))         # "10","Cuenca Moche"


dfC_1 = data.frame(generado=as.vector(df$C_1), estacion=as.vector(xls$SanchezCerro))
dfC_2 = data.frame(generado=as.vector(df$C_2), estacion=as.vector(xls$QN2701))
dfC_3 = data.frame(generado=as.vector(df$C_3), estacion=as.vector(xls$Puchaca))
dfC_4 = data.frame(generado=as.vector(df$C_4), estacion=as.vector(xls$QN603))
dfC_4_1 = data.frame(generado=as.vector(df$C_4_1), estacion=as.vector(xls$QN606))
dfC_5 = data.frame(generado=as.vector(df$C_5), estacion=as.vector(xls$Batan))
dfC_6 = data.frame(generado=as.vector(df$C_6), estacion=as.vector(xls$QN501))
dfC_7 = data.frame(generado=as.vector(df$C_7), estacion=as.vector(xls$Huacapongo))
dfC_8 = data.frame(generado=as.vector(df$C_8), estacion=as.vector(xls$Condorcerro))
dfC_8_1 = data.frame(generado=as.vector(df$C_8_1), estacion=as.vector(xls$QN403))
dfC_9 = data.frame(generado=as.vector(df$C_9), estacion=as.vector(xls$Yanapampa))
dfC_9_1 = data.frame(generado=as.vector(df$C_9_1), estacion=as.vector(xls$QN304))
dfC_10 = data.frame(generado=as.vector(df$C_10), estacion=as.vector(xls$Quirihuac))

write.csv(dfC_1, paste0(proceso,"/1/img/dfC_1.csv"))
write.csv(dfC_2, paste0(proceso,"/2/img/dfC_2.csv"))
write.csv(dfC_3, paste0(proceso,"/3/img/dfC_3.csv"))
write.csv(dfC_4, paste0(proceso,"/4/img/dfC_4.csv"))
write.csv(dfC_4_1, paste0(proceso,"/4/img/dfC_4_1.csv"))
write.csv(dfC_5, paste0(proceso,"/5/img/dfC_5.csv"))
write.csv(dfC_6, paste0(proceso,"/6/img/dfC_6.csv"))
write.csv(dfC_7, paste0(proceso,"/7/img/dfC_7.csv"))
write.csv(dfC_8, paste0(proceso,"/8/img/dfC_8.csv"))
write.csv(dfC_8_1, paste0(proceso,"/8/img/dfC_8_1.csv"))
write.csv(dfC_9, paste0(proceso,"/9/img/dfC_9.csv"))
write.csv(dfC_9_1, paste0(proceso,"/9/img/dfC_9_1.csv"))
write.csv(dfC_10, paste0(proceso,"/10/img/dfC_10.csv"))




grafico = function(datos, nombre){
  val_max = (as.integer(max(datos, na.rm = T) / 20) + 1) * 20
  mes = seq(as.Date('2019-01-01'), as.Date('2019-12-01'), by = 'month')
  grupo = c(rep("flowacc", 12), rep("estacion", 12))
  dataf = data.frame(mes, datos, grupo)
  Sys.setlocale(category = 'LC_ALL', locale = 'english')
  ploteo = ggplot(dataf, aes(x=mes, y=datos, shape = grupo, col = grupo)) +
    geom_line(size = 1) + theme_bw() + 
    theme(plot.title = element_text(face='bold')) +
    scale_colour_manual(values = c('blue', 'red')) +
    ylab(label = 'Q [m3/s]') +  xlab(label = '') +
    ggtitle(nombre, subtitle = 'from 1981 to 2017 - PP 95% - CN min') + 
    theme(plot.title    = element_text(size=16),
          plot.subtitle = element_text(size=16),
          axis.text.x   = element_text(size=12),
          axis.text.y   = element_text(size=12),
          axis.title    = element_text(size=17)) +
    scale_x_date(date_labels = '%b', breaks = '1 month') +
    scale_y_continuous(breaks = seq(0, val_max, 20), limits = c(0, val_max)) +
    geom_point(size = 3.5)
  return(ploteo)
}

graph_1 = grafico(valoresC_1, "Cuenca Piura")
graph_2 = grafico(valoresC_2, "Cuenca Chira")
graph_3 = grafico(valoresC_3, "Cuenca Motupe")
graph_4 = grafico(valoresC_4, "Cuenca Chancay-Lambayeque")
graph_4_1 = grafico(valoresC_4_1, "Cuenca Chancay-Lambayeque")
graph_5 = grafico(valoresC_5, "Cuenca ZaÒa")
graph_6 = grafico(valoresC_6, "Cuenca Jequetepeque")
graph_7 = grafico(valoresC_7, "Cuenca Vir˙")
graph_8 = grafico(valoresC_8, "Cuenca Santa")
graph_8_1 = grafico(valoresC_8_1, "Cuenca Santa")
graph_9 = grafico(valoresC_9, "Cuenca Pativilca")
graph_9_1 = grafico(valoresC_9_1, "Cuenca Pativilca")
graph_10 = grafico(valoresC_10, "Cuenca Moche")

ggsave("process_cs_min/1/img/comparacion.png", plot = graph_1,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/2/img/comparacion.png", plot = graph_2,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/3/img/comparacion.png", plot = graph_3,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/4/img/comparacion.png", plot = graph_4,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/4/img/comparacion_1.png", plot = graph_4_1,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/5/img/comparacion.png", plot = graph_5,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/6/img/comparacion.png", plot = graph_6,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/7/img/comparacion.png", plot = graph_7,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/8/img/comparacion.png", plot = graph_8,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/8/img/comparacion_1.png", plot = graph_8_1,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/9/img/comparacion.png", plot = graph_9,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/9/img/comparacion_1.png", plot = graph_9_1,width = 250, height = 180, units = "mm", dpi = 300)
ggsave("process_cs_min/10/img/comparacion.png", plot = graph_10,width = 250, height = 180, units = "mm", dpi = 300)

## ------------------------------------------------------------------ ##

pp_month = function(PP){
  pp_st = c()
  for (mes in c(seq(1,11), 0)){
    l = c()
    for(i in 1:432){
      if(i %% 12 == mes){
        l = c(l, PP[[i]])
      }
    }
    lista = stack(l)
    pp_st = c(pp_st, lista)
  }
  return(pp_st)
}


runoff = function(PP, CN){
  # CREAR CAUDAL A PARTIR DE NC
  S = (25400 / CN) - 254
  IA = 0.2*S
  Q = (PP - IA)^2 / (PP - IA + S)
  Q2 = (Q * 10000)/ (30*24*60*60*1000)
  # CAUDAL MEDIA
  # Q3 = mean(Q2)
  # PERSISTENCIA AL 95%
  # Q3 = calc(Q2, fun=function(x) quantile(x, .05, na.rm=TRUE))
  return(Q2)
}


setwd("E:/2020/uni")
# cn = raster("data/raster/ra_cn_cs_max.tif")
dem_total = raster("data/raster/SRTM_90.tif")
pisco = brick("data/raster/pisco_clip.tif")
area_cuencas = st_read("data/shp/gpo_cuencas_eval.shp")
area_cuencas_wgs = st_transform(area_cuencas, crs = proj4string(pisco))
area_cuencas_utm = st_transform(area_cuencas, crs = proj4string(cn_cs_max))

cn_cs_max = raster("data/raster/ra_cn_cs_max.tif")
cn_ch_min = raster("data/raster/ra_cn_ch_min.tif")
cn_cs_min = raster("data/raster/ra_cn_cs_min.tif")
cn_cn_min = raster("data/raster/ra_cn_cn_min.tif")

crear_caudales = function(i, cn){
  i = 1
  cn = cn_cs_max
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("cuencas4/", i)
  
  pathcn   = paste0(path_basin, "/ra_cn", ".tif")
  pathdem  = paste0(path_basin, "/ra_dem", ".tif")
  
  if(!file.exists("cuencas4")) dir.create("cuencas4")
  dir.create(path_basin)
  dir.create(paste0(path_basin, "/shp"))
  dir.create(paste0(path_basin, "/xls"))
  dir.create(paste0(path_basin, "/img"))
  
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = proj4string(pisco)))
  
  pisco_month_clip = crop(pisco, buf_wgs) %>% mask(buf_wgs) %>% pp_month()
  cn_clip = crop(cn, buf) %>% mask(buf)
  cn_clip_resam = Resamplear(cn_clip, pisco_month_clip[[1]])
  
  for(x in 1:12){
    q = runoff(pisco_month_clip[[x]], cn_clip_resam) %>% Resamplear(cn_clip)
    writeRaster(q, 
                paste0(path_basin, "/q_", str_pad(as.character(x), 2, pad = "0") ,".tif"), 
                overwrite = TRUE)
  }
  
  # plantilla res=100 | crs=utm18
  if(!file.exists(pathcn)){
    writeRaster(cn_clip, pathcn, overwrite=TRUE)
  }
  
  if(!file.exists(pathdem)){
    dem_clip  = mask(crop(dem_total, buf_wgs), buf_wgs) %>% Resamplear(cn_clip)
    writeRaster(dem_clip, pathdem, overwrite=TRUE)
  }
}


crear_caudales(1, cn_cs_max)
crear_caudales(5, cn_cs_max)
crear_caudales(6, cn_cs_max)
crear_caudales(7, cn_cs_max)
crear_caudales(2, cn_ch_min)
crear_caudales(8, cn_ch_min)
crear_caudales(9, cn_ch_min)
crear_caudales(3, cn_cs_min)
crear_caudales(10, cn_cs_min)
crear_caudales(4, cn_cn_min)



# --------------------------------------------------------------------------------

setwd("E:/2020/uni")
cs_max_st = stack(list.files("data/raster/q05/cs_max", full.names = T))

cortar_caudales = function(i, cn){
  i = 6
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("cuencas3/", i)
  
  if(!file.exists("cuencas3")) dir.create("cuencas3")
  dir.create(path_basin)
  dir.create(paste0(path_basin, "/shp"))
  dir.create(paste0(path_basin, "/xls"))
  dir.create(paste0(path_basin, "/img"))
  
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  
  q_month_clip = crop(cs_max_st, buf) %>% mask(buf)
  
  for(x in 1:12){
    writeRaster(q_month_clip[[x]], 
                paste0(path_basin, "/q_", str_pad(as.character(x), 2, pad = "0") ,".tif"), 
                overwrite = TRUE)
  }
}


crear_caudales(1, cn_cs_max)
crear_caudales(5, cn_cs_max)
crear_caudales(6, cn_cs_max)
crear_caudales(7, cn_cs_max)
crear_caudales(2, cn_ch_min)
crear_caudales(8, cn_ch_min)
crear_caudales(9, cn_ch_min)
crear_caudales(3, cn_cs_min)
crear_caudales(10, cn_cs_min)
crear_caudales(4, cn_cn_min)



# --------------------------------------------------------------------------------
# CAUDALES SERIE COMPLETA


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


crear_caudales = function(i, cn1, cn2){
  i = 1
  cn1 = cn_cs_min
  cn2 = cn_cn_max
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("cuencas4/", i)
  
  pathcn   = paste0(path_basin, "/ra_cn", ".tif")
  pathdem  = paste0(path_basin, "/ra_dem", ".tif")
  
  if(!file.exists("cuencas4")) dir.create("cuencas4")
  dir.create(path_basin)
  dir.create(paste0(path_basin, "/shp"))
  dir.create(paste0(path_basin, "/xls"))
  dir.create(paste0(path_basin, "/img"))
  
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = proj4string(pisco)))
  
  pisco_month_clip = crop(pisco, buf_wgs) %>% mask(buf_wgs)
  cn_clip_1 = crop(cn1, buf) %>% mask(buf)
  cn_clip_resam_1 = Resamplear(cn_clip, pisco_month_clip[[1]])
  
  cn_clip_2 = crop(cn2, buf) %>% mask(buf)
  cn_clip_resam_2 = Resamplear(cn_clip, pisco_month_clip[[1]])
  
  
  for(x in 1:432){
    print(x)
    if(i %% 12 %in% c(0, 1:4)){
      cn = cn_clip_resam_1
    }else if(i %% 12 %in% mes){
      cn = cn_clip_resam_2
    }
    q = runoff(pisco_month_clip[[x]], cn_clip_resam, numberOfDays(dates[x])) %>% Resamplear(cn_clip)
    writeRaster(q, 
                paste0(path_basin, "/q_", str_pad(as.character(x), 3, pad = "0") ,".tif"), 
                overwrite = TRUE)
  }
  
  # plantilla res=100 | crs=utm18
  if(!file.exists(pathcn)){
    writeRaster(cn_clip, pathcn, overwrite=TRUE)
  }
  
  if(!file.exists(pathdem)){
    dem_clip  = mask(crop(dem_total, buf_wgs), buf_wgs) %>% Resamplear(cn_clip)
    writeRaster(dem_clip, pathdem, overwrite=TRUE)
  }
}


crear_caudales(1, cn_cs_max)
crear_caudales(5, cn_cs_max)
crear_caudales(6, cn_cs_max)
crear_caudales(7, cn_cs_max)
crear_caudales(2, cn_ch_min)
crear_caudales(8, cn_ch_min)
crear_caudales(9, cn_ch_min)
crear_caudales(3, cn_cs_min)
crear_caudales(10, cn_cs_min)
crear_caudales(4, cn_cn_min)



dates = seq(as.Date("1981-01-01"), as.Date("2016-12-31"), by="month")
numberOfDays <- function(date) {
  m <- format(date, format="%m")
  while (format(date, format="%m") == m) { date <- date + 1  }
  return(as.integer(format(date - 1, format="%d")))
}




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
  }
  return(q_st)
}


path_basin = "E:/2020/uni/cuencas4/1"
# Q3 = calc(Q2, fun=function(x) quantile(x, .05, na.rm=TRUE))
Q = stack(list.files("E:/2020/uni/cuencas4/1", pattern = "^facc_(.*)tif$", full.names = T))

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

plot(q_st[[3]])

annos = seq(as.Date("1981-01-01"),as.Date("2016-01-01"),by="year")
coord = data.frame(x=-122729,y=9424388)
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


ts.plot(ts(df))

df_xts = as.xts(df)
plot(df_xts$serie_01)
plot(df_xts$serie_02, add=T)


par(mfcol=c(1,2))
plot(df_xts$serie_03)
plot(df_xts$serie_08)

mean(df_xts$serie_03)
quantile(df_xts$serie_03, .05, na.rm=TRUE)

mean(df_xts$serie_08)
quantile(df_xts$serie_08, .05, na.rm=TRUE)


df2 = melt(df)
df2["fecha"] = annos

df3 = df2 %>%
  mutate(x = paste0(format(fecha, "%Y"), "-", str_pad(variable, 2, pad = "0"), "-01")) %>%
  select(c("x", "value")) %>%
  arrange(x)

write.csv(df, "E:/2020/uni/cuencas4/1/xls/datos_multianuales_SanchezCerro.csv")
write.csv(df3, "E:/2020/uni/cuencas4/1/xls/serie_SanchezCerro_2.csv")
