import 'package:flutter/material.dart';

// Cutting the map to handle multiple screen sizes

Widget croppedMapFill({
  required BuildContext context,
  required String assetPath,
  required double imageWidth,
  required double imageHeight,
  required double cropLeft,
  required double cropTop,
  required double cropWidth,
  required double cropHeight,
}) {
  final screenW = MediaQuery.of(context).size.width;
  final screenH = MediaQuery.of(context).size.height;

  final imageAspect = cropWidth / cropHeight;
  final screenAspect = screenW / screenH;

  double scale;
  if (screenAspect > imageAspect) {
    // screen is wider → fill width, adjust height
    scale = screenW / cropWidth;
  } else {
    // screen is taller → fill height, adjust width
    scale = screenH / cropHeight;
  }

  final matrix = Matrix4.identity()
    ..translate(-cropLeft, -cropTop)
    ..scale(scale, scale, 1.0);

  return SizedBox(
    width: screenW,
    height: screenH,
    child: ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        alignment: Alignment.topLeft,
        child: Transform(
          transform: matrix,
          alignment: Alignment.topLeft,
          child: Image.asset(
            assetPath,
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.none, // keep original pixels
            alignment: Alignment.topLeft,
          ),
        ),
      ),
    ),
  );
}
