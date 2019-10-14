setwd("E:/2019/UNI")
rm(list=ls())
# Creando un vector de character
v_dep = c("cajamarca", "lima", "ayacucho")
v_dep

# Obteniendo un vector de comparacion (y lo asignamos a una variable para filtrar despues)
v_flag = v_dep == "ayacucho"
v_flag

v_dep[v_flag] = "cusco"

vec2 = c("A", "A", "A", "B", "B", "C")
vec2[vec2 == "A"] = "A2"
vec2

# Leer archivos espaciales
pp = read.csv("data/pp_jequetepeque.csv", sep = ";")
head(pp)

pp[,1] = as.Date(pp[,1], format="%d/%m/%Y")

plot(pp[,2], type="l")
library("ggplot2")
ggplot(pp, aes(NOMBRE))+
  geom_line(aes(y=ASUNCION, colour="red"))

pp[,1]

install.packages("hydroTSM")
library("hydroTSM")

pp = read.csv("data/pp_jequetepeque.csv", sep = ";")
df = daily2monthly(pp, FUN=mean, na.rm=T, date.fmt = "%d/%m/%Y", out.fmt="zoo")
df2 = fortify(df)

library("dplyr")

ggplot(df2, aes(Index)) +
  geom_line(aes(y=ASUNCION), color = "blue") +
  theme_bw() +
  ggtitle("Grafico de precipitación (mm)") +
  xlab("Fechas") +
  theme(axis.title = element_text(size=12,face="bold"), axis.text = element_text(size=10), legend.position="bottom")
