import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'annot_buttons.dart';

///механизм рисования создаваемой аннотации на экране
class FingerPaint extends StatefulWidget {

  FingerPaint({
    super.key,
    required this.line,
    required this.mode,
    required this.color,
    required this.thickness
  });
  ///массив Offset для формирования кривой
  List<Offset> line = [];
  ///какой режим выбран, такое оформление и задавать линии
  AnnotState mode;
  ///цвет линии рисования
  Color color;
  ///толщина линии рисования
  double thickness;

  @override
  FingerPaintState createState() => FingerPaintState();

}

class FingerPaintState extends State<FingerPaint> {


  @override
  Widget build(BuildContext context) {
    //print("array points ${widget.color.value}");
    return CustomPaint(
        //size: Size(300, 300),
        painter: MyPainter(line: widget.line, mode: widget.mode, color: widget.color, thickness: widget.thickness),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter({
    required this.line,
    required this.mode,
    required this.color,
    required this.thickness
});
  List<Offset> line = [];
  AnnotState mode;
  Color color;
  double thickness;

  List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Color(0xFF00ff00),
    Colors.white
  ];
  final _random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    const pointMode = ui.PointMode.polygon;
    final points = line;
    final paint = Paint()
      //..color = colors[_random.nextInt(colors.length)]
      ..color = mode == AnnotState.freeForm ? color : mode == AnnotState.erase ? Colors.white : Colors.transparent
      ..strokeWidth = mode == AnnotState.freeForm ? thickness : 12
      ..strokeCap = mode == AnnotState.freeForm ? StrokeCap.round : StrokeCap.square;
    canvas.drawPoints(pointMode, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return true;
  }
}