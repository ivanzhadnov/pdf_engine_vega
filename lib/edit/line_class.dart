
import 'package:flutter/material.dart';

///класс описывающий рисуемую линию
class DrawLineItem{
  List<Offset> line = [];
  Color color = Colors.blue;
  double thickness = 4.0;
  List<List<Offset>> undoLine = [];
  Color undoColor = Colors.blue;
  double undoThickness = 4.0;
  String text = '';
  ///мы тyт указываем выделение текста это или рисование карандашем
  String subject;
  String uuid;
  DrawLineItem({
    required this.subject,
    required this.uuid
});

  toJson(){
    return {
      "color" : color,
      "thickness" : thickness,
      "line" : line,
      "subject" : subject,
      "uuid" : uuid
    };
  }
}