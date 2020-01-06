rm(list=ls())
install.packages("rgdal")
install.packages("raster")
install.packages("sf")
install.packages("ncdf4")
install.packages("ggplot2")
install.packages("mapview")
require("raster")
require("ncdf4")
require("sf")
require("ggplot2")
require("mapview")
require("dplyr")



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

cn = raster("data/raster/ra_cn_min.tif")
dem_total = raster("data/raster/SRTM_90.tif")
area_cuencas = st_read("data/shp/gpo_cuencas_eval.shp")
pisco = brick("E:/BASE_DATOS/PISCO/PISCOpm21.nc")

# dem_utm = Resamplear(dem_total, cn)
area_cuencas_wgs = st_transform(area_cuencas, crs = proj4string(pisco))
area_cuencas_utm = st_transform(area_cuencas, crs = proj4string(cn))

for(i in seq(nrow(area_cuencas_utm))[8:10]){
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("process/", i)
  pathdem  = paste0(path_basin, "/ra_dem.tif")
  pathfdir = paste0(path_basin, "/ra_fdir.tif")
  pathppst = paste0(path_basin, "/ra_ppst.tif")
  pathqst  = paste0(path_basin, "/ra_qst_min.tif")
  pathcn   = paste0(path_basin, "/ra_cn_min.tif")
  
  # dir.create(path_basin)
  # dir.create(paste0(path_basin, "/shp"))
  # dir.create(paste0(path_basin, "/xls"))
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = proj4string(pisco)))
  
  # plantilla res=100 | crs=utm18
  cn_clip = mask(crop(cn, buf), buf)

  dem_clip  = Resamplear(mask(crop(dem_total, buf_wgs), buf_wgs), cn_clip)
  pp_clip  = mask(crop(pisco, buf_wgs), buf_wgs)
  
  pp_st = pp_mean_month(Resamplear(pp_clip, cn_clip))
  q_st = runoff(pp_st, cn_clip)
  
  # guardar archivos
  # writeRaster(dem_clip, pathdem, overwrite=TRUE)
  # terrain(dem_clip, opt="flowdir", unit="radians", neighbors=8, filename=pathfdir)
  # writeRaster(pp_st, pathppst, overwrite=TRUE)
  writeRaster(q_st, pathqst, overwrite=TRUE)
  
  writeRaster(q_st[[2]], paste0(path_basin, "/q_01_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[3]], paste0(path_basin, "/q_02_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[4]], paste0(path_basin, "/q_03_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[5]], paste0(path_basin, "/q_04_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[6]], paste0(path_basin, "/q_05_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[7]], paste0(path_basin, "/q_06_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[8]], paste0(path_basin, "/q_07_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[9]], paste0(path_basin, "/q_08_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[10]], paste0(path_basin, "/q_09_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[11]], paste0(path_basin, "/q_10_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[12]], paste0(path_basin, "/q_11_min.tif"), overwrite = TRUE)
  writeRaster(q_st[[1]], paste0(path_basin, "/q_12_min.tif"), overwrite = TRUE)
  
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


##############################
##############################
# ********* GRAFICOS *********
##############################
##############################

shp = sf::st_read("E:/2020/uni/data/shp/gpt_estaciones.shp")
xls = read.csv("E:/2020/uni/data/xls/series_estaciones.csv", sep = ";")

# cuencas = sf::st_read("E:/2020/uni/data/shp/gpo_cuencas_eval.shp")
# mapview(list(shp, cuencas))

df = data.frame(seq(1,12))
extract_data_serie = function(i, row){
  facc = stack(list.files(paste0("E:/2020/uni/process/", as.character(i)), pattern = "(facc_[0,1][0-9]_mean).tif$", full.names = T))
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



grafico = function(datos, nombre){
  val_max = (as.integer(max(datos) / 20) + 1) * 20
  mes = seq(as.Date('2019-01-01'), as.Date('2019-12-01'), by = 'month')
  grupo = c(rep("flowacc", 12), rep("estacion", 12))
  dataf = data.frame(mes, datos, grupo)
  Sys.setlocale(category = 'LC_ALL', locale = 'english')
  ploteo = ggplot(dataf, aes(x=mes, y=datos, shape = grupo, col = grupo)) +
    geom_line(size = 1) + theme_bw() + 
    theme(plot.title = element_text(face='bold')) +
    scale_colour_manual(values = c('blue', 'red')) +
    ylab(label = 'Q [m3/s]') +  xlab(label = '') +
    ggtitle(nombre, subtitle = 'from 1981 to 2017') + 
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

grafico(valoresC_1, "Cuenca Piura")
ggsave("process/1/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_2, "Cuenca Chira")
ggsave("process/2/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_3, "Cuenca Motupe")
ggsave("process/3/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_4, "Cuenca Chancay-Lambayeque")
ggsave("process/4/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_4_1, "Cuenca Chancay-Lambayeque")
ggsave("process/4/img/station_runoff_1.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_5, "Cuenca Zaña")
ggsave("process/5/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_6, "Cuenca Jequetepeque")
ggsave("process/6/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_7, "Cuenca Virú")
ggsave("process/7/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_8, "Cuenca Santa")
ggsave("process/8/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_8_1, "Cuenca Santa")
ggsave("process/8/img/station_runoff_1.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_9, "Cuenca Pativilca")
ggsave("process/9/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_9_1, "Cuenca Pativilca")
ggsave("process/9/img/station_runoff_1.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_10, "Cuenca Moche")
ggsave("process/10/img/station_runoff.png", width = 250, height = 180, units = "mm", dpi = 300)
