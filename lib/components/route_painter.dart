import 'package:flutter/material.dart';
import 'package:groceryrouter/components/map_point.dart';

class RoutePainter extends CustomPainter {
  final List<MapPoint> products;
  final List<MapPoint> intersections;
  final List<MapPoint> openings;
  final double imageWidth;
  final double imageHeight;
  static const double circleRadius = 5.0;
  static const double strokeWidth = 1.5;

  RoutePainter({
    required this.products,
    required this.intersections,
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

    final Paint routePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final Paint startMarkerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final Paint endMarkerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final Paint intersectionPaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    for (var point in products) {
      canvas.drawCircle(point.position, circleRadius, circleFillPaint);
      canvas.drawCircle(point.position, circleRadius, circleStrokePaint);
    }
    
    canvas.drawCircle(openings[0].position, circleRadius, startMarkerPaint);
    canvas.drawCircle(openings[0].position, circleRadius, circleStrokePaint);

    canvas.drawCircle(openings[1].position, circleRadius, endMarkerPaint);
    canvas.drawCircle(openings[1].position, circleRadius, circleStrokePaint);
  
    for (var intersection in intersections) {
      canvas.drawCircle(intersection.position, 0.1, intersectionPaint);
      canvas.drawCircle(intersection.position, 0.1, circleStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}