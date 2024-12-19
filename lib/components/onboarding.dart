import 'package:flutter/material.dart';
import 'package:groceryrouter/components/home_screen.dart';

class Onboarding extends StatefulWidget {
  @override
  _OnboardingState createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Move to the next page programmatically
  void _goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  // Move to the next page programmatically
  void _goToHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              OnboardingPage(
                title: 'Welcome to App',
                description: 'This is the first step of the onboarding process.',
                color: Colors.deepPurple,
              ),
              OnboardingPage(
                title: 'Easy Navigation',
                description: 'Navigate through the app with ease.',
                color: Colors.deepPurple,
              ),
              OnboardingPage(
                title: 'Get Started',
                description: 'Let\'s get started with your amazing journey.',
                color: Colors.deepPurple,
                showButton: true,
                onButtonPressed: _goToHomePage,
              ),
            ],
          ),
          // Page Indicator
          Positioned(
            bottom: 60,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                bool isActive = _currentPage == index;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  width: isActive ? 15 : 10, // Larger dot for active page
                  height: isActive ? 15 : 10, // Larger dot for active page
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final bool showButton;
  final VoidCallback? onButtonPressed;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.color,
    this.showButton = false,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            if (showButton) ...[
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: onButtonPressed,
                child: Text(
                  "Get Started",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.pink[700],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
