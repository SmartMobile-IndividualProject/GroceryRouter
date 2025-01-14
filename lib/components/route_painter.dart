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
  static const List<double> rectLong = [15, 85];
  static const List<double> rectShort = [15, 40];
  static const List<double> rectWide = [60, 15];
  
  late final List<Rect> obstacleRects;
  List<Offset>? _cachedRoute;

  RoutePainter({
    required this.products,
    required this.intersections,
    required this.obstacles,
    required this.openings,
    required this.imageWidth,
    required this.imageHeight,
  }) {
    obstacleRects = obstacles.map((obstacle) => Rect.fromCenter(
      center: obstacle.position,
      width: checkCategoryForSize(obstacle.category, 0),
      height: checkCategoryForSize(obstacle.category, 1),
    )).toList();
  }

  bool lineIntersectsObstacle(Offset start, Offset end) {
    return obstacleRects.any((rect) => lineIntersectsRect(start, end, rect));
  }

  bool lineIntersectsRect(Offset start, Offset end, Rect rect) {
    Rect bounds = Rect.fromPoints(start, end);
    if (!bounds.overlaps(rect)) return false;
    
    var rectLines = [
      [rect.topLeft, rect.topRight],
      [rect.topRight, rect.bottomRight],
      [rect.bottomRight, rect.bottomLeft],
      [rect.bottomLeft, rect.topLeft],
    ];

    return rectLines.any((line) => linesIntersect(start, end, line[0], line[1])) ||
           rect.contains(start) || rect.contains(end);
  }

  bool linesIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
    Rect boundsA = Rect.fromPoints(a1, a2);
    Rect boundsB = Rect.fromPoints(b1, b2);
    if (!boundsA.overlaps(boundsB)) return false;

    double orientationTest(Offset p, Offset q, Offset r) {
      return (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
    }

    double o1 = orientationTest(a1, a2, b1);
    double o2 = orientationTest(a1, a2, b2);
    double o3 = orientationTest(b1, b2, a1);
    double o4 = orientationTest(b1, b2, a2);

    return (o1 * o2 < 0) && (o3 * o4 < 0);
  }

  // Find nearest intersection that's closer to the target
  MapPoint? findNearestIntersectionTowardsTarget(Offset current, Offset target) {
    var candidateIntersections = intersections.where((intersection) {
      // Check if intersection is closer to target than current position
      double distanceToTarget = (target - intersection.position).distance;
      double currentToTarget = (target - current).distance;
      
      // Ensure the intersection is closer to the target and path is clear
      return distanceToTarget < currentToTarget &&
             !lineIntersectsObstacle(current, intersection.position);
    }).toList();

    if (candidateIntersections.isEmpty) return null;

    // Sort by combined distance (current to intersection + intersection to target)
    candidateIntersections.sort((a, b) {
      double distA = (a.position - current).distance + (a.position - target).distance;
      double distB = (b.position - current).distance + (b.position - target).distance;
      return distA.compareTo(distB);
    });

    return candidateIntersections.first;
  }

