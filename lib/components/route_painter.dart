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

  List<Offset> _findShortestRoute() {
    if (products.isEmpty) return [];

    // Create a graph of all valid connections between points
    Map<Offset, List<PathSegment>> graph = _buildGraph();
    
    // Find the shortest path that visits all selected products
    return _findShortestPathVisitingAll(graph);
  }

  Map<Offset, List<PathSegment>> _buildGraph() {
    Map<Offset, List<PathSegment>> graph = {};
    List<Offset> allPoints = [
      openings[0].position, // Start
      ...intersections.map((i) => i.position),
      ...products.map((p) => p.position),
    ];

    // Only add the end point if we have products to visit
    if (products.isNotEmpty) {
      allPoints.add(openings[1].position); // End
    }

    // Build connections between all points
    for (var from in allPoints) {
      graph[from] = [];
      for (var to in allPoints) {
        if (from != to && !_intersectsObstacle(from, to)) {
          graph[from]!.add(
            PathSegment(to, _calculateDistance(from, to))
          );
        }
      }
    }

    return graph;
  }

  List<Offset> _findShortestPathVisitingAll(Map<Offset, List<PathSegment>> graph) {
    Set<Offset> productPositions = products.map((p) => p.position).toSet();
    List<Offset> bestPath = [];
    double bestDistance = double.infinity;

    // Start position is always the opening
    Offset startPos = openings[0].position;
    
    void findPath(List<Offset> currentPath, Set<Offset> remainingProducts, double currentDistance) {
      // If current distance is already worse than best, stop this branch
      if (currentDistance >= bestDistance) return;

      // If we've visited all products
      if (remainingProducts.isEmpty) {
        // Add path to exit if we haven't already
        if (products.isNotEmpty) {
          Offset currentPos = currentPath.last;
          List<Offset> pathToExit = _findShortestPathToPoint(
            graph, 
            currentPos, 
            openings[1].position
          );
          
          if (pathToExit.isNotEmpty) {
            double totalDistance = currentDistance + 
                _calculatePathDistance(pathToExit);
            
            if (totalDistance < bestDistance) {
              bestDistance = totalDistance;
              bestPath = [...currentPath, ...pathToExit.skip(1)];
            }
          }
        }
        return;
      }

      // Try each remaining product as next destination
      Offset currentPos = currentPath.last;
      for (var nextProduct in remainingProducts) {
        // Find shortest path to this product
        List<Offset> pathToProduct = _findShortestPathToPoint(
          graph, 
          currentPos, 
          nextProduct
        );
        
        if (pathToProduct.isNotEmpty) {
          double additionalDistance = _calculatePathDistance(pathToProduct);
          Set<Offset> newRemaining = Set.from(remainingProducts)..remove(nextProduct);
          
          findPath(
            [...currentPath, ...pathToProduct.skip(1)],
            newRemaining,
            currentDistance + additionalDistance
          );
        }
      }

      // If no path found, try routing to the nearest intersection and continue
      Offset nearestIntersection = _findNearestIntersection(currentPos, remainingProducts);
      if (nearestIntersection != null) {
        List<Offset> pathToIntersection = _findShortestPathToPoint(graph, currentPos, nearestIntersection);
        if (pathToIntersection.isNotEmpty) {
          findPath(
            [...currentPath, ...pathToIntersection.skip(1)],
            remainingProducts,
            currentDistance + _calculatePathDistance(pathToIntersection)
          );
        }
      }
    }

    // Start the recursive search
    findPath([startPos], productPositions, 0);
    return bestPath;
  }

  List<Offset> _findShortestPathToPoint(
    Map<Offset, List<PathSegment>> graph, 
    Offset start, 
    Offset end
  ) {
    Map<Offset, double> distances = {start: 0};
    Map<Offset, Offset?> previous = {start: null};
    PriorityQueue<QueueItem> queue = PriorityQueue<QueueItem>();
    Set<Offset> visited = {};

    queue.add(QueueItem(start, 0));

    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      
      if (current.point == end) {
        // Reconstruct path
        List<Offset> path = [];
        Offset? currentPoint = end;
        while (currentPoint != null) {
          path.add(currentPoint);
          currentPoint = previous[currentPoint];
        }
        return path.reversed.toList();
      }

      //if (visited.contains(current.point)) continue;
      visited.add(current.point);

      for (var segment in graph[current.point] ?? []) {
        double newDistance = distances[current.point]! + segment.distance;
        
        if (!distances.containsKey(segment.point) || 
            newDistance < distances[segment.point]!) {
          distances[segment.point] = newDistance;
          previous[segment.point] = current.point;
          queue.add(QueueItem(segment.point, newDistance));
        }
      }
    }

    return []; // No path found
  }

  double _calculatePathDistance(List<Offset> path) {
    double distance = 0;
    for (int i = 0; i < path.length - 1; i++) {
      distance += _calculateDistance(path[i], path[i + 1]);
    }
    return distance;
  }

  bool _intersectsObstacle(Offset start, Offset end) {
    for (var obstacle in obstacles) {
      Rect obstacleRect = Rect.fromCenter(
        center: obstacle.position,
        width: checkCategoryForSize(obstacle.category, 0),
        height: checkCategoryForSize(obstacle.category, 1),
      );
      
      if (_lineIntersectsRect(start, end, obstacleRect)) {
        return true;
      }
    }
    return false;
  }

  bool _lineIntersectsRect(Offset start, Offset end, Rect rect) {
    if (rect.contains(start) || rect.contains(end)) return true;
    
    List<List<Offset>> edges = [
      [Offset(rect.left, rect.top), Offset(rect.right, rect.top)],
      [Offset(rect.right, rect.top), Offset(rect.right, rect.bottom)],
      [Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom)],
      [Offset(rect.left, rect.bottom), Offset(rect.left, rect.top)],
    ];
    
    for (var edge in edges) {
      if (_linesIntersect(start, end, edge[0], edge[1])) {
        return true;
      }
    }
    
    return false;
  }

  bool _linesIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
    double denominator = ((b2.dy - b1.dy) * (a2.dx - a1.dx)) -
        ((b2.dx - b1.dx) * (a2.dy - a1.dy));
    
    if (denominator == 0) return false;
    
    double ua = (((b2.dx - b1.dx) * (a1.dy - b1.dy)) -
        ((b2.dy - b1.dy) * (a1.dx - b1.dx))) /
        denominator;
    double ub = (((a2.dx - a1.dx) * (a1.dy - b1.dy)) -
        ((a2.dy - a1.dy) * (a1.dx - b1.dx))) /
        denominator;
    
    return (ua >= 0 && ua <= 1) && (ub >= 0 && ub <= 1);
  }

  double _calculateDistance(Offset a, Offset b) {
    return sqrt(pow(b.dx - a.dx, 2) + pow(b.dy - a.dy, 2));
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

    // Draw route
    if (products.isNotEmpty) {
      List<Offset> route = _findShortestRoute();
      if (route.isNotEmpty) {
        final path = Path();
        path.moveTo(route[0].dx, route[0].dy);

        for (int i = 1; i < route.length; i++) {
          path.lineTo(route[i].dx, route[i].dy);
        }

        // Debugging output to check if the path is valid
        print("Drawing path: $route");

        canvas.drawPath(path, routePaint);
      } else {
        print("No route found");
      }
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

  Offset _findNearestIntersection(Offset currentPos, Set<Offset> remainingProducts) {
    // Find nearest intersection among the available ones
    Offset nearestIntersection = Offset(0, 0);
    double nearestDistance = double.infinity;

    for (var intersection in intersections) {
      double distance = _calculateDistance(currentPos, intersection.position);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIntersection = intersection.position;
      }
    }

    return nearestIntersection;
  }
}

// Helper classes for the algorithm
class PathSegment {
  final Offset point;
  final double distance;

  PathSegment(this.point, this.distance);
}

class QueueItem implements Comparable<QueueItem> {
  final Offset point;
  final double priority;

  QueueItem(this.point, this.priority);

  @override
  int compareTo(QueueItem other) {
    return priority.compareTo(other.priority);
  }
}