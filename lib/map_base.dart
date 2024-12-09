import 'package:flutter/material.dart';

class MapBase extends StatefulWidget {
  const MapBase({super.key});

  @override
  _MapBaseState createState() => _MapBaseState();
}

class _MapBaseState extends State<MapBase> {
  List<Offset> routePoints = [];
  TransformationController _controller = TransformationController();
  GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: GestureDetector(
        onTapUp: (details) {
          // Get the image's position on the screen
          final RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
          final imagePosition = renderBox.localToGlobal(Offset.zero); // Get top-left corner position

          // Calculate the adjusted position relative to the image
          final tapPosition = details.localPosition;
          final translatedPosition = tapPosition - imagePosition;

          // Get the scale factor from the controller
          final scale = _controller.value.getMaxScaleOnAxis();

          // Adjust the tapped position by the scale factor
          final adjustedPosition = translatedPosition / scale;

          setState(() {
            routePoints.add(adjustedPosition);
          });
        },
        child: Center(
          child: Container(
            width: 400,  // Fixed width of the container
            height: 450, // Fixed height of the container
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 4.0), // Black border
              borderRadius: BorderRadius.circular(20.0), // Rounded corners
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: InteractiveViewer(
                transformationController: _controller,
                boundaryMargin: const EdgeInsets.all(80),
                minScale: 0.5, // Minimum zoom scale
                maxScale: 4.0, // Maximum zoom scale
                panEnabled: false, // Disable panning (only zoom enabled)
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRect(
                        child: Image.asset(
                          'assets/map_prototype.png', // Your map image path
                          fit: BoxFit.contain,
                          key: _imageKey, // Set the key for the image
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: Size(double.infinity, double.infinity),
                      painter: RoutePainter(routePoints, _controller),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  final List<Offset> routePoints;
  final TransformationController controller;

  RoutePainter(this.routePoints, this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint routePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Get the current scale from the TransformationController
    final scale = controller.value.getMaxScaleOnAxis();

    // Iterate through the route points and adjust them to match the current scale
    if (routePoints.isNotEmpty) {
      for (int i = 0; i < routePoints.length - 1; i++) {
        // Apply the scaling to the route points
        final point1 = routePoints[i] * scale;
        final point2 = routePoints[i + 1] * scale;

        // Draw the line between the points
        canvas.drawLine(point1, point2, routePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
