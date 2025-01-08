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

  // Check if a line intersects with any obstacle
  bool lineIntersectsObstacle(Offset start, Offset end) {
    for (var obstacle in obstacles) {
      Rect obstacleRect = Rect.fromCenter(
        center: obstacle.position,
        width: checkCategoryForSize(obstacle.category, 0),
        height: checkCategoryForSize(obstacle.category, 1),
      );
      
      if (lineIntersectsRect(start, end, obstacleRect)) {
        return true;
      }
    }
    return false;
  }

  // Check if a line intersects with a rectangle
  bool lineIntersectsRect(Offset start, Offset end, Rect rect) {
    var topLeft = rect.topLeft;
    var topRight = rect.topRight;
    var bottomLeft = rect.bottomLeft;
    var bottomRight = rect.bottomRight;

    return lineIntersectsLine(start, end, topLeft, topRight) ||
           lineIntersectsLine(start, end, topRight, bottomRight) ||
           lineIntersectsLine(start, end, bottomRight, bottomLeft) ||
           lineIntersectsLine(start, end, bottomLeft, topLeft);
  }

  // Check if two line segments intersect
  bool lineIntersectsLine(Offset line1Start, Offset line1End, Offset line2Start, Offset line2End) {
    double denominator = ((line2End.dy - line2Start.dy) * (line1End.dx - line1Start.dx)) -
                        ((line2End.dx - line2Start.dx) * (line1End.dy - line1Start.dy));

    if (denominator == 0) return false;

    double ua = (((line2End.dx - line2Start.dx) * (line1Start.dy - line2Start.dy)) -
                 ((line2End.dy - line2Start.dy) * (line1Start.dx - line2Start.dx))) / denominator;
    double ub = (((line1End.dx - line1Start.dx) * (line1Start.dy - line2Start.dy)) -
                 ((line1End.dy - line1Start.dy) * (line1Start.dx - line2Start.dx))) / denominator;

    return (ua >= 0 && ua <= 1) && (ub >= 0 && ub <= 1);
  }

  // Find nearest accessible intersection
  MapPoint findNearestAccessibleIntersection(Offset current, Set<MapPoint> excludeIntersections) {
    MapPoint? nearest;
    double minDistance = double.infinity;

    for (var intersection in intersections) {
      if (excludeIntersections.contains(intersection)) continue;
      
      if (!lineIntersectsObstacle(current, intersection.position)) {
        double distance = (intersection.position - current).distance;
        if (distance < minDistance) {
          minDistance = distance;
          nearest = intersection;
        }
      }
    }

    return nearest ?? intersections.first; // Fallback to first intersection if none found
  }

  // Calculate the complete route
  List<Offset> calculateRoute() {
    List<Offset> route = [];
    Set<MapPoint> usedIntersections = {};
    
    // Start from the entrance
    route.add(openings[0].position);
    Offset currentPosition = openings[0].position;

    // Process each selected product
    for (var product in products) {
      // Find path to product through intersections
      while (true) {
        if (!lineIntersectsObstacle(currentPosition, product.position)) {
          // Can reach product directly
          route.add(product.position);
          currentPosition = product.position;
          break;
        } else {
          // Need to go through an intersection
          MapPoint nextIntersection = findNearestAccessibleIntersection(
            currentPosition, 
            usedIntersections
          );
          route.add(nextIntersection.position);
          usedIntersections.add(nextIntersection);
          currentPosition = nextIntersection.position;
        }
      }
    }

    // Route to exit
    while (true) {
      if (!lineIntersectsObstacle(currentPosition, openings[1].position)) {
        route.add(openings[1].position);
        break;
      } else {
        MapPoint nextIntersection = findNearestAccessibleIntersection(
          currentPosition, 
          usedIntersections
        );
        route.add(nextIntersection.position);
        usedIntersections.add(nextIntersection);
        currentPosition = nextIntersection.position;
      }
    }

    return route;
  }

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

    // Draw route if there are selected products
    if (products.isNotEmpty) {
      List<Offset> route = calculateRoute();
      final path = Path();
      path.moveTo(route.first.dx, route.first.dy);
      
      for (int i = 1; i < route.length; i++) {
        path.lineTo(route[i].dx, route[i].dy);
      }
      
      canvas.drawPath(path, routePaint);
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