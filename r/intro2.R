library(raster)
library(sf)
install.packages("fasterize")
library(fasterize)

setwd("E:/2019/UNI/data")

ch = read_sf("shp/Centrales_estudio.shp")
ws = read_sf("shp/cuencas-data_mining.shp")

ws = st_read(".", "cuencas-data_mining.shp")
plot(ws)

library(rgdal)
library(rgeos)
rtemp = raster(xmn=-81.5,xmx=-78,ymn=-7.5,ymx=-4,res=0.01)
r1 = fasterize(st_as_sf(ws), rtemp, field="NOMBRE_P")
plot(r1)

library(ncdf4)
nc = brick("PISCOpm21.nc")
plot(nc[[1]])

r2 = Resamplear(nc, r1)
plot(r2)
plot(ws$geometry, add=T)

ex = extract(r2, ws, fun='mean', na.rm=TRUE, df=TRUE, weights = TRUE)
plot(ex)
