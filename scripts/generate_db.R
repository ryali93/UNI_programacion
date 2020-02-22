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
# require("gdalcubes")
# require("stars")


# cl <- makeCluster(4)
# parLapply(cl, iter, lm_boot_fun)

setwd("E:/2020/uni")
cn = raster("data/raster/ra_cn_cs_min.tif")
dem_total = raster("data/raster/SRTM_90.tif")
area_cuencas = st_read("data/shp/gpo_cuencas_eval.shp")
pisco = brick("E:/BASE_DATOS/PISCO/PISCOpm21.nc")
area_cuencas_wgs = st_transform(area_cuencas, crs = proj4string(pisco))
area_cuencas_utm = st_transform(area_cuencas, crs = proj4string(cn))

#------------------------------------------------------------------------
# CARGANDO FUNCION PARA NORMALIZAR DATOS
Resamplear = function(objetivo, plantilla){
  #Verificar la proyecciÃ³n
  if(proj4string(plantilla)!=proj4string(objetivo)){
    print("las proyecciones son diferentes")
    objetivo_proj<-projectRaster(objetivo,crs=CRS(proj4string(plantilla)))
    # print(proj4string(hasta_proj))
  }else{
    print("Tienen la misma proyeccion")
    objetivo_proj<-objetivo
  }
  #Verificando ExtensiÃ³n
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
  Q3 = mean(Q2)
  # PERSISTENCIA AL 95%
  # Q3 = calc(Q2, fun=function(x) quantile(x, .05, na.rm=TRUE))
  return(Q3)
}
crear_caudales = function(i){
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("process_ch_max/", i)
  
  pathfdir = paste0(path_basin, "/ra_fdir.tif")
  pathcn   = paste0("data/raster", "/ra_cn_ch_max", i, ".tif")
  pathppst = paste0("data/raster", "/ra_ppst_", i, ".tif")
  pathdem  = paste0("data/raster", "/ra_dem_", i, ".tif")
  pathqst  = paste0(path_basin, "/ra_qst.tif")

  dir.create(path_basin)
  dir.create(paste0(path_basin, "/shp"))
  dir.create(paste0(path_basin, "/xls"))
  dir.create(paste0(path_basin, "/img"))
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = proj4string(pisco)))
  
  # plantilla res=100 | crs=utm18
  if(!file.exists(pathcn)){
    cn_clip = mask(crop(cn, buf), buf)
    writeRaster(cn_clip, pathcn, overwrite=TRUE)
  }else{
    cn_clip = raster(pathcn)
    }
  
  if(!file.exists(pathdem)){
    dem_clip  = Resamplear(mask(crop(dem_total, buf_wgs), buf_wgs), cn_clip)
    writeRaster(dem_clip, pathdem, overwrite=TRUE)
  }else{
    dem_clip = raster(pathdem)
  }
  
  pp_clip  = mask(crop(pisco, buf_wgs), buf_wgs)

  if(!file.exists(pathppst)){
    pp_st = pp_month(Resamplear(pp_clip, cn_clip))
    writeRaster(stack(pp_st), pathppst, overwrite=TRUE)
  }
  
  # q_st = runoff(pp_st, cn_clip)
  # 
  # # guardar archivos
  # writeRaster(q_st, pathqst, overwrite=TRUE)
  # 
  # writeRaster(q_st[[2]], paste0(path_basin, "/q_01.tif"), overwrite = TRUE)
  # writeRaster(q_st[[3]], paste0(path_basin, "/q_02.tif"), overwrite = TRUE)
  # writeRaster(q_st[[4]], paste0(path_basin, "/q_03.tif"), overwrite = TRUE)
  # writeRaster(q_st[[5]], paste0(path_basin, "/q_04.tif"), overwrite = TRUE)
  # writeRaster(q_st[[6]], paste0(path_basin, "/q_05.tif"), overwrite = TRUE)
  # writeRaster(q_st[[7]], paste0(path_basin, "/q_06.tif"), overwrite = TRUE)
  # writeRaster(q_st[[8]], paste0(path_basin, "/q_07.tif"), overwrite = TRUE)
  # writeRaster(q_st[[9]], paste0(path_basin, "/q_08.tif"), overwrite = TRUE)
  # writeRaster(q_st[[10]], paste0(path_basin, "/q_09.tif"), overwrite = TRUE)
  # writeRaster(q_st[[11]], paste0(path_basin, "/q_10.tif"), overwrite = TRUE)
  # writeRaster(q_st[[12]], paste0(path_basin, "/q_11.tif"), overwrite = TRUE)
  # writeRaster(q_st[[1]], paste0(path_basin, "/q_12.tif"), overwrite = TRUE)
}


