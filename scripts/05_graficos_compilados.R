require("dplyr")
require("ggplot2")
getwd()
setwd("E:/2020/uni")

# ESCENARIO
SALIDA = "resultados"
SUBTITULO = "PP MEAN"

graficos_compilados = function(i, nombre){
  files_process_ch_max = list.files(paste0("process_ch_max", "/", i, "/img"), pattern = "*.csv$", full.names = T)
  files_process_ch_min = list.files(paste0("process_ch_min", "/", i, "/img"), pattern = "*.csv$", full.names = T)
  files_process_cn_max = list.files(paste0("process_cn_max", "/", i, "/img"), pattern = "*.csv$", full.names = T)
  files_process_cn_min = list.files(paste0("process_cn_min", "/", i, "/img"), pattern = "*.csv$", full.names = T)
  files_process_cs_max = list.files(paste0("process_cs_max", "/", i, "/img"), pattern = "*.csv$", full.names = T)
  files_process_cs_min = list.files(paste0("process_cs_min", "/", i, "/img"), pattern = "*.csv$", full.names = T)
  
  data_process_ch_max = read.csv(files_process_ch_max[1])
  data_process_ch_min = read.csv(files_process_ch_min[1])
  data_process_cn_max = read.csv(files_process_cn_max[1])
  data_process_cn_min = read.csv(files_process_cn_min[1])
  data_process_cs_max = read.csv(files_process_cs_max[1])
  data_process_cs_min = read.csv(files_process_cs_min[1])
  
  df = data.frame(
    estacion = data$estacion,
    ch_max = data_process_ch_max$generado,
    ch_min = data_process_ch_min$generado,
    cn_max = data_process_cn_max$generado,
    cn_min = data_process_cn_min$generado,
    cs_max = data_process_cs_max$generado,
    cs_min = data_process_cs_min$generado)
  
  datos = c(df$estacion, df$ch_max, df$ch_min, df$cn_max, df$cn_min, df$cs_max, df$cs_min)
  val_max = (as.integer(max(datos, na.rm = T) / 20) + 1) * 20
  mes = seq(as.Date('2019-01-01'), as.Date('2019-12-01'), by = 'month')
  grupo = c(
    rep("estacion", 12),
    rep("ch_max", 12),
    rep("ch_min", 12),
    rep("cn_max", 12),
    rep("cn_min", 12),
    rep("cs_max", 12),
    rep("cs_min", 12))
  dataf = data.frame(mes, datos, grupo)
  
  Sys.setlocale(category = 'LC_ALL', locale = 'english')
  ploteo = ggplot(dataf, aes(x=mes, y=datos, shape = grupo, col = grupo)) +
    geom_line(size = 1) + theme_bw() + 
    theme(plot.title = element_text(face='bold')) +
    # scale_colour_manual(values = c('blue', 'red')) +
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
  
  ggsave(paste0(SALIDA, "/", nombre,".png"), plot = ploteo, width = 250, height = 180, units = "mm", dpi = 300)
}


graficos_compilados(1, "Cuenca Piura")
graficos_compilados(2, "Cuenca Chira")
graficos_compilados(3, "Cuenca Motupe")
graficos_compilados(4, "Cuenca Chancay-Lambayeque")
graficos_compilados(5, "Cuenca Zaña")
graficos_compilados(6, "Cuenca Jequetepeque")
graficos_compilados(7, "Cuenca Virú")
graficos_compilados(8, "Cuenca Santa")
graficos_compilados(9, "Cuenca Pativilca")
graficos_compilados(10, "Cuenca Moche")




