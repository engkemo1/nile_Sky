import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small slippy map drawn straight onto OpenStreetMap tiles.
///
/// It deliberately pulls in no map package: the whole thing is `Image.network`
/// for the tiles plus a little Mercator arithmetic, so it builds anywhere
/// Flutter builds — mobile, desktop and web — with nothing to configure and no
/// API key. OpenStreetMap asks for attribution and an identifying User-Agent,
/// and both are here.

class MapPoint {
  final double lat;
  final double lng;
  const MapPoint(this.lat, this.lng);
}

/// A pin on the map.
class MapPin {
  final MapPoint point;
  final String label;
  final IconData icon;
  final Color color;

  const MapPin({
    required this.point,
    required this.label,
    this.icon = Icons.place,
    this.color = const Color(0xFFD4A843),
  });
}

/// Where balloons lift off on Luxor's west bank — used when a flight has no
/// coordinates of its own yet.
const MapPoint kLuxorLaunchArea = MapPoint(25.7180, 32.6120);

const double _tileSize = 256.0;
const int _minZoom = 3;
const int _maxZoom = 18;

double _lngToWorldX(double lng, int zoom) =>
    (lng + 180.0) / 360.0 * _tileSize * (1 << zoom);

double _latToWorldY(double lat, int zoom) {
  final rad = lat * math.pi / 180.0;
  final y = (1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) / 2.0;
  return y * _tileSize * (1 << zoom);
}

class NileMap extends StatefulWidget {
  final List<MapPin> pins;

  /// Falls back to the Luxor launch area when no pin has coordinates.
  final MapPoint fallbackCenter;
  final double height;
  final int initialZoom;

  /// Draws a dashed line between the first two pins (launch → landing).
  final bool connectPins;
  final BorderRadius borderRadius;

