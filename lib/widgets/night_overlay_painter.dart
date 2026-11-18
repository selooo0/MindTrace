import 'package:flutter/material.dart';

// this widget responsible of showing the night and day mode
// and display the circle around the player

class NightOverlayPainter extends CustomPainter {
  final Offset carPosition;
  final double radius;
  final double opacity;

  NightOverlayPainter({
    required this.carPosition,
    required this.radius,
    this.opacity = 0.95,
  });

  @override
  void paint(Canvas canvas, Size size) {

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    Paint darkness = Paint()..color = Colors.black.withOpacity(opacity);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkness);

    Paint cutOut = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = Colors.white;
    canvas.drawCircle(carPosition, radius, cutOut);
    canvas.restore();

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}