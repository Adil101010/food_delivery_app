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
  late AnimationController _particlesController;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _foodItems = [
    {
      'icon': Icons.lunch_dining_rounded,
      'name': 'Burger',
      'tagline': 'Juicy & Crispy',
      'color': Colors.orange,
      'gradient': [Colors.orange, Colors.deepOrange],
    },
    {
      'icon': Icons.local_pizza_rounded,
      'name': 'Pizza',
      'tagline': 'Cheesy Delight',
      'color': Colors.red,
      'gradient': [Colors.red, Colors.redAccent],
    },
    {
      'icon': Icons.rice_bowl_rounded,
      'name': 'Biryani',
      'tagline': 'Spicy Aroma',
      'color': Colors.amber,
      'gradient': [Colors.amber, Colors.deepOrange],
    },
    {
      'icon': Icons.coffee_maker_rounded,
      'name': 'Coffee',
      'tagline': 'Perfect Brew',
      'color': Colors.brown[700]!,
      'gradient': [Colors.brown, Colors.brown[900]!],
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _startCarousel();
  }

  Future<void> _startCarousel() async {
    for (int i = 0; i < _foodItems.length; i++) {
      setState(() => _currentIndex = i);
      _controller.reset();
      _controller.forward();
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    await Future.delayed(const Duration(milliseconds: 800));
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
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFood = _foodItems[_currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.5, -0.5),
                colors: [
                  currentFood['color'].withOpacity(0.3),
                  Colors.black87,
                  Colors.black,
                ],
              ),
            ),
          ),

          // Animated Particles
          AnimatedBuilder(
            animation: _particlesController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlesPainter(_particlesController.value),
                size: Size.infinite,
              );
            },
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Logo / App Name (top)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'FoodieHub',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Order Fresh Food',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacer
                const Spacer(flex: 2),

                // Animated Food Icon
                ScaleTransition(
                  scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 0.1).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(50),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentFood['gradient'],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: currentFood['color'].withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        currentFood['icon'],
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Text Animation
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Column(
                      children: [
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.3, 0.8),
                          )),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.3, 0.7),
                              ),
                            ),
                            child: Text(
                              currentFood['name'],
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.4, 0.9),
                          )),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.5, 1.0),
                              ),
                            ),
                            child: Text(
                              currentFood['tagline'],
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 80),

                // Progress Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _foodItems.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 36 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? AppTheme.primary
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _currentIndex == index
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Particle Painter
class _ParticlesPainter extends CustomPainter {
  final double animationValue;

  _ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final angle = (animationValue * 2 * 3.14 * 2 + i * 0.5) % (2 * 3.14);
      final radius = 100 + (animationValue * 200 + i * 50) % 300;
      final x = size.width / 2 + (radius * 0.3) * (angle.cos());
      final y = size.height / 2 + (radius * 0.3) * (angle.sin());

      paint.color = Colors.white.withOpacity(0.3 - animationValue * 0.1);
      canvas.drawCircle(Offset(x, y), 3 + animationValue * 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
