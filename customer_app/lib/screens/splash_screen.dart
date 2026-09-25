import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/hot_air_balloon_logo.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _flightController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Exchange rates come from the admin panel rather than constants compiled
    // into this build. The splash already waits four seconds, so this costs
    // nothing, and a failure just leaves the previous rates in place.
    ApiService.loadExchangeRates();

    // The incredible 4-second immersive flight takeoff animation
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Slowly scale the gorgeous POV background to simulate moving upward & forward
    _scaleAnimation = Tween<double>(begin: 1.05, end: 1.25).animate(
      CurvedAnimation(
        parent: _flightController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Fade the background in gracefully
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flightController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Content (Logo & Text) fades in after takeoff starts
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flightController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    _flightController.forward().then((_) {
      // Hold briefly at peak height, then transition to onboarding
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const OnboardingScreen(),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 1000),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _flightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark before the sunrise fades in
      body: AnimatedBuilder(
        animation: _flightController,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. The Stunning First-Person Balloon Ride POV Background
              FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Image.asset(
                    'assets/images/balloon_ride_pov.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. Cinematic Dark Gradient Overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // 3. Central Brand Identity (Logo + Typography)
              Center(
                child: FadeTransition(
                  opacity: _contentFadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Our new, elegant logo asset
                      const HotAirBalloonLogo(
                        size: 150,
                        animate: true,
                        showGlow: true,
                      ),
                      const SizedBox(height: 32),
                      
                      const Text(
                        'NILESKY',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 10.0,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Luxury Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'YOUR JOURNEY BEGINS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
