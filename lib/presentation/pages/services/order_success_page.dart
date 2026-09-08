import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/service_entity.dart';

class OrderSuccessPage extends StatefulWidget {
  final ServiceEntity service;
  final String orderId;
  final int amountPaid;

  const OrderSuccessPage({
    super.key,
    required this.service,
    required this.orderId,
    required this.amountPaid,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _ripple;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _checkScale = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.elasticOut,
    );
    _ripple = CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    // Sequence the animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _checkCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _rippleCtrl.forward();
      _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _rippleCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            // Confetti / particles background
            Positioned.fill(child: _ConfettiLayer()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(),
                    // ── Animated Success Circle ──────────────────────────
                    _buildSuccessCircle(),
                    const SizedBox(height: 32),
                    // ── Headline ─────────────────────────────────────────
                    SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _slideCtrl,
                        child: Column(
                          children: [
                            Text(
                              'Payment Successful!',
                              style: AppTextStyles.displayMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your application has been submitted.\nOur team will begin processing shortly.',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // ── Order Card ────────────────────────────────────────
                    SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _slideCtrl,
                        child: _buildOrderCard(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── Next Steps ────────────────────────────────────────
                    SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _slideCtrl,
                        child: _buildNextSteps(),
                      ),
                    ),
                    const Spacer(),
                    // ── Action Buttons ────────────────────────────────────
                    SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _slideCtrl,
                        child: _buildActions(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCircle() {
    return AnimatedBuilder(
      animation: Listenable.merge([_checkCtrl, _rippleCtrl]),
      builder: (_, __) => SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ripple
            if (_ripple.value > 0)
              Container(
                width: 160 * _ripple.value,
                height: 160 * _ripple.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success
                      .withValues(alpha: 0.15 * (1 - _ripple.value)),
                ),
              ),
            // Mid ring
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),
            // Inner circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.3),
                    AppColors.success.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: AppColors.success, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: ScaleTransition(
                scale: _checkScale,
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryIndigo.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Order Details', style: AppTextStyles.headlineSmall),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Text('Paid',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.success, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 16),
          _OrderRow(label: 'Order ID', value: widget.orderId),
          const SizedBox(height: 10),
          _OrderRow(label: 'Service', value: widget.service.name),
          const SizedBox(height: 10),
          _OrderRow(
              label: 'Category', value: widget.service.categoryLabel),
          const SizedBox(height: 10),
          _OrderRow(
              label: 'Processing Time',
              value: '${widget.service.durationDays} working days'),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Amount Paid',
                  style: AppTextStyles.titleMedium),
              const Spacer(),
              Text(
                '₹${widget.amountPaid}',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    final steps = [
      (Icons.upload_file_rounded, 'Upload Documents', AppColors.primaryIndigo),
      (Icons.person_search_rounded, 'Expert Review', AppColors.accentCyan),
      (Icons.gavel_rounded, 'Government Filing', AppColors.gold),
      (Icons.verified_rounded, 'Certificate Issued', AppColors.success),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What happens next?', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isLast = i == steps.length - 1;
            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: s.$3.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: s.$3.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: s.$3.withValues(alpha: 0.2),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(s.$1, color: s.$3, size: 16),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 56,
                        child: Text(
                          s.$2,
                          style: AppTextStyles.caption.copyWith(fontSize: 8),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 1.5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              s.$3.withValues(alpha: 0.4),
                              steps[i + 1].$3.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context)
              .popUntil((route) => route.isFirst),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryIndigo.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.track_changes_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Track My Application',
                    style: AppTextStyles.buttonText
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.of(context)
              .popUntil((route) => route.isFirst),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              'Browse More Services',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Order Row ──────────────────────────────────────────────────────────────────
class _OrderRow extends StatelessWidget {
  final String label, value;
  const _OrderRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        Text(value,
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}

// ── Confetti Layer ─────────────────────────────────────────────────────────────
class _ConfettiLayer extends StatefulWidget {
  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rand = math.Random(42);
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      40,
      (_) => _Particle(
        x: _rand.nextDouble(),
        y: _rand.nextDouble() * -0.5,
        color: [
          AppColors.gold,
          AppColors.primaryIndigo,
          AppColors.success,
          AppColors.accentCyan,
          AppColors.accentPurple,
        ][_rand.nextInt(5)],
        size: _rand.nextDouble() * 6 + 3,
        speed: _rand.nextDouble() * 0.003 + 0.001,
        wobble: _rand.nextDouble() * 0.02 - 0.01,
      ),
    );
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _ctrl.addListener(() {
      for (final p in _particles) {
        p.y += p.speed;
        p.x += p.wobble;
        if (p.y > 1.2) {
          p.y = -0.1;
          p.x = _rand.nextDouble();
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  double x, y;
  final Color color;
  final double size, speed, wobble;
  _Particle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
    required this.wobble,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: 0.7);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
