import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _logoCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFadeAnim = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _progressCtrl.forward().then((_) {
        _fadeCtrl.forward().then((_) => widget.onComplete());
      });
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _fadeCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(_fadeAnim),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background gradient blobs
            Positioned(
              top: -80,
              right: -80,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12 + 0.04 * _pulseCtrl.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.10 + 0.04 * _pulseCtrl.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo
                  FadeTransition(
                    opacity: _logoFadeAnim,
                    child: ScaleTransition(
                      scale: _logoScaleAnim,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_pulseCtrl, _rotateCtrl]),
                        builder: (_, __) {
                          return SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer spinning ring
                                Transform.rotate(
                                  angle: _rotateCtrl.value * 2 * math.pi,
                                  child: Container(
                                    width: 174,
                                    height: 174,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: _DottedCirclePainter(AppColors.primary),
                                    ),
                                  ),
                                ),
                                // Inner counter-spin
                                Transform.rotate(
                                  angle: -_rotateCtrl.value * 2 * math.pi * 0.5,
                                  child: Container(
                                    width: 144,
                                    height: 144,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.secondary.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // Logo circle
                                Container(
                                  width: 118,
                                  height: 118,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, Color(0xFF0EA5E9)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '🏛️',
                                      style: TextStyle(fontSize: 48),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _logoFadeAnim,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ).createShader(bounds),
                          child: Text(
                            'NGO Partners',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'FAST · SECURE · PROFESSIONAL',
                          style: AppTextStyles.labelSmall.copyWith(
                            letterSpacing: 3,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Progress
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _progressCtrl,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressCtrl.value,
                              backgroundColor: AppColors.bgMid,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              minHeight: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _progressCtrl,
                          builder: (_, __) => Text(
                            _progressCtrl.value < 0.4
                                ? 'Initialising platform...'
                                : _progressCtrl.value < 0.75
                                    ? 'Loading services...'
                                    : 'Almost ready...',
                            style: AppTextStyles.caption.copyWith(letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedCirclePainter extends CustomPainter {
  final Color color;
  _DottedCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 4;
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi * 2 / 12;
      canvas.drawCircle(
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        2.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}


