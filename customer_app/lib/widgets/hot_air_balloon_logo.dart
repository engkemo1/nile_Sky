import 'package:flutter/material.dart';

/// The NileSky brand mark, with an optional golden glow and a slow float.
class HotAirBalloonLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showGlow;
  final bool showFullEmblem;

  const HotAirBalloonLogo({
    super.key,
    this.size = 64,
    this.animate = false,
    this.showGlow = false,
    this.showFullEmblem = true,
  });

  @override
  State<HotAirBalloonLogo> createState() => _HotAirBalloonLogoState();
}

class _HotAirBalloonLogoState extends State<HotAirBalloonLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.animate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The NileSky mark: a gold balloon over the Nile, inside a gold ring.
    // It is a circular badge on a transparent background, so it needs no clip
    // and sits correctly on both the dark app background and a white card.
    final imageWidget = Image.asset(
      'assets/images/logo.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.airplanemode_active,
        size: widget.size,
        color: const Color(0xFFD4A843),
      ),
    );

    if (!widget.animate && !widget.showGlow) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: imageWidget,
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        final floatOffset = widget.animate ? (pulse - 0.5) * 6.0 : 0.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: widget.showGlow
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A843).withOpacity(0.25 + pulse * 0.2),
                        blurRadius: widget.size * 0.45,
                        spreadRadius: widget.size * 0.08,
                      ),
                      BoxShadow(
                        color: const Color(0xFF0284C7).withOpacity(0.15 + pulse * 0.1),
                        blurRadius: widget.size * 0.6,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : null,
            child: imageWidget,
          ),
        );
      },
    );
  }
}
