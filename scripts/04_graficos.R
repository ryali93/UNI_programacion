rm(list=ls())

# Cargar librerías
require("raster")
require("ncdf4")
require("sf")
require("ggplot2")
require("mapview")
require("dplyr")
require("stringr")
require("hydroGOF")

setwd("E:/2020/uni")

# ESCENARIO
ESCENARIO = "ra_cn_cs_min"
PROCESO = "process_cs_min"
SUBTITULO = "PP MEAN - CN min'"

# Variables locales
shp = st_read("data/shp/gpt_estaciones.shp")
xls = read.csv("data/xls/series_estaciones.csv", sep = ";")

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

# Funcion para generar estadisticos
estadisticos = function(df){
  # correlation
  coef_corr = cor(df$generado, df$estacion, method = "pearson", use = "complete.obs")
  # rmse
  error_rmse = rmse(df$generado, df$estacion)
  # bias
  bias = pbias(df$generado, df$estacion)
  # nash
  nash = NSE(df$generado, df$estacion)
  
  estadist = c(paste0("r2: ", round(coef_corr, 2)),
               paste0("rmse: ", round(error_rmse, 2)),
               paste0("bias: ", round(bias, 2)),
               paste0("nash: ", round(nash, 2)), 
               rep("", 8))
  df = cbind(df, estadist)
  return(df)
}

# Funcion para crear data frame con datos exraido del flow accumulation 
extract_data_serie = function(i, row){
  facc = stack(list.files(paste0(PROCESO, "/", as.character(i)), pattern = "(facc_[0,1][0-9]).tif$", full.names = T))
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

df = data.frame(mes = seq(1,12))
# Extrayendo datos del flow accumulation para cada estacion
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
# colnames(df)[1] = "mes"

# Juntando datos de flowacc con estacion
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

# Creando df para cada estacion comparando con datos del flowacc
dfC_1 = estadisticos(data.frame(generado=as.vector(df$C_1), estacion=as.vector(xls$SanchezCerro)))
dfC_2 = estadisticos(data.frame(generado=as.vector(df$C_2), estacion=as.vector(xls$QN2701)))
dfC_3 = estadisticos(data.frame(generado=as.vector(df$C_3), estacion=as.vector(xls$Puchaca)))
dfC_4 = estadisticos(data.frame(generado=as.vector(df$C_4), estacion=as.vector(xls$QN603)))
dfC_4_1 = estadisticos(data.frame(generado=as.vector(df$C_4_1), estacion=as.vector(xls$QN606)))
dfC_5 = estadisticos(data.frame(generado=as.vector(df$C_5), estacion=as.vector(xls$Batan)))
dfC_6 = estadisticos(data.frame(generado=as.vector(df$C_6), estacion=as.vector(xls$QN501)))
dfC_7 = estadisticos(data.frame(generado=as.vector(df$C_7), estacion=as.vector(xls$Huacapongo)))
dfC_8 = estadisticos(data.frame(generado=as.vector(df$C_8), estacion=as.vector(xls$Condorcerro)))
dfC_8_1 = estadisticos(data.frame(generado=as.vector(df$C_8_1), estacion=as.vector(xls$QN403)))
dfC_9 = estadisticos(data.frame(generado=as.vector(df$C_9), estacion=as.vector(xls$Yanapampa)))
dfC_9_1 = estadisticos(data.frame(generado=as.vector(df$C_9_1), estacion=as.vector(xls$QN304)))
dfC_10 = estadisticos(data.frame(generado=as.vector(df$C_10), estacion=as.vector(xls$Quirihuac)))


# Guardando comparacion y estadisticos
write.csv(dfC_1, paste0(PROCESO,"/1/img/dfC_1.csv"))
write.csv(dfC_2, paste0(PROCESO,"/2/img/dfC_2.csv"))
write.csv(dfC_3, paste0(PROCESO,"/3/img/dfC_3.csv"))
write.csv(dfC_4, paste0(PROCESO,"/4/img/dfC_4.csv"))
write.csv(dfC_4_1, paste0(PROCESO,"/4/img/dfC_4_1.csv"))
write.csv(dfC_5, paste0(PROCESO,"/5/img/dfC_5.csv"))
write.csv(dfC_6, paste0(PROCESO,"/6/img/dfC_6.csv"))
write.csv(dfC_7, paste0(PROCESO,"/7/img/dfC_7.csv"))
write.csv(dfC_8, paste0(PROCESO,"/8/img/dfC_8.csv"))
write.csv(dfC_8_1, paste0(PROCESO,"/8/img/dfC_8_1.csv"))
write.csv(dfC_9, paste0(PROCESO,"/9/img/dfC_9.csv"))
write.csv(dfC_9_1, paste0(PROCESO,"/9/img/dfC_9_1.csv"))
write.csv(dfC_10, paste0(PROCESO,"/10/img/dfC_10.csv"))

# Generar graficos
grafico = function(datos, nombre){
  val_max = (as.integer(max(datos, na.rm = T) / 20) + 1) * 20
  mes = seq(as.Date('2019-01-01'), as.Date('2019-12-01'), by = 'month')
  grupo = c(rep("generado", 12), rep("estacion", 12))
  dataf = data.frame(mes, datos, grupo)
  Sys.setlocale(category = 'LC_ALL', locale = 'english')
  ploteo = ggplot(dataf, aes(x=mes, y=datos, shape = grupo, col = grupo)) +
    geom_line(size = 1) + theme_bw() + 
    theme(plot.title = element_text(face='bold')) +
    scale_colour_manual(values = c('blue', 'red')) +
    ylab(label = 'Q [m3/s]') +  xlab(label = '') +
    ggtitle(nombre, subtitle = paste0('from 1981 to 2017 - ', SUBTITULO)) + 
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

ggsave(paste0(PROCESO, "/1/img/comparacion.png"), plot = graph_1,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/2/img/comparacion.png"), plot = graph_2,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/3/img/comparacion.png"), plot = graph_3,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/4/img/comparacion.png"), plot = graph_4,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/4/img/comparacion_1.png"), plot = graph_4_1,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/5/img/comparacion.png"), plot = graph_5,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/6/img/comparacion.png"), plot = graph_6,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/7/img/comparacion.png"), plot = graph_7,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/8/img/comparacion.png"), plot = graph_8,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/8/img/comparacion_1.png"), plot = graph_8_1,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/9/img/comparacion.png"), plot = graph_9,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/9/img/comparacion_1.png"), plot = graph_9_1,width = 250, height = 180, units = "mm", dpi = 300)
ggsave(paste0(PROCESO, "/10/img/comparacion.png"), plot = graph_10,width = 250, height = 180, units = "mm", dpi = 300)