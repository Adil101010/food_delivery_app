import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../config/app_theme.dart';
import '../../services/token_manager.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({Key? key}) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late AnimationController _fadeOutController; 

  bool _isVideoInitialized = false;
  bool _hasNavigated = false; 

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/videos/splash_video.mp4',
      );

      await _videoController.initialize();

      if (!mounted) return;

      setState(() => _isVideoInitialized = true);

      
      await _videoController.setPlaybackSpeed(0.75);

      _videoController.play();
      _fadeController.forward();

      
      _videoController.addListener(_onVideoProgress);

      
      Future.delayed(const Duration(seconds: 5), () => _navigateNext());
    } catch (e) {
      print('Video initialization error: $e');
      Future.delayed(const Duration(seconds: 3), () => _navigateNext());
    }
  }

  
  void _onVideoProgress() {
    if (!mounted || !_videoController.value.isInitialized) return;

    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 600 &&
        !_hasNavigated) {
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

   
    await _fadeOutController.forward();

    if (!mounted) return;

    final isLoggedIn = await TokenManager.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_onVideoProgress);
    _videoController.dispose();
    _fadeController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

         
          if (_isVideoInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else
           
            Container(color: Colors.black),

          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),

          
          FadeTransition(
            opacity: _fadeController,
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 60,
                      color: AppTheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Name
                  const Text(
                    'FoodieHub',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Delivering Happiness',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  //  Koi CircularProgressIndicator NAHI
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── 4. Black Fade Out — Buffer Fix ───────────
          AnimatedBuilder(
            animation: _fadeOutController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeOutController.value,
                child: Container(color: Colors.black),
              );
            },
          ),
        ],
      ),
    );
  }
}
