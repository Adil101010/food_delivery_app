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
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _lineAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Line animation (slower, more dramatic)
    _lineController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );
    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lineController,
        curve: Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    // Icon scale-in
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.elasticOut,
      ),
    );

    // Pulse effect for icons
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer background
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _lineController.forward();

    await Future.delayed(const Duration(milliseconds: 2800));
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
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
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.1 + _shimmerAnimation.value * 0.2),
                      Colors.white,
                      AppTheme.background,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              );
            },
          ),

          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top Spacing
                          SizedBox(height: constraints.maxHeight * 0.08),

                          // Logo / App Name
                          const Column(
                            children: [
                              Text(
                                'FoodieHub',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Delivering Happiness',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: constraints.maxHeight * 0.05),

                          // Animated Line Path
                          Center(
                            child: SizedBox(
                              width: screenSize.width * 0.7,
                              height: constraints.maxHeight * 0.2,
                              child: AnimatedBuilder(
                                animation: _lineAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: AnimatedLinePainter(
                                      _lineAnimation,
                                      AppTheme.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: constraints.maxHeight * 0.05),

                          // Animated Icons with Pulse
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Restaurant Icon (Left)
                              ScaleTransition(
                                scale: _iconAnimation,
                                child: ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primary,
                                          Color.lerp(AppTheme.primary, Colors.black, 0.3)!,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withOpacity(0.4),
                                          blurRadius: 30,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),

                              // Home Icon (Right)
                              ScaleTransition(
                                scale: _iconAnimation,
                                child: ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.green.shade600, Colors.green.shade800],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.4),
                                          blurRadius: 30,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.home_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Tagline with fade-in
                          FadeTransition(
                            opacity: _iconAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'From their kitchen',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'To your table',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Loading Progress
                          FadeTransition(
                            opacity: _iconAnimation,
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                value: null,
                                strokeWidth: 3,
                                backgroundColor: AppTheme.primary.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedLinePainter extends CustomPainter {
  final Animation<double> animation;
  final Color lineColor;

  AnimatedLinePainter(this.animation, this.lineColor) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ FIX: Check if size is valid before painting
    if (size.width <= 0 || size.height <= 0) {
      return; // Don't paint if size is invalid
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Multi-segment curved path
    final path = Path();

    // First curve
    path.moveTo(size.width * 0.1, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.2,
    );

    // Second curve
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.3,
      size.width * 0.9,
      size.height * 0.8,
    );

    // Animate path
    final pathMetrics = path.computeMetrics();
    
    // ✅ FIX: Check if path has any metrics before accessing
    if (pathMetrics.isEmpty) {
      return; // Don't paint if path has no metrics
    }
    
    final pathMetric = pathMetrics.first;
    final extractLength = pathMetric.length * animation.value;
    final extractPath = pathMetric.extractPath(0, extractLength);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(AnimatedLinePainter oldDelegate) => true;
}