List<Offset> findPathBetweenPoints(Offset start, Offset target, bool isProductToProduct) {
    List<Offset> path = [start];
    Offset current = start;
    Set<Offset> visitedIntersections = {};
    bool justCollectedProduct = isProductToProduct;

    while (current != target) {
      // After collecting a product, we must go to an intersection first
      if (justCollectedProduct) {
        var nextIntersection = findBestIntersectionAfterProduct(current, target);
        if (nextIntersection != null) {
          path.add(nextIntersection.position);
          current = nextIntersection.position;
          visitedIntersections.add(current);
          justCollectedProduct = false;
          continue;
        }
      }

      // Try direct path to target if possible
      if (!justCollectedProduct && !lineIntersectsObstacle(current, target)) {
        path.add(target);
        break;
      }

      // Find next best intersection
      MapPoint? nextIntersection = findNearestIntersectionTowardsTarget(current, target);

      // If no valid intersection found or we're in a cycle
      if (nextIntersection == null || visitedIntersections.contains(nextIntersection.position)) {
        // Try to find any valid intersection as last resort
        var lastResortIntersection = findLastResortIntersection(current, target, visitedIntersections);
        
        if (lastResortIntersection != null) {
          path.add(lastResortIntersection.position);
          current = lastResortIntersection.position;
          visitedIntersections.add(current);
          justCollectedProduct = false;
        } else {
          // If we really can't find any valid path, force through nearest valid intersection
          var forcedPath = forceThroughNearestValidIntersection(current, target);
          if (forcedPath.isNotEmpty) {
            path.addAll(forcedPath.skip(1));
          }
          break;
        }
      } else {
        path.add(nextIntersection.position);
        current = nextIntersection.position;
        visitedIntersections.add(current);
        justCollectedProduct = false;
      }
    }

    return path;
  }

  MapPoint? findBestIntersectionAfterProduct(Offset current, Offset target) {
    // Find intersections that are both accessible from current position and provide a path to target
    var validIntersections = intersections.where((intersection) {
      bool accessibleFromCurrent = !lineIntersectsObstacle(current, intersection.position);
      bool providesPathToTarget = canEventuallyReachTarget(intersection.position, target);
      return accessibleFromCurrent && providesPathToTarget;
    }).toList();

    if (validIntersections.isEmpty) return null;

    // Sort intersections by a combination of:
    // 1. Distance from current position
    // 2. Distance to target
    // 3. Number of clear paths to other intersections
    validIntersections.sort((a, b) {
      double scoreA = calculateIntersectionScore(a, current, target);
      double scoreB = calculateIntersectionScore(b, current, target);
      return scoreA.compareTo(scoreB);
    });

    return validIntersections.first;
  }

  double calculateIntersectionScore(MapPoint intersection, Offset current, Offset target) {
    double distanceToCurrent = (intersection.position - current).distance;
    double distanceToTarget = (intersection.position - target).distance;
    int clearPaths = countClearPathsToOtherIntersections(intersection);
    
    // Weighted scoring - adjust weights to fine-tune behavior
    return distanceToCurrent * 0.4 + distanceToTarget * 0.4 - clearPaths * 0.2;
  }

  int countClearPathsToOtherIntersections(MapPoint intersection) {
    return intersections
        .where((other) => other != intersection &&
            !lineIntersectsObstacle(intersection.position, other.position))
        .length;
  }

  bool canEventuallyReachTarget(Offset current, Offset target) {
    // Check if target can be reached directly
    if (!lineIntersectsObstacle(current, target)) return true;

    // Check if target can be reached through any intersection
    return intersections.any((intersection) =>
        !lineIntersectsObstacle(current, intersection.position) &&
        !lineIntersectsObstacle(intersection.position, target));
  }

  MapPoint? findLastResortIntersection(
      Offset current, Offset target, Set<Offset> visitedIntersections) {
    var candidates = intersections.where((i) =>
        !visitedIntersections.contains(i.position) &&
        !lineIntersectsObstacle(current, i.position) &&
        canEventuallyReachTarget(i.position, target));

    if (candidates.isEmpty) return null;

    return candidates.reduce((a, b) {
      double scoreA = calculateIntersectionScore(a, current, target);
      double scoreB = calculateIntersectionScore(b, current, target);
      return scoreA < scoreB ? a : b;
    });
  }

  List<Offset> forceThroughNearestValidIntersection(Offset current, Offset target) {
  var bestIntersection = intersections
      .where((i) =>
          !lineIntersectsObstacle(current, i.position) &&
          !lineIntersectsObstacle(i.position, target))
      .reduce((a, b) {
          var aDistance = (a.position - current).distance + (a.position - target).distance;
          var bDistance = (b.position - current).distance + (b.position - target).distance;
          return aDistance < bDistance ? a : b;
    });
    if (bestIntersection != null) {
      return [current, bestIntersection.position, target];
    }
    return [];
  }

  List<Offset> generateRoute() {
    if (_cachedRoute != null) return _cachedRoute!;

    List<Offset> route = [];
    Offset currentPos = openings[0].position;

    // Start to first product
    var initialPath = findPathBetweenPoints(currentPos, products.first.position, false);
    route.addAll(initialPath);
    currentPos = products.first.position;

    // Between products
    for (int i = 1; i < products.length; i++) {
      var path = findPathBetweenPoints(currentPos, products[i].position, true);  // Force intersection
      route.addAll(path.skip(1));  // Skip first point as it's already in route
      currentPos = products[i].position;
    }

    // Last product to end
    if (products.isNotEmpty) {
      var pathToEnd = findPathBetweenPoints(currentPos, openings[1].position, false);
      route.addAll(pathToEnd.skip(1));
    }

    _cachedRoute = route;
    return route;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawStaticElements(canvas);

    if (products.isNotEmpty) {
      _drawRoute(canvas);
    }
  }

  void _drawStaticElements(Canvas canvas) {
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
      ..color = const Color.fromARGB(0, 30, 27, 212)
      ..style = PaintingStyle.fill;
    final Paint obstaclePaint = Paint()
      ..color = const Color.fromARGB(0, 255, 255, 255)
      ..style = PaintingStyle.fill;

    for (var rect in obstacleRects) {
      canvas.drawRect(rect, obstaclePaint);
    }

    for (var point in products) {
      canvas.drawCircle(point.position, circleRadius, circleFillPaint);
      canvas.drawCircle(point.position, circleRadius, circleStrokePaint);
    }

    for (var intersection in intersections) {
      canvas.drawCircle(intersection.position, 2.0, intersectionPaint);
    }

    canvas.drawCircle(openings[0].position, circleRadius, startMarkerPaint);
    canvas.drawCircle(openings[0].position, circleRadius, circleStrokePaint);
    canvas.drawCircle(openings[1].position, circleRadius, endMarkerPaint);
    canvas.drawCircle(openings[1].position, circleRadius, circleStrokePaint);
  }

  void _drawRoute(Canvas canvas) {
    List<Offset> route = generateRoute();
    
    for (int i = 0; i < route.length - 1; i++) {
      double progress = i / (route.length - 1);
      final Paint routePaint = Paint()
        ..color = Color.lerp(
          const Color.fromARGB(255, 90, 20, 100),
          const Color.fromARGB(255, 200, 180, 220),
          progress,
        )!
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(route[i], route[i + 1], routePaint);
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