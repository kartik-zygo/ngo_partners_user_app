import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GoldOrbs extends StatefulWidget {
  const GoldOrbs({super.key});

  @override
  State<GoldOrbs> createState() => _GoldOrbsState();
}

class _GoldOrbsState extends State<GoldOrbs> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<_OrbConfig> _orbs = [
    _OrbConfig(top: 0.08, left: 0.03, size: 140, duration: 3200),
    _OrbConfig(top: 0.55, right: 0.02, size: 100, duration: 4000),
    _OrbConfig(top: 0.30, left: 0.75, size: 80, duration: 3600),
    _OrbConfig(top: 0.75, left: 0.12, size: 110, duration: 4400),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _orbs.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _orbs[i].duration),
      )..repeat(reverse: true),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -18).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(_orbs.length, (i) {
          final orb = _orbs[i];
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Positioned(
              top: orb.top != null
                  ? MediaQuery.of(context).size.height * orb.top! +
                      _animations[i].value
                  : null,
              left: orb.left != null
                  ? MediaQuery.of(context).size.width * orb.left!
                  : null,
              right: orb.right != null
                  ? MediaQuery.of(context).size.width * orb.right!
                  : null,
              child: Container(
                width: orb.size,
                height: orb.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    colors: [
                      AppColors.gold.withValues(alpha: 0.18),
                      AppColors.gold.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OrbConfig {
  final double? top, left, right;
  final double size;
  final int duration;

  _OrbConfig({
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.duration,
  });
}
