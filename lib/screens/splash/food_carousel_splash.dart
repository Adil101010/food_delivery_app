import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/token_manager.dart';

class FoodCarouselSplash extends StatefulWidget {
  const FoodCarouselSplash({Key? key}) : super(key: key);

  @override
  State<FoodCarouselSplash> createState() => _FoodCarouselSplashState();
}

class _FoodCarouselSplashState extends State<FoodCarouselSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _foodItems = [
    {'icon': Icons.lunch_dining, 'name': 'Burger', 'color': Colors.orange},
    {'icon': Icons.local_pizza, 'name': 'Pizza', 'color': Colors.red},
    {'icon': Icons.rice_bowl, 'name': 'Biryani', 'color': Colors.amber},
    {'icon': Icons.coffee, 'name': 'Coffee', 'color': Colors.brown},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _startCarousel();
  }

  Future<void> _startCarousel() async {
    for (int i = 0; i < _foodItems.length; i++) {
      setState(() => _currentIndex = i);
      _controller.reset();
      _controller.forward();
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final isLoggedIn = await TokenManager.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFood = _foodItems[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated Food Icon
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
              ),
              child: RotationTransition(
                turns: Tween<double>(begin: 0.0, end: 0.1).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                ),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: currentFood['color'].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentFood['icon'],
                    size: 120,
                    color: currentFood['color'],
                  ),
                ),
              ),
            ),
          ),

          // Text
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _controller,
              child: Column(
                children: [
                  Text(
                    currentFood['name'],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cravings don\'t wait',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Progress Indicators
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _foodItems.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppTheme.primary
                        : Colors.white30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
