import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppChromeBackground extends StatelessWidget {
  const AppChromeBackground({
    super.key,
    required this.child,
    this.showGrid = true,
  });

  final Widget child;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.pageGradient,
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _GlowOrb(diameter: 320, color: AppColors.glowSecondary),
        ),
        Positioned(
          top: 120,
          right: -40,
          child: _GlowOrb(diameter: 260, color: AppColors.glowPrimary),
        ),
        Positioned(
          bottom: -60,
          left: 40,
          child: _GlowOrb(diameter: 240, color: AppColors.glowMint),
        ),
        if (showGrid)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
          ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.12), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gap = 44.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final beamPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.glowPrimary.withValues(alpha: 0.0),
          AppColors.glowPrimary.withValues(alpha: 0.12),
          AppColors.glowPrimary.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width, size.height * 0.6)
      ..lineTo(size.width, size.height * 0.9)
      ..lineTo(size.width * 0.25, size.height * 0.2)
      ..close();
    canvas.drawPath(path, beamPaint);

    final ringPaint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 3; i++) {
      final radius = size.shortestSide * (0.18 + (i * 0.06));
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.18),
          radius: radius,
        ),
        -math.pi / 4,
        math.pi * 1.2,
        false,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
