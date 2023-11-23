import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';



class FingerPaint extends StatelessWidget {
  FingerPaint({
    required this.line
});

  List<Offset> line = [];

  @override
  Widget build(BuildContext context) {
    print("array points $line");
    return CustomPaint(
        //size: Size(300, 300),
        painter: MyPainter(line: line),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter({
    required this.line
});
  List<Offset> line = [];

  List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue
  ];
  final _random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final pointMode = ui.PointMode.polygon;
    // final points = [
    //   Offset(50, 100),
    //   Offset(150, 75),
    //   Offset(250, 250),
    //   Offset(130, 200),
    //   Offset(270, 100),
    // ];
    final points = line;
    final paint = Paint()
      ..color = colors[_random.nextInt(colors.length)]
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(pointMode, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
  }
}