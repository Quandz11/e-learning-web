import 'package:flutter/material.dart';

class RouteMapCanvas extends StatelessWidget {
  const RouteMapCanvas({
    super.key,
    required this.waypoints,
    this.height = 200,
    this.isLive = true,
  });

  final List<({double latitude, double longitude})> waypoints;
  final double height;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E382B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background subtle grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: _GridBackgroundPainter(),
            ),
          ),
          // Route polyline and points
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(
                waypoints: waypoints,
                isLive: isLive,
              ),
            ),
          ),
          // Status watermark / GPS indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF132B20).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF27523C)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34D399),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'GPS VỆ TINH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9AE6B4),
                      letterSpacing: 0.5,
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

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF162D22)
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.waypoints, required this.isLive});

  final List<({double latitude, double longitude})> waypoints;
  final bool isLive;

  @override
  void paint(Canvas canvas, Size size) {
    if (waypoints.isEmpty) {
      _paintDemoRoute(canvas, size);
      return;
    }

    // Normalize coordinates to fit size
    double minLat = waypoints.first.latitude;
    double maxLat = waypoints.first.latitude;
    double minLng = waypoints.first.longitude;
    double maxLng = waypoints.first.longitude;

    for (final p in waypoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final dLat = (maxLat - minLat).abs();
    final dLng = (maxLng - minLng).abs();

    if (dLat < 0.00001 && dLng < 0.00001) {
      // Single location point
      final center = Offset(size.width / 2, size.height / 2);
      _drawBeacon(canvas, center);
      return;
    }

    const padding = 28.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    Offset toOffset(double lat, double lng) {
      final x = padding + ((lng - minLng) / (dLng == 0 ? 1 : dLng)) * drawWidth;
      // Invert Y because latitude increases upwards
      final y = padding + (1.0 - ((lat - minLat) / (dLat == 0 ? 1 : dLat))) * drawHeight;
      return Offset(x, y);
    }

    final points = waypoints.map((p) => toOffset(p.latitude, p.longitude)).toList();
    _drawTrail(canvas, points);
  }

  void _paintDemoRoute(Canvas canvas, Size size) {
    // Elegant demo trail when no real GPS points have accumulated yet
    final p0 = Offset(size.width * 0.15, size.height * 0.65);
    final p1 = Offset(size.width * 0.35, size.height * 0.35);
    final p2 = Offset(size.width * 0.55, size.height * 0.55);
    final p3 = Offset(size.width * 0.85, size.height * 0.30);

    final points = [p0, p1, p2, p3];
    _drawTrail(canvas, points);
  }

  void _drawTrail(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Glow background
    final glowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.35)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    // Main line
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF10B981)],
      ).createShader(Rect.fromLTWH(0, 0, 400, 400))
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Start Pin
    final startPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(points.first, 5, startPaint);
    canvas.drawCircle(
      points.first,
      8,
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Current Beacon
    _drawBeacon(canvas, points.last);
  }

  void _drawBeacon(Canvas canvas, Offset pos) {
    final beaconCore = Paint()..color = const Color(0xFF10B981);
    final beaconHalo = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final beaconBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pos, 12, beaconHalo);
    canvas.drawCircle(pos, 6, beaconCore);
    canvas.drawCircle(pos, 6, beaconBorder);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.waypoints.length != waypoints.length || oldDelegate.isLive != isLive;
}
