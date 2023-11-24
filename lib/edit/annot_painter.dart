import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'annot_buttons.dart';

///механизм рисования создаваемой аннотации на экране
class FingerPaint extends StatefulWidget {

  FingerPaint({
    super.key,
    required this.line,
    required this.mode
  });
  ///массив Offset для формирования кривой
  List<Offset> line = [];
  ///какой режим выбран, такое оформление и задавать линии
  AnnotState mode;

  @override
  FingerPaintState createState() => FingerPaintState();

}

class FingerPaintState extends State<FingerPaint> {


  @override
  Widget build(BuildContext context) {
    //print("array points $line");
    return CustomPaint(
        //size: Size(300, 300),
        painter: MyPainter(line: widget.line, mode: widget.mode),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter({
    required this.line,
    required this.mode
});
  List<Offset> line = [];
  AnnotState mode;

  List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Color(0xFF00ff00)
  ];
  final _random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    const pointMode = ui.PointMode.polygon;
    final points = line;
    final paint = Paint()
      //..color = colors[_random.nextInt(colors.length)]
      ..color = mode == AnnotState.freeForm ? colors[3] : colors[4].withOpacity(0.4)
      ..strokeWidth = mode == AnnotState.freeForm ? 4 : 12
      ..strokeCap = mode == AnnotState.freeForm ? StrokeCap.round : StrokeCap.square;
    canvas.drawPoints(pointMode, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return true;
  }
}