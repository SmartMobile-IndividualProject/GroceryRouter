import 'dart:math';

import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final String category;
  final Offset position;
  bool isSelected;

  CategoryItem({
    required this.name,
    required this.category,
    required this.position,
    this.isSelected = false,
  });
}

// Node class for A* pathfinding
class PathNode {
  final int x;
  final int y;
  double g = 0; // Cost from start to this node
  double h = 0; // Estimated cost from this node to end
  double get f => g + h; // Total cost
  PathNode? parent;

  PathNode(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathNode && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class MapBase extends StatefulWidget {
  const MapBase({super.key});

  @override
  _MapBaseState createState() => _MapBaseState();
}

class _MapBaseState extends State<MapBase> {
  List<CategoryItem> selectedPoints1 = [];
  List<CategoryItem> selectedPoints2 = [];
  bool isImage1 = true;
  double imageWidth = 350;
  double imageHeight = 250;
  String selectedImage = 'Image 1';

  // Define grid size for pathfinding
  static const int gridWidth = 35; // Number of cells horizontally
  static const int gridHeight = 25; // Number of cells vertically

  // Define obstacles (colored boxes) - Coordinates in grid cells
  final List<Rect> obstacles = [
    Rect.fromLTWH(5, 5, 5, 5),    // Example obstacle
    Rect.fromLTWH(15, 10, 5, 5),  // Example obstacle
    Rect.fromLTWH(25, 15, 5, 5),  // Example obstacle
  ];

  final Map<String, List<CategoryItem>> categoryItems = {
    'Destinations': [
      CategoryItem(
        name: 'Airport',
        category: 'Destinations',
        position: Offset(50, 50),
      ),
      CategoryItem(
        name: 'Hotel',
        category: 'Destinations',
        position: Offset(150, 100),
      ),
      CategoryItem(
        name: 'Restaurant',
        category: 'Destinations',
        position: Offset(250, 150),
      ),
    ],
    'Activities': [
      CategoryItem(
        name: 'Hiking',
        category: 'Activities',
        position: Offset(100, 200),
      ),
      CategoryItem(
        name: 'Swimming',
        category: 'Activities',
        position: Offset(200, 75),
      ),
      CategoryItem(
        name: 'Shopping',
        category: 'Activities',
        position: Offset(300, 125),
      ),
    ],
    'Transport': [
      CategoryItem(
        name: 'Bus',
        category: 'Transport',
        position: Offset(75, 150),
      ),
      CategoryItem(
        name: 'Train',
        category: 'Transport',
        position: Offset(175, 175),
      ),
      CategoryItem(
        name: 'Taxi',
        category: 'Transport',
        position: Offset(275, 100),
      ),
    ],
  };

  // Convert screen coordinates to grid coordinates
  Point<int> screenToGrid(Offset position) {
    int x = (position.dx * gridWidth / imageWidth).floor();
    int y = (position.dy * gridHeight / imageHeight).floor();
    return Point(x, y);
  }

  // Convert grid coordinates to screen coordinates
  Offset gridToScreen(int x, int y) {
    double screenX = x * imageWidth / gridWidth;
    double screenY = y * imageHeight / gridHeight;
    return Offset(screenX, screenY);
  }

  // Check if a grid cell is walkable (not in an obstacle)
  bool isWalkable(int x, int y) {
    Offset screenPos = gridToScreen(x, y);
    for (var obstacle in obstacles) {
      if (obstacle.contains(screenPos)) {
        return false;
      }
    }
    return true;
  }

  // Get valid neighbors for a node
  List<PathNode> getNeighbors(PathNode node) {
    List<PathNode> neighbors = [];
    final directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1],  // Cardinal directions
      [-1, -1], [-1, 1], [1, -1], [1, 1]  // Diagonal directions
    ];

    for (var dir in directions) {
      int newX = node.x + dir[0];
      int newY = node.y + dir[1];

      if (newX >= 0 && newX < gridWidth && 
          newY >= 0 && newY < gridHeight && 
          isWalkable(newX, newY)) {
        neighbors.add(PathNode(newX, newY));
      }
    }

    return neighbors;
  }

  // Calculate heuristic (Manhattan distance)
  double heuristic(PathNode a, PathNode b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
  }

