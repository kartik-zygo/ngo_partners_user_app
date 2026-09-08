import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class NgoLogoWidget extends StatelessWidget {
  final double size;
  const NgoLogoWidget({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.65,
      child: CustomPaint(
        painter: _LogoPainter(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'NGOPARTNERS',
                style: AppTextStyles.brandName.copyWith(fontSize: size * 0.12),
              ),
              Text(
                'FAST. EASY NGO REGISTRATION',
                style: AppTextStyles.tagline.copyWith(fontSize: size * 0.055),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.40;
    final scale = size.width / 300;

    // Shield
    final shieldPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;

    final shieldPath = Path();
    shieldPath.moveTo(cx, cy - 45 * scale);
    shieldPath.lineTo(cx + 25 * scale, cy - 30 * scale);
    shieldPath.lineTo(cx + 25 * scale, cy + 10 * scale);
    shieldPath.quadraticBezierTo(cx + 25 * scale, cy + 35 * scale, cx, cy + 50 * scale);
    shieldPath.quadraticBezierTo(cx - 25 * scale, cy + 35 * scale, cx - 25 * scale, cy + 10 * scale);
    shieldPath.lineTo(cx - 25 * scale, cy - 30 * scale);
    shieldPath.close();
    canvas.drawPath(shieldPath, shieldPaint);

    // Center orb
    final orbPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2 * scale), width: 28 * scale, height: 18 * scale),
      orbPaint,
    );

    // Handshake arc
    final arcPaint = Paint()
      ..color = AppColors.bgDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    final arcPath = Path();
    arcPath.moveTo(cx - 14 * scale, cy + 2 * scale);
    arcPath.quadraticBezierTo(cx - 7 * scale, cy - 5 * scale, cx, cy);
    arcPath.quadraticBezierTo(cx + 7 * scale, cy - 5 * scale, cx + 14 * scale, cy + 2 * scale);
    canvas.drawPath(arcPath, arcPaint);

    // Wings
    final wingPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.gold, AppColors.goldLight],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Left wing
    final leftWing = Path();
    leftWing.moveTo(cx - 25 * scale, cy);
    leftWing.quadraticBezierTo(cx - 50 * scale, cy - 15 * scale, cx - 80 * scale, cy - 7 * scale);
    leftWing.quadraticBezierTo(cx - 65 * scale, cy - 3 * scale, cx - 60 * scale, cy + 5 * scale);
    leftWing.quadraticBezierTo(cx - 80 * scale, cy, cx - 95 * scale, cy + 15 * scale);
    leftWing.quadraticBezierTo(cx - 75 * scale, cy + 8 * scale, cx - 68 * scale, cy + 18 * scale);
    leftWing.quadraticBezierTo(cx - 40 * scale, cy + 5 * scale, cx - 25 * scale, cy + 5 * scale);
    leftWing.close();
    canvas.drawPath(leftWing, wingPaint);

    // Right wing (mirrored)
    final rightWing = Path();
    rightWing.moveTo(cx + 25 * scale, cy);
    rightWing.quadraticBezierTo(cx + 50 * scale, cy - 15 * scale, cx + 80 * scale, cy - 7 * scale);
    rightWing.quadraticBezierTo(cx + 65 * scale, cy - 3 * scale, cx + 60 * scale, cy + 5 * scale);
    rightWing.quadraticBezierTo(cx + 80 * scale, cy, cx + 95 * scale, cy + 15 * scale);
    rightWing.quadraticBezierTo(cx + 75 * scale, cy + 8 * scale, cx + 68 * scale, cy + 18 * scale);
    rightWing.quadraticBezierTo(cx + 40 * scale, cy + 5 * scale, cx + 25 * scale, cy + 5 * scale);
    rightWing.close();
    canvas.drawPath(rightWing, wingPaint);
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
