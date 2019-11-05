setwd("D:/UNI_programacion")

library(raster)
p = brick("raster/piscoclip.tif")

lista = c()
for( i in 1:432){
  if (i %% 12 == 1){
    a = p[[i]]
    lista = c(lista,a)
  }
}

m = calc(stack(lista), mean)
plot(m)

writeRaster(m, "raster/pisco_jan_mean.tif")

meanserie = seq(as.Date(""), as.Date(""),by = "yearly") #
# df  = data.frame(serie,lista)


cn = raster("raster/cn_cn_reclass.tif")
plot(cn)
s = 25.4 * ( (1000 / cn) - 10)


p = Resamplear(s, m)
ss = Resamplear(m, s)

plot(p)
q = (m - 0.2 * p)^2 / (m + 0.8 * p)
plot(q)

writeRaster(q, "raster/caudal_tmp.tif")





slope = raster("raster/slope_deg.tif")
slope_perc = calc(slope*(pi/180), tan)
plot(slope_perc*90)

writeRaster(slope_perc*90, "raster/slope_perc.tif", overwrite=T)



