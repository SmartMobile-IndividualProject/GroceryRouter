import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:groceryrouter/components/map_point.dart';
import 'dart:math';
import 'dart:collection';

class RoutePainter extends CustomPainter {
  final List<MapPoint> products;
  final List<MapPoint> intersections;
  final List<MapPoint> obstacles;
  final List<MapPoint> openings;
  final double imageWidth;
  final double imageHeight;
  static const double circleRadius = 5.0;
  static const double strokeWidth = 1.5;
  static const List<double> rectLong = [15, 70];
  static const List<double> rectShort = [15, 40];
  static const List<double> rectWide = [60, 15];

  RoutePainter({
    required this.products,
    required this.intersections,
    required this.obstacles,
    required this.openings,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint circleFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint circleStrokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Paint startMarkerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    final Paint endMarkerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final Paint intersectionPaint = Paint()
      ..color = const Color.fromARGB(255, 30, 27, 212)
      ..style = PaintingStyle.fill;
    final Paint obstaclePaint = Paint()
      ..color = const Color.fromARGB(100, 255, 255, 255)
      ..style = PaintingStyle.fill;
    final Paint routePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Draw products
    for (var point in products) {
      canvas.drawCircle(point.position, circleRadius, circleFillPaint);
      canvas.drawCircle(point.position, circleRadius, circleStrokePaint);
    }

    // Draw start/end markers
    canvas.drawCircle(openings[0].position, circleRadius, startMarkerPaint);
    canvas.drawCircle(openings[0].position, circleRadius, circleStrokePaint);
    canvas.drawCircle(openings[1].position, circleRadius, endMarkerPaint);
    canvas.drawCircle(openings[1].position, circleRadius, circleStrokePaint);

    // Draw intersections
    for (var intersection in intersections) {
      canvas.drawCircle(intersection.position, 2.0, intersectionPaint);
      canvas.drawCircle(intersection.position, 2.0, circleStrokePaint);
    }

    // Draw obstacles
    for (var obstacle in obstacles) {
      canvas.drawRect(
        Rect.fromCenter(
          center: obstacle.position,
          width: checkCategoryForSize(obstacle.category, 0),
          height: checkCategoryForSize(obstacle.category, 1),
        ),
        obstaclePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  double checkCategoryForSize(String category, int value) {
    double size = 0.0;
    switch (category) {
      case 'RectLong':
        size = rectLong[value];
        break;
      case 'RectShort':
        size = rectShort[value];
        break;
      case 'RectWide':
        size = rectWide[value];
        break;
    }
    return size;
  }
}