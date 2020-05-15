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
  Q3 = calc(Q2, fun=function(x) quantile(x, .95, na.rm=TRUE))
  return(Q3)
}

setwd("E:/2020/uni")

cn = raster("data/raster/ra_cn_min.tif")
dem_total = raster("data/raster/SRTM_90.tif")
area_cuencas = st_read("data/shp/gpo_cuencas_eval.shp")
pisco = brick("E:/BASE_DATOS/PISCO/PISCOpm21.nc")

# dem_utm = Resamplear(dem_total, cn)
area_cuencas_wgs = st_transform(area_cuencas, crs = proj4string(pisco))
area_cuencas_utm = st_transform(area_cuencas, crs = proj4string(cn))

for(i in seq(9,10)){
  i = 1
  print(as.character(area_cuencas_utm$NOMBRE[i]))
  path_basin = paste0("process/", i)
  pathdem  = paste0(path_basin, "/ra_dem.tif")
  pathfdir = paste0(path_basin, "/ra_fdir.tif")
  pathppst = paste0(path_basin, "/ra_ppst.tif")
  # pathqst  = paste0(path_basin, "/ra_qst_min.tif")
  pathcn   = paste0(path_basin, "/ra_cn_min.tif")
  
  # dir.create(path_basin)  # dir.create(paste0(path_basin, "/shp"))
  # dir.create(paste0(path_basin, "/xls"))
  # dir.create(paste0(path_basin, "/img"))
  buf      = st_as_sf(st_buffer(st_geometry(area_cuencas_utm[i,]), dist = 10000))
  buf_wgs  = st_as_sf(st_transform(buf, crs = proj4string(pisco)))
  
  # plantilla res=100 | crs=utm18
  cn_clip = mask(crop(cn, buf), buf)
  
  dem_clip  = Resamplear(mask(crop(dem_total, buf_wgs), buf_wgs), cn_clip)
  pp_clip  = mask(crop(pisco, buf_wgs), buf_wgs)
  pp_st = pp_month(Resamplear(pp_clip, cn_clip))
  
  for (j in seq(9,12)){
    q_st = runoff(pp_st[[j]], cn_clip)
    writeRaster(q_st, paste0(path_basin, "/q_", formatC(j, width=2, flag="0"), "_cnmin_q05.tif"), overwrite = TRUE)
  }
  # guardar archivos
  writeRaster(dem_clip, pathdem, overwrite=TRUE)
  # writeRaster(stack(pp_mensual), pathppst, overwrite=TRUE)
  # terrain(dem_clip, opt="flowdir", unit="radians", neighbors=8, filename=pathfdir)
  # writeRaster(q_st, pathqst, overwrite=TRUE)
}



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
  # facc = stack(list.files(paste0("E:/2020/uni/process/", as.character(i)), pattern = "(facc_[0,1][0-9]_cnmin_qmean).tif$", full.names = T))
  # facc = stack(list.files(paste0("E:/2020/uni/process/", as.character(i)), pattern = "(facc_[0,1][0-9]_cnmin_q95).tif$", full.names = T))
  # facc = stack(list.files(paste0("E:/2020/uni/process/", as.character(i)), pattern = "(facc_[0,1][0-9]_cnmax_qmean).tif$", full.names = T))
  facc = stack(list.files(paste0("E:/2020/uni/process/", as.character(i)), pattern = "(facc_[0,1][0-9]_cnmin_q05).tif$", full.names = T))
  
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
colnames(df)[2] = "cnmin_qmean"
colnames(df)[3] = "cnmin_q95"
colnames(df)[4] = "cnmax_qmean"
# colnames(df)[5] = "cnmin_q05"

df1 = cbind(df, estacion = as.vector(xls$SanchezCerro)) 

data.frame(
  mes = seq(as.Date('2019-01-01'), as.Date('2019-12-01'), by = 'month'),
  grupo = c(rep("cnmin_qmean", 12), rep("cnmin_q95", 12), rep("cnmax_qmean", 12), rep("estacion", 12)),
  valores = c(df1$cnmin_qmean, df1$cnmin_q95, df1$cnmax_qmean, df1$estacion)
)

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
    ggtitle(nombre, subtitle = 'from 1981 to 2017 - Q mean - CN min') + 
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
ggsave("process/1/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_2, "Cuenca Chira")
ggsave("process/2/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_3, "Cuenca Motupe")
ggsave("process/3/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_4, "Cuenca Chancay-Lambayeque")
ggsave("process/4/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_4_1, "Cuenca Chancay-Lambayeque")
ggsave("process/4/img/qmean_cnmin_1.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_5, "Cuenca ZaÒa")
ggsave("process/5/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_6, "Cuenca Jequetepeque")
ggsave("process/6/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_7, "Cuenca Vir˙")
ggsave("process/7/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_8, "Cuenca Santa")
ggsave("process/8/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_8_1, "Cuenca Santa")
ggsave("process/8/img/qmean_cnmin_1.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_9, "Cuenca Pativilca")
ggsave("process/9/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_9_1, "Cuenca Pativilca")
ggsave("process/9/img/qmean_cnmin_1.png", width = 250, height = 180, units = "mm", dpi = 300)
grafico(valoresC_10, "Cuenca Moche")
ggsave("process/10/img/qmean_cnmin.png", width = 250, height = 180, units = "mm", dpi = 300)




nombre = "Cuenca Piura"
mes = seq(as.Date('2019-01-01'), as.Date('2019-12-01'), by = 'month')
grupo = c(rep("cnmin_qmean", 12), rep("cnmin_q95", 12), rep("cnmax_qmean", 12), rep("estacion", 12))
datos = c(df1$cnmin_qmean, df1$cnmin_q95, df1$cnmax_qmean, df1$estacion)
dataf = data.frame(mes, datos, grupo)
val_max = (as.integer(max(datos) / 20) + 1) * 20
Sys.setlocale(category = 'LC_ALL', locale = 'english')
ggplot(dataf, aes(x=mes, y=datos, shape = grupo, col = grupo)) +
  geom_line(size = 1) + theme_bw() + 
  theme(plot.title = element_text(face='bold')) +
  scale_colour_manual(values = c('blue', 'red', 'green', 'brown')) +
  ylab(label = 'Q [m3/s]') +  xlab(label = '') +
  ggtitle(nombre, subtitle = 'from 1981 to 2017 - Q mean - CN min') + 
  theme(plot.title    = element_text(size=16),
        plot.subtitle = element_text(size=16),
        axis.text.x   = element_text(size=12),
        axis.text.y   = element_text(size=12),
        axis.title    = element_text(size=17)) +
  scale_x_date(date_labels = '%b', breaks = '1 month') +
  scale_y_continuous(breaks = seq(0, val_max, 20), limits = c(0, val_max)) +
  geom_point(size = 3.5)



