import 'dart:math';
import 'package:flutter/material.dart';

///находим вхождение точки (в нашем случае нарисованой кривой анотации) в окружность (в нашем случае маркер ластика)
bool belongsToCircle({required double x, required double y, required double centerX, required double centerY, required double radius}) {
  //double distance = (x - centerX).pow(2) + (y - centerY).pow(2);
  double distance = (pow((y - centerY), 2,) + pow((x - centerX),2,)).toDouble();
  double radiusSquared = radius * radius;

  return distance <= radiusSquared;
}

void test() {
  // Координаты центра окружности и её радиус
  double circleCenterX = 2;
  double circleCenterY = 3;
  double circleRadius = 5;

  // Точка для проверки
  double pointX = 4;
  double pointY = 1;

  // Проверяем принадлежность точки к окружности
  bool belongs = belongsToCircle(x: pointX, y: pointY, centerX: circleCenterX, centerY: circleCenterY, radius: circleRadius);

  if (belongs) {
    print('Точка принадлежит окружности.');
  } else {
    print('Точка не принадлежит окружности.');
  }
}