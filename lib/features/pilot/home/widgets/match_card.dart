import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_card.dart';
import '../../../../core/theme/app_colors.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: const [
              Text('AI Job Match',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              SizedBox(width: 4),
              Icon(Icons.auto_awesome, size: 14, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            width: 96,
            child: CustomPaint(
              painter: _GradientRingPainter(percent: 0.96),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '96%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'Great match',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _GradientRingPainter extends CustomPainter
{
  final double percent;
  _GradientRingPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 10) / 2;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * percent;

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: sweepAngle,
      colors: const [AppColors.green, AppColors.logoTurquoiseDark],
      transform: const _StartAngleRotation(-math.pi / 2),
    );

    final fgPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) =>
      oldDelegate.percent != percent;
}
class _StartAngleRotation extends GradientTransform {
  final double radians;
  const _StartAngleRotation(this.radians);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    return Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(radians)
      ..translate(-center.dx, -center.dy);
  }
}