crear_caudales_2 = function(i){
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("process_ch_max/", i)
  pathcn   = paste0("data/raster", "/ra_cn_ch_max", i, ".tif")
  pathppst = paste0("data/raster", "/ra_ppst_", i, ".tif")
  pathqst  = paste0(path_basin, "/ra_qst.tif")
  
  cn_clip = raster(pathcn)
  pp_st = pp_month(stack(pathppst))
  
  # guardar archivos
  writeRaster(runoff(pp_st[[2]], cn_clip), paste0(path_basin, "/q_01.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[3]], cn_clip), paste0(path_basin, "/q_02.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[4]], cn_clip), paste0(path_basin, "/q_03.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[5]], cn_clip), paste0(path_basin, "/q_04.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[6]], cn_clip), paste0(path_basin, "/q_05.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[7]], cn_clip), paste0(path_basin, "/q_06.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[8]], cn_clip), paste0(path_basin, "/q_07.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[9]], cn_clip), paste0(path_basin, "/q_08.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[10]], cn_clip), paste0(path_basin, "/q_09.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[11]], cn_clip), paste0(path_basin, "/q_10.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[12]], cn_clip), paste0(path_basin, "/q_11.tif"), overwrite = TRUE)
  writeRaster(runoff(pp_st[[1]], cn_clip), paste0(path_basin, "/q_12.tif"), overwrite = TRUE)
  
}


# "1","Cuenca Piura"              --> "Sanchez Cerro 2" (21)
# "2","Cuenca Chira"              --> "QN-2701" (17)
# "3","Cuenca Motupe"             --> "Puchaca" (6)
# "4","Cuenca Chancay-Lambayeque" --> "QN-603" (15), "QN-606" (16)
# "5","Cuenca Zaña"               --> "Batan" (5)
# "6","Cuenca Jequetepeque"       --> "QN-501" (14)
# "7","Cuenca Virú"               --> "Huacopongo" (8)
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
valoresC_5 = c(as.vector(df$C_5), as.vector(xls$Batan))               # "5","Cuenca Zaña"
valoresC_6 = c(as.vector(df$C_6), as.vector(xls$QN501))               # "6","Cuenca Jequetepeque"
valoresC_7 = c(as.vector(df$C_7), as.vector(xls$Huacapongo))          # "7","Cuenca Virú"
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
graph_5 = grafico(valoresC_5, "Cuenca Zaña")
graph_6 = grafico(valoresC_6, "Cuenca Jequetepeque")
graph_7 = grafico(valoresC_7, "Cuenca Virú")
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

setwd("E:/2020/uni")
files_q = list.files("data/raster/ra_cn_cs_min", full.names = T)

for(i in 1:10){
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("process_cs_min/", i)
  pathcn   = paste0(path_basin, "/ra_cn.tif")
  pathdem  = paste0(path_basin, "/ra_dem.tif")
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = proj4string(pisco)))
  
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





# ------------------------------------------------------------------------------------
getwd()

proceso = "process_cs_min"
dir.create(paste0("enviar/", proceso))
for(c in 1:10){
  dir.create(paste0("enviar/", proceso, "/", c))
  nombres = list.files(paste0(proceso, "/", c, "/img"))
  files = list.files(paste0(proceso, "/", c,"/img"), full.names = T)
  for (f in seq(length(files))){
    file.copy(files[f], paste0("enviar/", proceso, "/", c, "/", nombres[f]))
  }
}


