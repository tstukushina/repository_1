# ���������������� ������


setwd("F:/Docs") #  ������ ������� ����������
getwd()  # ������� ���� � ������� ����� 
rm(list=ls()) # �������� ���� ���������� � ���������� ������

#  ��������� ������ �������
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

# ��������� ������� � R
dataset <- read.table("new.txt", header = TRUE)



# ��������� ��������� ���������� �� ������������ �������������. 
h1 <- hist(dataset$B, freq = FALSE, col = "lightblue") 
curve(dnorm(x, mean=mean(dataset$B), sd=sd(dataset$B)), add = TRUE)  # �� ������������ ����� ��� ������ �� ������ ��������� ������������

# ������� ��������������� ������������� 
dataset_log <- log(dataset)
h2 <- hist(log(dataset$B), freq = FALSE, col = "lightblue")
curve(dnorm(x, mean=mean(log(dataset$B)), sd=sd(log(dataset$B))), add = TRUE)
# ����� �����

# ���� ��� ������� ��� ����� ������������ � ���������������� ������ � �������� 
library(psych)
psych::describe(dataset)

library(reshape2)
library(ggplot2)

meltData <- melt(dataset) # ������ ��������������� 1D ��� �� ��������, ����� ��� ggplot
p <- ggplot(meltData, aes(factor(variable), value)) 
p + geom_boxplot() + facet_wrap(~variable, scale="free") + coord_flip()  # ������ ���� � �����

# ��� ���� ����� ������� ����� ���������� ��� ����� �������� � ���� ������, �� ������ ������� ����������: 
require(corrgram)
c <- corrgram(dataset) # ��� ����������� ��� ������� ���������� 
c2 <- corrgram(dataset, order=TRUE, lower.panel = panel.pts, upper.panel = panel.pie)

# ��� ��������� ����������� ����������� ������������� ����� ������������ ��������
# ������ ������, ��� ��������:
plot(dataset$A1, dataset$A2)
pc <- princomp(dataset, cor = TRUE, score = TRUE)
pc$loadings
biplot(pc)

# �������� ���������� �2, �1, A3. ���� ����� �2 A3  ������� �������� ����������� 


# ��� ����������� ������ ���������� �������, �������� ��� ��� �������� � ���������� �������������

plot(dataset$B, dataset$A2)
plot(dataset$B, dataset$A3)

# �� ����� ��������� ������� ��������� 
# ��� ������� 70/30: ����� ����� ������������ �� 70% � ��������� �� �� ���������� 30%. 
library(caret)
index <- createDataPartition(dataset$B, p = .70, list = FALSE) 
train <- dataset[index, ] 
test <- dataset[-index, ] 



# ������ ������ � ������� ������� lm(). �������� ����� ������: B =  Beta1*A1 + Beta2*A2 + Beta3*A3 
lin_mod <- lm(B~A1+A2+A3, data = dataset)
# ������ ��������� � �� ����� �����������:
print(lin_mod)
# ������� �������� �� ��������� ���������� ����� ������:
summary(lin_mod)

# �� ������� �� ���������� ����� ������ � ����� ��� ��������� �3 �� �������� � �������� 5% 
# ������ ������ ����������� ����� �������� R-squared � Adjusted R-squared.  �� �����, ���� ������ ����� Adjusted R-squared 89,83%.
# ��������� ������ ��������� � ���������� �������������� ����������� (�3):

lin_mod <- lm(B~A1+A2, data = dataset)
print(lin_mod)
summary(lin_mod)
# �� ����� ��� ��� ���������� ����� �������� ������������� ��������� ��� ������ 5% � Adjusted R-squared ���� ����� - 89,86%.
# � ������ ������ ���� �� ������� �������������� ������������������ �������. ��� ������������� ����� � �����������, �� ������� ���� � ����������� ����������.
# ������� ��������� � ���� 

# � ������ �������, ��������� ����� �� ������� ����������:
c3 <- corrgram(dataset_log, order=TRUE, lower.panel = panel.pts, upper.panel = panel.pie)

# ������� �������� ������������� � B ����������:
lin_mod <- lm(B~A1+A2 + A3, data = dataset_log)
print(lin_mod)
summary(lin_mod)
# �� ����� ����� ��� Adj. R-sq. ����� 90.16%, ��� ��� ��� 1 ��������� � ��� �� �������� ��������������� ���������

lin_mod <- lm(B~A1+A2, data = dataset_log)
print(lin_mod)
summary(lin_mod)
# ����, ��� ���������� �������� ������������� ��������� ���� � �������� 1% �������, � Adj. R-sq. ������� �� ������ 90.71%. ��� �������� ����������.

# �������, ��������� ��� ����������� "�����������" ��������� ����������:
B_predict <- matrix(predict(lin_mod, dataset_log))
B_compare <- exp(cbind(dataset_log$B, B_predict))
View(B_compare)
# � ������ ������� - ������������ �������� ��������� ����������, �� ������ - ���������������.






















