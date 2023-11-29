import 'package:flutter/material.dart';


///виджет ластика
class AnnotEraser extends StatelessWidget {
  Offset erasePosition;
  double eraseRadius;
  AnnotEraser({required this.eraseRadius, required this.erasePosition, super.key });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: erasePosition.dy - eraseRadius,
      left: erasePosition.dx - eraseRadius,
      child: Container(
        width: eraseRadius * 2,
        height: eraseRadius * 2,
        decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle
        ),
      ),
    );
  }
}