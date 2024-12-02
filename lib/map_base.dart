import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapBase extends StatefulWidget {
  const MapBase({super.key});

  @override
  _MapBaseState createState() => _MapBaseState();
}

class _MapBaseState extends State<MapBase> {
  List<Offset> routePoints = [];
  //PolylinePoints polylinePoints = PolylinePoints();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // Convert tap position to relative coordinates within the image
        setState(() {
          routePoints.add(details.localPosition);
        });
      },
      child: InteractiveViewer(
        boundaryMargin: EdgeInsets.all(80),
        minScale: 0.5, // Minimum zoom scale (for zoom out)
        maxScale: 4.0, // Maximum zoom scale (for zoom in)
        child: Stack(
          children: [
            // Display the map image
            Positioned.fill(
              child: Image.asset(
                'assets/map_prototype.png', // Replace with your map image path
                fit: BoxFit.contain,
              ),
            ),
            // Draw the route
            CustomPaint(
              size: Size(double.infinity, double.infinity),
              painter: RoutePainter(routePoints),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  final List<Offset> routePoints;
  RoutePainter(this.routePoints);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint routePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    if (routePoints.isNotEmpty) {
      for (int i = 0; i < routePoints.length - 1; i++) {
        canvas.drawLine(routePoints[i], routePoints[i + 1], routePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}