  // A* pathfinding algorithm
  List<Offset> findPath(Offset start, Offset end) {
    Point<int> startGrid = screenToGrid(start);
    Point<int> endGrid = screenToGrid(end);

    PathNode startNode = PathNode(startGrid.x, startGrid.y);
    PathNode endNode = PathNode(endGrid.x, endGrid.y);

    List<PathNode> openSet = [startNode];
    Set<PathNode> closedSet = {};

    while (openSet.isNotEmpty) {
      PathNode current = openSet.reduce((a, b) => a.f < b.f ? a : b);

      if (current == endNode) {
        // Reconstruct path
        List<Offset> path = [];
        PathNode? node = current;
        while (node != null) {
          path.add(gridToScreen(node.x, node.y));
          node = node.parent;
        }
        return path.reversed.toList();
      }

      openSet.remove(current);
      closedSet.add(current);

      for (var neighbor in getNeighbors(current)) {
        if (closedSet.contains(neighbor)) continue;

        double tentativeG = current.g + 1;

        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        } else if (tentativeG >= neighbor.g) {
          continue;
        }

        neighbor.parent = current;
        neighbor.g = tentativeG;
        neighbor.h = heuristic(neighbor, endNode);
      }
    }

    // If no path found, return direct line
    return [start, end];
  }

  void showSelectionDialog() {
    categoryItems.forEach((category, items) {
      items.forEach((item) => item.isSelected = false);
    });
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Items'),
                  TextButton(
                    onPressed: () {
                      List<CategoryItem> selectedItems = [];
                      categoryItems.forEach((category, items) {
                        selectedItems.addAll(
                          items.where((item) => item.isSelected),
                        );
                      });
                      
                      this.setState(() {
                        if (isImage1) {
                          selectedPoints1 = List.from(selectedItems);
                        } else {
                          selectedPoints2 = List.from(selectedItems);
                        }
                      });
                      
                      Navigator.of(context).pop();
                    },
                    child: Text('Confirm'),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: categoryItems.entries.map((category) {
                    return ExpansionTile(
                      title: Text(category.key),
                      children: category.value.map((item) {
                        return CheckboxListTile(
                          title: Text(item.name),
                          value: item.isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              item.isSelected = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: imageWidth,
                height: imageHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 4.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Stack(
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: Image.asset(
                          isImage1 ? 'assets/map_prototype.png' : 'assets/map_prototype_2.png',
                          key: ValueKey(isImage1),
                          fit: BoxFit.cover,
                        ),
                      ),
                      CustomPaint(
                        size: Size(imageWidth, imageHeight),
                        painter: PointsAndRoutePainter(
                          points: isImage1 ? selectedPoints1 : selectedPoints2,
                          imageWidth: imageWidth,
                          imageHeight: imageHeight,
                          findPath: findPath,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Select Image'),
                          content: DropdownButton<String>(
                            value: selectedImage,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedImage = newValue!;
                                isImage1 = selectedImage == 'Image 1';
                              });
                              Navigator.of(context).pop();
                            },
                            items: <String>['Image 1', 'Image 2']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                  child: Text('Switch'),
                ),
                ElevatedButton(
                  onPressed: showSelectionDialog,
                  child: Text('Add'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isImage1) {
                        selectedPoints1.clear();
                      } else {
                        selectedPoints2.clear();
                      }
                    });
                  },
                  child: Text('Reset'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PointsAndRoutePainter extends CustomPainter {
  final List<CategoryItem> points;
  final double imageWidth;
  final double imageHeight;
  final Function(Offset, Offset) findPath;
  static const double circleRadius = 6.0;
  static const double strokeWidth = 2.0;

  PointsAndRoutePainter({
    required this.points,
    required this.imageWidth,
    required this.imageHeight,
    required this.findPath,
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
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Draw routes between points using pathfinding
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        List<Offset> pathPoints = findPath(points[i].position, points[i + 1].position);
        
        if (pathPoints.length > 1) {
          Path path = Path();
          path.moveTo(pathPoints.first.dx, pathPoints.first.dy);
          
          for (int j = 1; j < pathPoints.length; j++) {
            path.lineTo(pathPoints[j].dx, pathPoints[j].dy);
          }
          
          canvas.drawPath(path, routePaint);
        }
      }
    }

    // Draw circles for each point
    for (var point in points) {
      canvas.drawCircle(point.position, circleRadius, circleFillPaint);
      canvas.drawCircle(point.position, circleRadius, circleStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}