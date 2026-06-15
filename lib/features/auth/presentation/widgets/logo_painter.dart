//import 'dart:math' as math;
import 'package:flutter/material.dart';

class TinkiyAgroLogo extends StatelessWidget {
  final double size;
  final Color color;
  final bool showText;
  final double fontSize;

  const TinkiyAgroLogo({
    super.key,
    this.size = 120.0,
    this.color = Colors.white,
    this.showText = true,
    this.fontSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _FarmerLogoPainter(color: color),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'TINKIYAGRO',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ],
    );
  }
}

class _FarmerLogoPainter extends CustomPainter {
  final Color color;

  _FarmerLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    // --- 1. Draw the Plate/Fruit (Circle) ---
    // Placed in the upper right quadrant
    final double circleRadius = w * 0.15;
    final Offset circleCenter = Offset(w * 0.65, h * 0.25);
    canvas.drawCircle(circleCenter, circleRadius, paint);

    // --- 2. Draw the Ground Line ---
    // Curved arc at the very bottom
    final Path groundPath = Path()
      ..moveTo(w * 0.2, h * 0.95)
      ..quadraticBezierTo(w * 0.5, h * 0.90, w * 0.8, h * 0.95);
    canvas.drawPath(groundPath, strokePaint);

    // --- 3. Draw the Farmer Body ---
    final Path bodyPath = Path();

    // Hat
    // Brim of the hat
    bodyPath.moveTo(w * 0.35, h * 0.25);
    bodyPath.quadraticBezierTo(w * 0.48, h * 0.22, w * 0.60, h * 0.25);
    bodyPath.quadraticBezierTo(w * 0.48, h * 0.27, w * 0.35, h * 0.25);

    // Top of the hat (sombrero style)
    bodyPath.moveTo(w * 0.41, h * 0.24);
    bodyPath.cubicTo(
      w * 0.42,
      h * 0.13,
      w * 0.53,
      h * 0.13,
      w * 0.54,
      h * 0.24,
    );
    bodyPath.close();

    // Head
    final Offset headCenter = Offset(w * 0.48, h * 0.29);
    canvas.drawCircle(headCenter, w * 0.065, paint);

    // Poncho / Torso
    final Path poncho = Path()
      ..moveTo(w * 0.43, h * 0.36) // Left shoulder
      ..lineTo(w * 0.55, h * 0.36) // Right shoulder
      ..lineTo(w * 0.58, h * 0.52) // Right waist/poncho tip
      ..lineTo(w * 0.45, h * 0.55) // Center bottom poncho
      ..lineTo(w * 0.39, h * 0.50) // Left waist/poncho tip
      ..close();
    canvas.drawPath(poncho, paint);

    // Left Arm (holding the plate)
    // Starts from right shoulder, bends up to touch the plate
    final Path leftArm = Path()
      ..moveTo(w * 0.53, h * 0.36)
      ..quadraticBezierTo(w * 0.62, h * 0.38, w * 0.59, h * 0.32) // elbow
      ..lineTo(w * 0.55, h * 0.30) // hand support
      ..lineTo(w * 0.58, h * 0.28)
      ..lineTo(w * 0.63, h * 0.35)
      ..lineTo(w * 0.55, h * 0.40)
      ..close();
    canvas.drawPath(leftArm, paint);

    // Right Arm (resting on hip / active)
    final Path rightArm = Path()
      ..moveTo(w * 0.44, h * 0.36)
      ..lineTo(w * 0.38, h * 0.42) // elbow
      ..lineTo(w * 0.44, h * 0.47) // hand on hip
      ..lineTo(w * 0.46, h * 0.43)
      ..lineTo(w * 0.42, h * 0.40)
      ..close();
    canvas.drawPath(rightArm, paint);

    // Left Leg (standing / trailing back)
    final Path leftLeg = Path()
      ..moveTo(w * 0.44, h * 0.55)
      ..lineTo(w * 0.40, h * 0.70) // knee
      ..lineTo(w * 0.45, h * 0.88) // foot
      ..lineTo(w * 0.40, h * 0.89) // foot sole
      ..lineTo(w * 0.36, h * 0.70) // knee back
      ..lineTo(w * 0.41, h * 0.55)
      ..close();
    canvas.drawPath(leftLeg, paint);

    // Right Leg (lifted / dynamic step forward)
    final Path rightLeg = Path()
      ..moveTo(w * 0.49, h * 0.55)
      ..lineTo(w * 0.56, h * 0.66) // knee forward
      ..lineTo(w * 0.49, h * 0.83) // heel
      ..lineTo(w * 0.54, h * 0.85) // toes
      ..lineTo(w * 0.60, h * 0.66) // knee outer
      ..lineTo(w * 0.53, h * 0.55)
      ..close();
    canvas.drawPath(rightLeg, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