  const NileMap({
    super.key,
    this.pins = const [],
    this.fallbackCenter = kLuxorLaunchArea,
    this.height = 220,
    this.initialZoom = 13,
    this.connectPins = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<NileMap> createState() => _NileMapState();
}

class _NileMapState extends State<NileMap> {
  late int _zoom;
  late MapPoint _center;
  Offset _dragWorld = Offset.zero; // pan accumulated in world pixels

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom.clamp(_minZoom, _maxZoom);
    _center = _fitCenter();
  }

  @override
  void didUpdateWidget(NileMap old) {
    super.didUpdateWidget(old);
    if (old.pins.length != widget.pins.length) {
      _center = _fitCenter();
      _dragWorld = Offset.zero;
    }
  }

  MapPoint _fitCenter() {
    if (widget.pins.isEmpty) return widget.fallbackCenter;
    final lat = widget.pins.map((p) => p.point.lat).reduce((a, b) => a + b) /
        widget.pins.length;
    final lng = widget.pins.map((p) => p.point.lng).reduce((a, b) => a + b) /
        widget.pins.length;
    return MapPoint(lat, lng);
  }

  /// Centre in world pixels, including whatever the user has dragged.
  Offset get _centerWorld => Offset(
        _lngToWorldX(_center.lng, _zoom) + _dragWorld.dx,
        _latToWorldY(_center.lat, _zoom) + _dragWorld.dy,
      );

  void _setZoom(int next) {
    next = next.clamp(_minZoom, _maxZoom);
    if (next == _zoom) return;
    // Keep the view anchored: convert the current centre back to a coordinate
    // before the zoom changes, then drop the accumulated drag.
    final c = _centerWorld;
    final scale = 1 << _zoom;
    final lng = c.dx / (_tileSize * scale) * 360.0 - 180.0;
    final n = math.pi - 2.0 * math.pi * c.dy / (_tileSize * scale);
    final lat = 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
    setState(() {
      _center = MapPoint(lat, lng);
      _dragWorld = Offset.zero;
      _zoom = next;
    });
  }

  void _recenter() => setState(() {
        _center = _fitCenter();
        _dragWorld = Offset.zero;
        _zoom = widget.initialZoom.clamp(_minZoom, _maxZoom);
      });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, widget.height);
            final topLeft = _centerWorld - Offset(size.width / 2, size.height / 2);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => setState(() => _dragWorld -= d.delta),
              onDoubleTap: () => _setZoom(_zoom + 1),
              child: Stack(
                children: [
                  _tiles(size, topLeft),
                  if (widget.connectPins && widget.pins.length >= 2)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RoutePainter(
                          from: _screenOf(widget.pins[0].point, topLeft),
                          to: _screenOf(widget.pins[1].point, topLeft),
                        ),
                      ),
                    ),
                  ..._pins(topLeft),
                  _attribution(),
                  _controls(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Offset _screenOf(MapPoint p, Offset topLeft) => Offset(
        _lngToWorldX(p.lng, _zoom) - topLeft.dx,
        _latToWorldY(p.lat, _zoom) - topLeft.dy,
      );

  Widget _tiles(Size size, Offset topLeft) {
    final count = 1 << _zoom;
    final firstX = (topLeft.dx / _tileSize).floor();
    final firstY = (topLeft.dy / _tileSize).floor();
    final lastX = ((topLeft.dx + size.width) / _tileSize).floor();
    final lastY = ((topLeft.dy + size.height) / _tileSize).floor();

    final tiles = <Widget>[];
    for (var x = firstX; x <= lastX; x++) {
      for (var y = firstY; y <= lastY; y++) {
        if (y < 0 || y >= count) continue;
        final wrapped = x % count < 0 ? x % count + count : x % count;
        tiles.add(Positioned(
          left: x * _tileSize - topLeft.dx,
          top: y * _tileSize - topLeft.dy,
          width: _tileSize,
          height: _tileSize,
          child: Image.network(
            'https://tile.openstreetmap.org/$_zoom/$wrapped/$y.png',
            width: _tileSize,
            height: _tileSize,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            // OpenStreetMap's tile policy asks callers to identify themselves.
            headers: const {'User-Agent': 'NileSky/1.0 (Luxor balloon booking)'},
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF12203A)),
          ),
        ));
      }
    }
    return Stack(children: [
      const Positioned.fill(child: ColoredBox(color: Color(0xFF12203A))),
      ...tiles,
    ]);
  }

  List<Widget> _pins(Offset topLeft) {
    return widget.pins.map((pin) {
      final at = _screenOf(pin.point, topLeft);
      return Positioned(
        left: at.dx - 70,
        top: at.dy - 58,
        width: 140,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1626).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: pin.color, width: 1),
              ),
              child: Text(
                pin.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, height: 1.2),
              ),
            ),
            const SizedBox(height: 2),
            Icon(pin.icon, color: pin.color, size: 28, shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4),
            ]),
          ],
        ),
      );
    }).toList();
  }

  Widget _attribution() => Positioned(
        left: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: Colors.black.withValues(alpha: 0.45),
          child: const Text(
            '© OpenStreetMap contributors',
            style: TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ),
      );

  Widget _controls() => Positioned(
        right: 8,
        top: 8,
        child: Column(
          children: [
            _button(Icons.add, 'Zoom in', () => _setZoom(_zoom + 1)),
            const SizedBox(height: 6),
            _button(Icons.remove, 'Zoom out', () => _setZoom(_zoom - 1)),
            const SizedBox(height: 6),
            _button(Icons.my_location, 'Recentre', _recenter),
          ],
        ),
      );

  Widget _button(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: Material(
          color: const Color(0xFF0C1626).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Icon(icon, size: 16, color: const Color(0xFFD4A843)),
            ),
          ),
        ),
      );
}

class _RoutePainter extends CustomPainter {
  final Offset from;
  final Offset to;

  _RoutePainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A843)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final total = (to - from).distance;
    if (total < 1) return;
    final step = (to - from) / total;
    const dash = 9.0, gap = 7.0;
    var travelled = 0.0;
    while (travelled < total) {
      final end = math.min(travelled + dash, total);
      canvas.drawLine(from + step * travelled, from + step * end, paint);
      travelled = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.from != from || old.to != to;
}
