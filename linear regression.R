# Подготовительные работы


setwd("F:/Docs") #  адресс нововой директории
getwd()  # выясним путь к рабочей папке 
rm(list=ls()) # Удаление всех переменных с предыдущей сессии

#  Установка нужных пакетов
install.packages("tidyverse")
install.packages("psych")
install.packages("corrgram")
install.packages("caret")
#      A1, the operation time, 
#      A2, the temperature of the coolant,
#      A3, the transformed acid concentration.
#      B,  the percentage of unprocessed ammonia.

# 5 columns
# 21 rows
# Index
# Operation Time
# Coolant Temperature
# Transformed acid concentration
# Unprocessed percentage

# Загружаем датасет в R
dataset <- read.table("new.txt", header = TRUE)



# Проверяем зависимую переменную на нормальность распределения. 
h1 <- hist(dataset$B, freq = FALSE, col = "lightblue") 
curve(dnorm(x, mean=mean(dataset$B), sd=sd(dataset$B)), add = TRUE)  # На гисторграмме видно что данные не совсем нормально распределены

# Пробуем логарифмическую трансформацию 
dataset_log <- log(dataset)
h2 <- hist(log(dataset$B), freq = FALSE, col = "lightblue")
curve(dnorm(x, mean=mean(log(dataset$B)), sd=sd(log(dataset$B))), add = TRUE)
# Стало лучше

# Этот шаг поможет нам ближе познакомится с характеристиками данных в датасете 
library(psych)
psych::describe(dataset)

library(reshape2)
library(ggplot2)

meltData <- melt(dataset) # строим индексированный 1D ряд из датасета, нужно для ggplot
p <- ggplot(meltData, aes(factor(variable), value)) 
p + geom_boxplot() + facet_wrap(~variable, scale="free") + coord_flip()  # Строим ящик с усами

# Для того чтобы выбрать какие регрессоры нам стоит включить в нашу модель, мы строим матрицу корреляций: 
require(corrgram)
c <- corrgram(dataset) # это стандартный вид матрицы корреляций 
c2 <- corrgram(dataset, order=TRUE, lower.panel = panel.pts, upper.panel = panel.pie)

# для наглядной иллюстрации совместного распределения стоит использовать отдельно
# взятый график, как например:
plot(dataset$A1, dataset$A2)
pc <- princomp(dataset, cor = TRUE, score = TRUE)
pc$loadings
biplot(pc)

# Выбираем регрессоры А2, А1, A3. хотя между А2 A3  сильное значение коррелияции 


# Для наглядности строим рассеянные графики, проверфм что нет аномалий в совместном распределении

plot(dataset$B, dataset$A2)
plot(dataset$B, dataset$A3)

# Мы хотим случайным образом разделить 
# наш датасет 70/30: чтобы найти коэффициенты на 70% и проверить их на оставшихся 30%. 
library(caret)
index <- createDataPartition(dataset$B, p = .70, list = FALSE) 
train <- dataset[index, ] 
test <- dataset[-index, ] 



# Строим модель с помощью команды lm(). Желаемая форма модели: B =  Beta1*A1 + Beta2*A2 + Beta3*A3 
lin_mod <- lm(B~A1+A2+A3, data = dataset)
# Модель построена и мы видим коэфициенты:
print(lin_mod)
# Обратим внимание на суммарную статистику нашей модели:
summary(lin_mod)

# Мы смотрим на результаты нашей модели и видим что регрессор А3 не попадает в интервал 5% 
# Вторым важным показателем будет являться R-squared и Adjusted R-squared.  мы видим, наша модель имеет Adjusted R-squared 89,83%.
# Попробуем убрать регрессор с наименьшей статистической значимостью (А3):

lin_mod <- lm(B~A1+A2, data = dataset)
print(lin_mod)
summary(lin_mod)
# Мы видим что все регрессоры здесь являются статистически значимыми при уровне 5% и Adjusted R-squared стал лучше - 89,86%.
# В начале нашего кода мы создали логарифмически трансформированный датасет. Его распределение ближе к нормальному, по крайней мере в независимой переменной.
# Давайте обратимся к нему 

# В первую очередь, посмотрим вновь на матрицу корреляций:
c3 <- corrgram(dataset_log, order=TRUE, lower.panel = panel.pts, upper.panel = panel.pie)

# Выберем наиболее коррелирующие с B регрессоры:
lin_mod <- lm(B~A1+A2 + A3, data = dataset_log)
print(lin_mod)
summary(lin_mod)
# Мы сразу видим что Adj. R-sq. равен 90.16%, при том что 1 регрессор у нас не являются статистическими значимыми

lin_mod <- lm(B~A1+A2, data = dataset_log)
print(lin_mod)
summary(lin_mod)
# Итак, все регрессоры являются статистически значимыми даже в пределах 1% отсечки, и Adj. R-sq. остался на уровне 90.71%. Это неплохие показатели.

# Наконец, попробуем для наглядности "предсказать" зависимую переменную:
B_predict <- matrix(predict(lin_mod, dataset_log))
B_compare <- exp(cbind(dataset_log$B, B_predict))
View(B_compare)
# В первой колонке - оригинальные значения зависимой переменной, во второй - смоделированные.






















