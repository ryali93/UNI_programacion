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

  plot(pp_st)


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
df
xls


mes = seq(as.Date('2019-01-01'), as.Date('2019-12-01'), by = 'month')
valores = c(as.vector(df$C_1), as.vector(xls$SanchezCerro))        # "1","Cuenca Piura"
valores = c(as.vector(df$C_2), as.vector(xls$QN2701))              # "2","Cuenca Chira"
valores = c(as.vector(df$C_6), as.vector(xls$QN501))               # "6","Cuenca Jequetepeque"


# "3","Cuenca Motupe"
# "4","Cuenca Chancay-Lambayeque"
# "5","Cuenca Zaña"

# "7","Cuenca Virú"
# "8","Cuenca Santa"
# "9","Cuenca Pativilca"
# "10","Cuenca Moche"

grupo = c(rep("flowacc", 12), rep("estacion", 12))
df6_9 = data.frame(mes, valores, grupo)

Sys.setlocale(category = 'LC_ALL', locale = 'english')

ggplot(df6_9, aes(x=mes, y=valores, shape = grupo, col = grupo)) +
  geom_line(size = 1) + theme_bw() +
  scale_colour_manual(values = c('blue', 'red')) +
  ylab(label = 'Q [m^3/s]') +  xlab(label = '') +
  ggtitle('Runoff', subtitle = 'from 1981 to 2017') + 
  theme(plot.title    = element_text(size=16),
        plot.subtitle = element_text(size=16),
        axis.text.x   = element_text(size=12),
        axis.text.y   = element_text(size=12),
        axis.title    = element_text(size=17)) +
  scale_x_date(date_labels = '%b', breaks = '1 month') +
  scale_y_continuous(breaks = seq(0,100,10), limits = c(0, 100)) +
  geom_point(size = 3.5)



df1 = data.frame(df$mes, df$C_1,   xls$SanchezCerro)
df2 = data.frame(df$mes, df$C_2,   xls$QN2701)
df3 = data.frame(df$mes, df$C_3,   xls$Puchaca)
df4 = data.frame(df$mes, df$C_4,   xls$QN603)
df4_1 = data.frame(df$mes, df$C_4_1, xls$QN606)
df5 = data.frame(df$mes, df$C_5,   xls$Batan)
df6 = data.frame(df$mes, df$C_6,   xls$QN501)
df7 = data.frame(df$mes, df$C_7,   xls$Huacapongo)
df8 = data.frame(df$mes, df$C_8,   xls$Condorcerro)
df8_1 = data.frame(df$mes, df$C_8_1, xls$QN403)
df9 = data.frame(df$mes, df$C_9,   xls$Yanapampa)
df9_1 = data.frame(df$mes, df$C_9_1, xls$QN304)
df10 = data.frame(df$mes, df$C_10,  xls$Quirihuac)

ggplot(df1, aes(x = df.mes)) + theme_bw() +
  geom_line(aes(y = df.C_1, col="red"), linetype = "dashed") +
  geom_point(aes(y = df.C_1, col="red", shape = 11), size=3) +
  geom_line(aes(y = xls.SanchezCerro, col="blue")) +
  # geom_point(aes(y = xls.SanchezCerro, col="blue"), size=3) +
  
  scale_shape_manual(values = c(24, 21), guide = "none") +
  theme(legend.position="bottom")

p2 <- ggplot(df2, aes(x = df.mes)) + theme_bw() +
  geom_line(aes(y = df.C_2, col="C_2", linetype = "dashed")) +
  geom_line(aes(y = xls.QN2701, col="SanchezCerro"))


p3 <- ggplot(df3, aes(x = df.mes)) +
  geom_line(aes(y = df.C_3, col="C_3")) +
  geom_line(aes(y = xls.Puchaca, col="Puchaca"))

p4 <- ggplot(df4, aes(x = df.mes)) +
  geom_line(aes(y = df.C_4, col="C_4")) +
  geom_line(aes(y = xls.QN603, col="QN603"))

p4_1 <- ggplot(df4_1, aes(x = df.mes)) +
  geom_line(aes(y = df.C_4_1, col="C_4_1")) +
  geom_line(aes(y = xls.QN606, col="QN606"))


ggarrange(p1,p2,p3,p4)

ggplot(df5, aes(x = df.mes)) +
  geom_line(aes(y = df.C_5, col="C_5")) +
  geom_line(aes(y = xls.Batan, col="Batan"))

ggplot(df6, aes(x = df.mes)) +
  geom_line(aes(y = df.C_6, col="C_6")) +
  geom_line(aes(y = xls.QN501, col="QN501"))

ggplot(df7, aes(x = df.mes)) +
  geom_line(aes(y = df.C_7, col="C_7")) +
  geom_line(aes(y = xls.Huacapongo, col="Huacapongo"))

ggplot(df8, aes(x = df.mes)) +
  geom_line(aes(y = df.C_8, col="C_8")) +
  geom_line(aes(y = xls.Condorcerro, col="Condorcerro"))

ggplot(df8_1, aes(x = df.mes)) +
  geom_line(aes(y = df.C_8_1, col="C_8_1")) +
  geom_line(aes(y = xls.QN403, col="QN403"))

ggplot(df9, aes(x = df.mes)) +
  geom_line(aes(y = df.C_9, col="C_9")) +
  geom_line(aes(y = xls.Yanapampa, col="Yanapampa"))

ggplot(df9_1, aes(x = df.mes)) +
  geom_line(aes(y = df.C_9_1, col="C_9_1")) +
  geom_line(aes(y = xls.QN304, col="QN304"))

ggplot(df10, aes(x = df.mes)) +
  geom_line(aes(y = df.C_10, col="C_10")) +
  geom_line(aes(y = xls.Quirihuac, col="Quirihuac"))





st = stack("E:/2020/uni/process/1/ra_ppst.tif")
plot(st[[1]])

qst = stack("E:/2020/uni/process/1/ra_qst.tif")
plot(qst[[3]])
