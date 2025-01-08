import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:groceryrouter/components/route_painter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' as services;
import 'map_point.dart';
import 'map_points.dart';

class MapBase extends StatefulWidget {
  const MapBase({super.key});

  @override
  _MapBaseState createState() => _MapBaseState();
}

class _MapBaseState extends State<MapBase> {
  img.Image? mapImage;
  List<MapPoint> selectedPoints1 = [];
  List<MapPoint> selectedPoints2 = [];
  bool isImage1 = true;
  double imageWidth = 350;
  double imageHeight = 250;
  String selectedImage = 'Image 1';

  Map<String, List<MapPoint>> products = {};
  List<MapPoint> intersections = [];
  List<MapPoint> obstacles = [];
  List<MapPoint> openings = [];

  // Define grid size for pathfinding
  static const int gridWidth = 35; // Number of cells horizontally
  static const int gridHeight = 25; // Number of cells vertically

  // Define obstacles (colored boxes) - Coordinates in grid cells
  // final List<Rect> obstacles = [
  //   Rect.fromLTWH(5, 5, 5, 5),    // Example obstacle
  //   Rect.fromLTWH(15, 10, 5, 5),  // Example obstacle
  //   Rect.fromLTWH(25, 15, 5, 5),  // Example obstacle
  // ];

  @override
  void initState() {
    super.initState();
    //loadMapImage();

    products = MapPoints.products;
    intersections = MapPoints.intersections;
    obstacles = MapPoints.obstacles;
    openings = MapPoints.openings;

    print('Openings: ${openings.map((p) => p.position).toList()}');
    print('Image dimensions: ${imageWidth}x${imageHeight}');
  }

  // Future<void> loadMapImage() async {
  //   // Load the image from assets using Flutter's asset bundle
  //   final ByteData data = await services.rootBundle.load('assets/map_prototype.png');
  //   final List<int> bytes = data.buffer.asUint8List();
    
  //   // Decode the image using the image package
  //   img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;
    
  //   // Store the decoded image in mapImage
  //   setState(() {
  //     mapImage = image;
  //   });
  // }

  void showSelectionDialog() {
    products.forEach((category, items) {
      items.forEach((item) => item.isSelected = false);
    });

    String searchQuery = '';
    
    showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Filter products based on search query
          Map<String, List<MapPoint>> filteredProducts = {};
          
          if (searchQuery.isEmpty) {
            filteredProducts = products;
          } else {
            products.forEach((category, items) {
              final filteredItems = items.where(
                (item) => item.name.toLowerCase().contains(searchQuery.toLowerCase())
              ).toList();
              
              if (filteredItems.isNotEmpty) {
                filteredProducts[category] = filteredItems;
              }
            });
          }
          
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Items'),
                TextButton(
                  onPressed: () {
                    List<MapPoint> selectedItems = [];
                    products.forEach((category, items) {
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
                children: [
                  // Search TextField
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  // Product categories and items
                  ...filteredProducts.entries.map((category) {
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
                ],
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
                      // Background image
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: Image.asset(
                          isImage1 ? 'assets/map_prototype.png' : 'assets/map_prototype_2.png',
                          key: ValueKey(isImage1),
                          fit: BoxFit.cover,
                          width: imageWidth,
                          height: imageHeight,
                        ),
                      ),
                      // CustomPaint should be sized to match exactly
                      SizedBox(
                        width: imageWidth,
                        height: imageHeight,
                        child: CustomPaint(
                          painter: RoutePainter(
                            products: isImage1 ? selectedPoints1 : selectedPoints2,
                            intersections: intersections,
                            obstacles: obstacles,
                            openings: openings,
                            imageWidth: imageWidth,
                            imageHeight: imageHeight,
                          ),
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