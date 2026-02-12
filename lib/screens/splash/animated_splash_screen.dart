import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/app_theme.dart';
import '../../services/token_manager.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({Key? key}) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _lineController;
  late AnimationController _iconController;
  late Animation<double> _lineAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();

    // Line animation
    _lineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );

    // Icon animation
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _lineController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));
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
    _lineController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated Line
          Center(
            child: CustomPaint(
              size: const Size(200, 200),
              painter: AnimatedLinePainter(_lineAnimation),
            ),
          ),

          // Restaurant Icon (Start)
          Positioned(
            left: MediaQuery.of(context).size.width * 0.3,
            top: MediaQuery.of(context).size.height * 0.4,
            child: ScaleTransition(
              scale: _iconAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Home Icon (End)
          Positioned(
            right: MediaQuery.of(context).size.width * 0.3,
            bottom: MediaQuery.of(context).size.height * 0.4,
            child: ScaleTransition(
              scale: _iconAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Text Animation
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _iconAnimation,
              child: Column(
                children: [
                  Text(
                    'From their kitchen',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To your table',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedLinePainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedLinePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2,
      size.width,
      size.height,
    );

    final pathMetrics = path.computeMetrics();
    final pathMetric = pathMetrics.first;
    final extractPath = pathMetric.extractPath(
      0,
      pathMetric.length * animation.value,
    );

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(AnimatedLinePainter oldDelegate) => true;
}
