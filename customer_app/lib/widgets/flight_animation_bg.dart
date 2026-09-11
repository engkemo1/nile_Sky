import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'hot_air_balloon_logo.dart';

/// Animated daylight sky background with floating luxury hot air balloons and soft sunrise ambient glow.
class FlightAnimationBg extends StatefulWidget {
  final Widget child;
  const FlightAnimationBg({super.key, required this.child});

  @override
  State<FlightAnimationBg> createState() => _FlightAnimationBgState();
}

class _FlightAnimationBgState extends State<FlightAnimationBg>
    with TickerProviderStateMixin {
  late AnimationController _driftController;
  late AnimationController _pulseController;
  final Random _random = Random();
  final List<_SkyElement> _elements = [];

  @override
  void initState() {
    super.initState();

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    for (int i = 0; i < 8; i++) {
      _elements.add(_SkyElement(
        xFraction: _random.nextDouble(),
        speed: 0.12 + _random.nextDouble() * 0.35,
        size: 24 + _random.nextDouble() * 26,
        startY: _random.nextDouble(),
        drift: (_random.nextDouble() - 0.5) * 0.08,
        isBalloon: i % 2 == 0,
        opacity: 0.25 + _random.nextDouble() * 0.35,
      ));
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Daylight Sunrise Ambient Glow Background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final glowAlpha = 0.06 + _pulseController.value * 0.04;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: glowAlpha),
                      AppColors.secondary.withValues(alpha: 0.03),
                      AppColors.bgDark,
                    ],
                    stops: const [0.0, 0.4, 0.9],
                  ),
                ),
              );
            },
          ),
        ),

        // Floating Real Hot Air Balloons & Sky Elements
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _driftController,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: _elements.map((el) {
                        double y = el.startY - (_driftController.value * el.speed);
                        y = y % 1.0;
                        if (y < 0) y += 1.0;

                        double x = el.xFraction +
                            sin(_driftController.value * 2 * pi + el.startY * 6) * el.drift;
                        x = x.clamp(0.0, 1.0);

                        return Positioned(
                          left: x * w,
                          top: y * h,
                          child: Opacity(
                            opacity: el.opacity,
                            child: el.isBalloon
                                ? HotAirBalloonLogo(size: el.size)
                                : Icon(
                                    Icons.cloud,
                                    size: el.size * 1.1,
                                    color: const Color(0xFFBAE6FD).withValues(alpha: 0.7),
                                  ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _SkyElement {
  final double xFraction;
  final double speed;
  final double size;
  final double startY;
  final double drift;
  final bool isBalloon;
  final double opacity;

  _SkyElement({
    required this.xFraction,
    required this.speed,
    required this.size,
    required this.startY,
    required this.drift,
    required this.isBalloon,
    required this.opacity,
  });
}
