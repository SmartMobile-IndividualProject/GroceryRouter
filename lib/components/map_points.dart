import 'package:groceryrouter/components/map_point.dart';
import 'dart:ui';

class MapPoints {
  static final Map<String, List<MapPoint>> products = {
    'Fresh produce': [
      MapPoint(
        name: 'Apple',
        category: 'Fresh produce',
        position: const Offset(238, 190)
      ),
      MapPoint(
        name: 'Cabbage',
        category: 'Fresh produce',
        position: const Offset(321, 164)
      ),
      MapPoint(
        name: 'Melon',
        category: 'Fresh produce',
        position: const Offset(268, 115)
      ),
    ],
    'Bakery': [
      MapPoint(
        name: 'Baguettes',
        category: 'Bakery',
        position: const Offset(268, 48)
      ),
      MapPoint(
        name: 'Bread',
        category: 'Bakery',
        position: const Offset(208, 87)
      ),
      MapPoint(
        name: 'Sandwich',
        category: 'Bakery',
        position: const Offset(166, 177)
      ),
    ],
    'Drinks': [
      MapPoint(
        name: 'Alcohol',
        category: 'Drinks',
        position: const Offset(44, 70)
      ),
      MapPoint(
        name: 'Soda',
        category: 'Drinks',
        position: const Offset(115, 110)
      ),
      MapPoint(
        name: 'Water',
        category: 'Drinks',
        position: const Offset(92, 175)
      ),
    ],
  };

  static List<MapPoint> intersections = [
    MapPoint(
      name: 'Intersection1',
      category: 'Intersection',
      position: const Offset(35, 38)
    ),
    MapPoint(
      name: 'Intersection2',
      category: 'Intersection',
      position: const Offset(81, 38)
    ),
    MapPoint(
      name: 'Intersection3',
      category: 'Intersection',
      position: const Offset(128, 38)
    ),
    MapPoint(
      name: 'Intersection4',
      category: 'Intersection',
      position: const Offset(175, 38)
    ),
    MapPoint(
      name: 'Intersection5',
      category: 'Intersection',
      position: const Offset(223, 38)
    ),
    MapPoint(
      name: 'Intersection6',
      category: 'Intersection',
      position: const Offset(308, 38)
    ),
    MapPoint(
      name: 'Intersection7',
      category: 'Intersection',
      position: const Offset(223, 82)
    ),
    MapPoint(
      name: 'Intersection8',
      category: 'Intersection',
      position: const Offset(308, 82)
    ),
    MapPoint(
      name: 'Intersection9',
      category: 'Intersection',
      position: const Offset(223, 125)
    ),
    MapPoint(
      name: 'Intersection10',
      category: 'Intersection',
      position: const Offset(308, 125)
    ),
    MapPoint(
      name: 'Intersection11',
      category: 'Intersection',
      position: const Offset(35, 145)
    ),
    MapPoint(
      name: 'Intersection12',
      category: 'Intersection',
      position: const Offset(81, 145)
    ),
    MapPoint(
      name: 'Intersection13',
      category: 'Intersection',
      position: const Offset(128, 145)
    ),
    MapPoint(
      name: 'Intersection14',
      category: 'Intersection',
      position: const Offset(175, 145)
    ),
    MapPoint(
      name: 'Intersection15',
      category: 'Intersection',
      position: const Offset(223, 145)
    ),
    MapPoint(
      name: 'Intersection16',
      category: 'Intersection',
      position: const Offset(226, 169)
    ),
    MapPoint(
      name: 'Intersection17',
      category: 'Intersection',
      position: const Offset(310, 169)
    ),
    MapPoint(
      name: 'Intersection18',
      category: 'Intersection',
      position: const Offset(35, 203)
    ),
    MapPoint(
      name: 'Intersection19',
      category: 'Intersection',
      position: const Offset(81, 203)
    ),
    MapPoint(
      name: 'Intersection20',
      category: 'Intersection',
      position: const Offset(128, 203)
    ),
    MapPoint(
      name: 'Intersection21',
      category: 'Intersection',
      position: const Offset(175, 203)
    ),
    MapPoint(
      name: 'Intersection22',
      category: 'Intersection',
      position: const Offset(226, 203)
    ),
    MapPoint(
      name: 'Intersection23',
      category: 'Intersection',
      position: const Offset(310, 203)
    ),
  ];

  static List<MapPoint> obstacles = [
    MapPoint(
      name: 'Obstacle1',
      category: 'RectLong',
      position: const Offset(55, 93)
    ),
    MapPoint(
      name: 'Obstacle2',
      category: 'RectLong',
      position: const Offset(107, 93)
    ),
    MapPoint(
      name: 'Obstacle3',
      category: 'RectLong',
      position: const Offset(154, 91)
    ),
    MapPoint(
      name: 'Obstacle4',
      category: 'RectLong',
      position: const Offset(199, 91)
    ),
    MapPoint(
      name: 'Obstacle5',
      category: 'RectWide',
      position: const Offset(268, 59)
    ),
    MapPoint(
      name: 'Obstacle6',
      category: 'RectWide',
      position: const Offset(268, 104)
    ),
    MapPoint(
      name: 'Obstacle7',
      category: 'RectShort',
      position: const Offset(55, 175)
    ),
    MapPoint(
      name: 'Obstacle8',
      category: 'RectShort',
      position: const Offset(107, 175)
    ),
    MapPoint(
      name: 'Obstacle9',
      category: 'RectShort',
      position: const Offset(154, 175)
    ),
    MapPoint(
      name: 'Obstacle10',
      category: 'RectLong',
      position: const Offset(201, 198)
    ),
    MapPoint(
      name: 'Obstacle11',
      category: 'RectWide',
      position: const Offset(270, 148)
    ),
    MapPoint(
      name: 'Obstacle12',
      category: 'RectWide',
      position: const Offset(270, 192)
    ),
  ];

  static List<MapPoint> openings = [
    MapPoint(
      name: 'Start',
      category: 'StartLocation',
      position: const Offset(263, 216)
    ),
    MapPoint(
      name: 'End',
      category: 'EndLocation',
      position: const Offset(120, 216)
    )
  ];
}