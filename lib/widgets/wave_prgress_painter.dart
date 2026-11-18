import 'dart:math';

import 'package:flutter/material.dart';

//this one show in each suspect card a waved blue background

class WaveProgressPainter extends CustomPainter {
  final double progress;
  WaveProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;
    final height = size.height * (1 - progress);
    final paint = Paint()..color = Colors.blueAccent.withOpacity(0.4);

    final path = Path();
    path.moveTo(0, height);
    for (double x = 0; x <= size.width; x++) {
      final y = height + sin(x / 15) * 5;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
