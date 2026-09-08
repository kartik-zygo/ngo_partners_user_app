import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// Soft floating dots / blobs for the light theme background
class AnimatedBackgroundPainter extends CustomPainter {
  final double animValue;
  final List<Blob> blobs;

  AnimatedBackgroundPainter(this.animValue, this.blobs);

  @override
  void paint(Canvas canvas, Size size) {
    for (final blob in blobs) {
      final pulse = 0.4 + 0.6 * math.sin(animValue * math.pi * 2 + blob.phase);
      final paint = Paint()
        ..color = blob.color.withValues(alpha: blob.opacity * pulse)
        ..style = PaintingStyle.fill;

      final cx = blob.cx * size.width;
      final cy = blob.cy * size.height + math.sin(animValue * math.pi * 2 + blob.phase) * 18;
      canvas.drawCircle(Offset(cx, cy), blob.radius * (size.width * 0.18), paint);
    }
  }

  @override
  bool shouldRepaint(AnimatedBackgroundPainter old) => old.animValue != animValue;
}

class Blob {
  final double cx, cy, radius, opacity, phase;
  final Color color;
  Blob(this.cx, this.cy, this.radius, this.opacity, this.phase, this.color);
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Blob> _blobs;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accentCyan,
      AppColors.accent,
      AppColors.accentPurple,
    ];
    _blobs = List.generate(8, (i) {
      return Blob(
        rng.nextDouble(),
        rng.nextDouble(),
        0.3 + rng.nextDouble() * 0.7,
        0.025 + rng.nextDouble() * 0.04,
        rng.nextDouble() * math.pi * 2,
        colors[i % colors.length],
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: AnimatedBackgroundPainter(_controller.value, _blobs),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0F4FF), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const AnimatedBackground(),
          child,
        ],
      ),
    );
  }
}


