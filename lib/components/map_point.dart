import 'dart:ui';

class MapPoint {
  final String name;
  final String category;
  final Offset position;
  bool isSelected;

  MapPoint({
    required this.name,
    required this.category,
    required this.position,
    this.isSelected = false,
  });
}