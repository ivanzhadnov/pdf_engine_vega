import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

///class MapPage extends StatefulWidget {
//   final bool centerRoute;
//   MapPage({this.centerRoute = false}) : super();
//
//   @override
//   MainMapPageState createState() => MainMapPageState();
// }

class FingerPaint extends StatefulWidget {
  FingerPaint({
    required this.line
  });
  List<Offset> line = [];

  @override
  FingerPaintState createState() => FingerPaintState();

}

class FingerPaintState extends State<FingerPaint> {


  @override
  Widget build(BuildContext context) {
    //print("array points $line");
    return CustomPaint(
        //size: Size(300, 300),
        painter: MyPainter(line: widget.line),
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
      //..color = colors[_random.nextInt(colors.length)]
      ..color = colors.first.withOpacity(0.2)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(pointMode, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return true;
  }
}