import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' as services;

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
  double g = double.infinity; // Cost from start to this node
  double h = 0.0; // Estimated cost from this node to end
  double f = double.infinity; // Total cost
  PathNode? parent;

  PathNode(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return other is PathNode && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class MapBase extends StatefulWidget {
  const MapBase({super.key});

  @override
  _MapBaseState createState() => _MapBaseState();
}

class _MapBaseState extends State<MapBase> {
  img.Image? mapImage;
  List<CategoryItem> selectedPoints1 = [];
  List<CategoryItem> selectedPoints2 = [];
  bool isImage1 = true;
  double imageWidth = 350;
  double imageHeight = 250;
  String selectedImage = 'Image 1';
  Offset startMarker = const Offset(261, 210);
  Offset endMarker = const Offset(120, 210);

  // Define grid size for pathfinding
  static const int gridWidth = 35; // Number of cells horizontally
  static const int gridHeight = 25; // Number of cells vertically

  // Define obstacles (colored boxes) - Coordinates in grid cells
  final List<Rect> obstacles = [
    Rect.fromLTWH(5, 5, 5, 5),    // Example obstacle
    Rect.fromLTWH(15, 10, 5, 5),  // Example obstacle
    Rect.fromLTWH(25, 15, 5, 5),  // Example obstacle
  ];

  @override
  void initState() {
    super.initState();
    loadMapImage();
  }

  Future<void> loadMapImage() async {
    // Load the image from assets using Flutter's asset bundle
    final ByteData data = await services.rootBundle.load('assets/map_prototype.png');
    final List<int> bytes = data.buffer.asUint8List();
    
    // Decode the image using the image package
    img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;
    
    // Store the decoded image in mapImage
    setState(() {
      mapImage = image;
    });
  }

  final Map<String, List<CategoryItem>> categoryItems = {
    'Fresh produce': [
      CategoryItem(
        name: 'Apple',
        category: 'Fresh produce',
        position: Offset(238, 188),
      ),
      CategoryItem(
        name: 'Cabbage',
        category: 'Fresh produce',
        position: Offset(319, 164),
      ),
      CategoryItem(
        name: 'Melon',
        category: 'Fresh produce',
        position: Offset(266, 112),
      ),
    ],
    'Bakery': [
      CategoryItem(
        name: 'Baguettes',
        category: 'Bakery',
        position: Offset(266, 50),
      ),
      CategoryItem(
        name: 'Bread',
        category: 'Bakery',
        position: Offset(207, 87),
      ),
      CategoryItem(
        name: 'Sandwich',
        category: 'Bakery',
        position: Offset(164, 172),
      ),
    ],
    'Drinks': [
      CategoryItem(
        name: 'Alcohol',
        category: 'Drinks',
        position: Offset(48, 70),
      ),
      CategoryItem(
        name: 'Soda',
        category: 'Drinks',
        position: Offset(115, 110),
      ),
      CategoryItem(
        name: 'Water',
        category: 'Drinks',
        position: Offset(94, 171),
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
  bool isWalkable(int x, int y, img.Image mapImage) {
    // Convert grid coordinates to screen coordinates
    Offset screenPos = gridToScreen(x, y);
    
    // Get the pixel at the screen position
    img.Pixel pixel = mapImage.getPixel(screenPos.dx.toInt(), screenPos.dy.toInt());
    
    return isGrayColor(pixel);
  }

  bool isGrayColor(img.Pixel color) {
    return color.r == 195 && color.g == 195 && color.b == 195;
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
          isWalkable(newX, newY, mapImage!)) {
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
  List<Offset> findPath(Offset start, Offset end, Set<PathNode> visitedNodes) {
  Point<int> startGrid = screenToGrid(start);
  Point<int> endGrid = screenToGrid(end);

  PathNode startNode = PathNode(startGrid.x, startGrid.y);
  PathNode endNode = PathNode(endGrid.x, endGrid.y);

  List<PathNode> openSet = [startNode];
  Set<PathNode> closedSet = {};

  startNode.g = 0;
  startNode.f = heuristic(startNode, endNode);

  while (openSet.isNotEmpty) {
    // Get the node with the lowest f score
    PathNode current = openSet.reduce((a, b) => a.f < b.f ? a : b);

    if (current == endNode) {
      // Reconstruct the path
      List<Offset> path = [];
      PathNode? node = current;
      while (node != null) {
        path.add(gridToScreen(node.x, node.y));
        node = node.parent;
      }
      return path.reversed.toList(); // Return reversed path
    }

    openSet.remove(current);
    closedSet.add(current);
    visitedNodes.add(current); // Mark as visited

    for (var neighbor in getNeighbors(current)) {
      if (closedSet.contains(neighbor) || visitedNodes.contains(neighbor)) continue;

      double tentativeG = current.g + 1;
      if (!openSet.contains(neighbor)) {
        openSet.add(neighbor);
      } else if (tentativeG >= neighbor.g) {
        continue;
      }

      neighbor.parent = current;
      neighbor.g = tentativeG;
      neighbor.f = neighbor.g + heuristic(neighbor, endNode);
    }
  }

  // If no path is found, return a direct line
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
                      if(mapImage != null)
                      CustomPaint(
                        size: Size(imageWidth, imageHeight),
                        painter: PointsAndRoutePainter(
                          points: isImage1 ? selectedPoints1 : selectedPoints2,
                          imageWidth: imageWidth,
                          imageHeight: imageHeight,
                          findPath: findPath,
                          startMarker: startMarker,
                          endMarker: endMarker,
                          mapImage: mapImage!,
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
  final Function(Offset, Offset, Set<PathNode>) findPath;
  final Offset startMarker;
  final Offset endMarker;
  static const double circleRadius = 6.0;
  static const double strokeWidth = 2.0;
  final img.Image mapImage;

  PointsAndRoutePainter({
    required this.points,
    required this.imageWidth,
    required this.imageHeight,
    required this.findPath, 
    required this.startMarker,
    required this.endMarker,
    required this.mapImage,
  });

  bool isGrayColor(img.Pixel color) {
    return color.r == 195 && color.g == 195 && color.b == 195;
  }

  // // Calculate the distance between two points
  // double calculateDistance(Offset a, Offset b) {
  //   return (a.dx - b.dx).abs() + (a.dy - b.dy).abs(); // Manhattan Distance
  // }

  @override
  void paint(Canvas canvas, Size size) {
    if (mapImage == null) return;

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

    final Paint startMarkerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final Paint endMarkerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    Set<PathNode> visitedNodes = {};

    // Step 1: Draw route from start marker to the first selected point
    if (points.isNotEmpty) {
      List<Offset> startToFirstPointPath = findPath(startMarker, points.first.position, visitedNodes);
      if (startToFirstPointPath.length > 1) {
        Path path = Path();
        path.moveTo(startToFirstPointPath.first.dx, startToFirstPointPath.first.dy);
        for (int i = 1; i < startToFirstPointPath.length; i++) {
          path.lineTo(startToFirstPointPath[i].dx, startToFirstPointPath[i].dy);
        }
        canvas.drawPath(path, routePaint);
      }
    }

    // Step 2: Draw routes between selected points
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        List<Offset> pathPoints = findPath(points[i].position, points[i + 1].position, visitedNodes);

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

    // Step 3: Draw route from the last selected point to the end marker
    if (points.isNotEmpty) {
      List<Offset> lastToEndPath = findPath(points.last.position, endMarker, visitedNodes);
      if (lastToEndPath.length > 1) {
        Path path = Path();
        path.moveTo(lastToEndPath.first.dx, lastToEndPath.first.dy);
        for (int i = 1; i < lastToEndPath.length; i++) {
          path.lineTo(lastToEndPath[i].dx, lastToEndPath[i].dy);
        }
        canvas.drawPath(path, routePaint);
      }
    }

    // Draw circles for each point
    for (var point in points) {
      canvas.drawCircle(point.position, circleRadius, circleFillPaint);
      canvas.drawCircle(point.position, circleRadius, circleStrokePaint);
    }
    
    // Draw start marker
    canvas.drawCircle(startMarker, circleRadius, startMarkerPaint);
    canvas.drawCircle(startMarker, circleRadius, circleStrokePaint);

    // Draw end marker
    canvas.drawCircle(endMarker, circleRadius, endMarkerPaint);
    canvas.drawCircle(endMarker, circleRadius, circleStrokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
