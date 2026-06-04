import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Map pin icon matching the login screen artwork (scaled for AppBar / chips).
class IpantauMapPin extends StatelessWidget {
  const IpantauMapPin({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.83, size),
      painter: _MapPinPainter(),
    );
  }
}

class _MapPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.navy;
    final path = Path();
    final cx = size.width / 2;
    final r = size.width * 0.42;
    path.addOval(Rect.fromCircle(center: Offset(cx, r), radius: r));
    path.moveTo(cx - size.width * 0.12, r * 1.6);
    path.lineTo(cx, size.height * 0.95);
    path.lineTo(cx + size.width * 0.12, r * 1.6);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, r), r * 0.52, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx, r), r * 0.22, Paint()..color = AppTheme.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
