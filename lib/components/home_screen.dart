

import 'package:flutter/material.dart';
import 'package:groceryrouter/components/map_base.dart';

// Sample screens to navigate to
class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      //appBar: AppBar(title: Text('First Screen')),
      body: Center(child: Text('This is the Home page')),
    );
  }
}

class ThirdScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      //appBar: AppBar(title: Text('Third Screen')),
      body: Center(child: Text('This is the Settings page')),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Track selected index for BottomNavigationBar

  // List of screens to navigate to
  final List<Widget> _screens = [
    FirstScreen(),
    MapBase(),
    ThirdScreen(),
  ];

  // Function to change screen based on selected index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GroceryRouter')),
      body: _screens[_selectedIndex], // Display screen based on selected index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
