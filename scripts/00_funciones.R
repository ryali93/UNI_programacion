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