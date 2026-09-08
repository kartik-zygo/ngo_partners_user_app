import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:get_it/get_it.dart';
import '../../../data/datasources/cross_app_bridge_data_source.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import '../support/agora_call_page.dart';
import 'service_payment_page.dart';

class ServiceDetailPage extends StatefulWidget {
  final ServiceEntity service;
  final UserEntity user;
  const ServiceDetailPage({super.key, required this.service, required this.user});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Color get _catColor {
    switch (widget.service.category) {
      case ServiceCategory.ngo:
        return AppColors.accentEmerald;
      case ServiceCategory.compliance:
        return AppColors.gold;
      case ServiceCategory.business:
        return AppColors.accentCyan;
    }
  }

  List<Color> get _heroBg {
    switch (widget.service.category) {
      case ServiceCategory.ngo:
        return [const Color(0xFF059669), const Color(0xFF34D399)];
      case ServiceCategory.compliance:
        return [const Color(0xFFD97706), const Color(0xFFFCD34D)];
      case ServiceCategory.business:
        return [const Color(0xFF0891B2), const Color(0xFF67E8F9)];
    }
  }

  IconData get _catIcon {
    switch (widget.service.category) {
      case ServiceCategory.ngo:
        return Icons.account_balance_rounded;
      case ServiceCategory.compliance:
        return Icons.gavel_rounded;
      case ServiceCategory.business:
        return Icons.business_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildSliverHero(context),
          SliverToBoxAdapter(child: _buildStatBar()),
          SliverToBoxAdapter(child: _buildDescription()),
          SliverToBoxAdapter(child: _buildBenefits()),
          SliverToBoxAdapter(child: _buildDocuments()),
          SliverToBoxAdapter(child: _buildProcess()),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomNavigationBar: _buildCTA(context),
    );
  }

  // ── Sliver Hero ─────────────────────────────────────────────────────────────
  Widget _buildSliverHero(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 16),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 18),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _heroBg,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Animated glow blob
                Positioned(
                  top: -60,
                  right: -60,
                  child: AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (_, __) => Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _catColor.withValues(
                                alpha: 0.15 * _glowCtrl.value + 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _catColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Grid lines decoration
                Positioned.fill(
                  child: CustomPaint(painter: _GridPainter(_catColor)),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 90, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon container
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: _catColor.withValues(alpha: 0.4),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _catColor.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Icon(_catIcon, color: _catColor, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CategoryBadge(
                                  label: widget.service.categoryLabel,
                                  color: _catColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.service.name,
                                  style: AppTextStyles.headlineLarge.copyWith(
                                    fontSize: 22,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.currency_rupee_rounded, color: AppColors.gold, size: 14),
                                    Text(
                                      widget.service.pricingLabel.isNotEmpty
                                          ? widget.service.pricingLabel
                                          : 'Custom Quote',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Personalised quote by our team',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _AvailabilityBadge(
                              available: widget.service.status == 'approved'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stat Bar ─────────────────────────────────────────────────────────────────
  Widget _buildStatBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatTile(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: '${widget.service.durationDays}d',
              color: AppColors.accentCyan),
          _divider(),
          _StatTile(
              icon: Icons.folder_outlined,
              label: 'Documents',
              value: '${widget.service.documents.length} req.',
              color: AppColors.primaryIndigo),
          _divider(),
          _StatTile(
              icon: Icons.star_rounded,
              label: 'Expert Help',
              value: 'CA/CS',
              color: AppColors.gold),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.borderSubtle,
      );

  // ── Description ─────────────────────────────────────────────────────────────
  Widget _buildDescription() {
    if (widget.service.description == null) return const SizedBox.shrink();
    return _Section(
      title: 'About This Service',
      icon: Icons.info_outline_rounded,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          widget.service.description!,
          style: AppTextStyles.bodyLarge.copyWith(height: 1.8),
        ),
      ),
    );
  }

  // ── Benefits ─────────────────────────────────────────────────────────────────
  Widget _buildBenefits() {
    final benefits = _getBenefits();
    return _Section(
      title: 'Why Choose This',
      icon: Icons.verified_outlined,
      child: Column(
        children: benefits.asMap().entries.map((entry) {
          final b = entry.value;
          final color = b['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child:
                        Icon(b['icon'] as IconData, color: color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['title'] as String,
                            style: AppTextStyles.titleMedium),
                        const SizedBox(height: 2),
                        Text(b['subtitle'] as String,
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Documents ─────────────────────────────────────────────────────────────────
  Widget _buildDocuments() {
    if (widget.service.documents.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'Documents Required',
      icon: Icons.description_outlined,
      badge: '${widget.service.documents.length}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: widget.service.documents.asMap().entries.map((entry) {
            final i = entry.key;
            final doc = entry.value;
            final isLast = i == widget.service.documents.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _catColor,
                              _catColor.withValues(alpha: 0.6)
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child:
                              Text(doc, style: AppTextStyles.bodyLarge)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Soft Copy',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.borderSubtle),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Process Timeline ─────────────────────────────────────────────────────────
  Widget _buildProcess() {
    final steps = _getSteps();
    return _Section(
      title: 'How It Works',
      icon: Icons.route_rounded,
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isLast = i == steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _catColor,
                          _catColor.withValues(alpha: 0.5)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _catColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.bgDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 44,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _catColor.withValues(alpha: 0.4),
                            _catColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: 7, bottom: isLast ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['title']!,
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: 3),
                      Text(step['subtitle']!,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }



  // ── Bottom CTA ──────────────────────────────────────────────────────────────
  Widget _buildCTA(BuildContext context) {
    final purchasable = widget.service.purchasable;
    final priceDisplay = widget.service.pricingLabel.isNotEmpty
        ? widget.service.pricingLabel
        : purchasable
            ? '₹${widget.service.price}'
            : 'Contact for pricing';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pricing note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primarySurface,
                    AppColors.secondarySurface.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    priceDisplay,
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                  ),
                  const Spacer(),
                  Text(
                    purchasable ? 'Fixed price' : 'Get free quote',
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Primary CTA — Buy Now when purchasable, else Consultation
            GestureDetector(
              onTap: purchasable
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServicePaymentPage(
                            service: widget.service,
                            user: widget.user,
                          ),
                        ),
                      )
                  : () => _showContactSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.38),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      purchasable
                          ? Icons.receipt_long_rounded
                          : Icons.headset_mic_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      purchasable
                          ? 'Order for $priceDisplay'
                          : 'Get Free Consultation',
                      style: AppTextStyles.buttonText.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            // Secondary link — show consultation when purchasable
            if (purchasable) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showContactSheet(context),
                child: Text(
                  'Have questions? Get free consultation',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _ContactSheet(
        service: widget.service,
        user: widget.user,
        hostContext: context,
      ),
    );
  }


  // ── Data ────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _getBenefits() {
    switch (widget.service.category) {
      case ServiceCategory.ngo:
        return [
          {
            'icon': Icons.verified_rounded,
            'color': AppColors.success,
            'title': 'Government Certified',
            'subtitle': 'All registrations are official and government-approved'
          },
          {
            'icon': Icons.support_agent_rounded,
            'color': AppColors.primaryIndigo,
            'title': 'Expert Legal Guidance',
            'subtitle': 'Dedicated CA/CS professionals handle your case end-to-end'
          },
          {
            'icon': Icons.bolt_rounded,
            'color': AppColors.gold,
            'title': 'Fastest Processing',
            'subtitle': 'Real-time application tracking with 24/7 status updates'
          },
        ];
      case ServiceCategory.compliance:
        return [
          {
            'icon': Icons.shield_rounded,
            'color': AppColors.success,
            'title': 'Unlock Tax Benefits',
            'subtitle': 'Significant tax exemptions and donor deductions unlocked'
          },
          {
            'icon': Icons.people_rounded,
            'color': AppColors.accentCyan,
            'title': 'Build Donor Trust',
            'subtitle': 'Certified status increases credibility & donor confidence'
          },
          {
            'icon': Icons.update_rounded,
            'color': AppColors.gold,
            'title': 'Long-Term Validity',
            'subtitle': 'Once registered, benefits and certification continue'
          },
        ];
      case ServiceCategory.business:
        return [
          {
            'icon': Icons.security_rounded,
            'color': AppColors.accentCyan,
            'title': 'Limited Liability',
            'subtitle': 'Personal assets protected from all business liabilities'
          },
          {
            'icon': Icons.trending_up_rounded,
            'color': AppColors.primaryIndigo,
            'title': 'Scalable Structure',
            'subtitle': 'Formal framework designed to scale as your business grows'
          },
          {
            'icon': Icons.account_balance_rounded,
            'color': AppColors.gold,
            'title': 'Better Funding Access',
            'subtitle': 'Easier to secure bank loans and attract investors'
          },
        ];
    }
  }

  List<Map<String, String>> _getSteps() {
    return [
      {
        'title': 'Upload Documents',
        'subtitle': 'Submit required documents securely through the app portal'
      },
      {
        'title': 'Expert Verification',
        'subtitle': 'Our CA/CS team reviews and verifies all submitted documents'
      },
      {
        'title': 'Government Filing',
        'subtitle': 'Application filed with the relevant government authorities'
      },
      {
        'title': 'Certificate Delivery',
        'subtitle': 'Official certificate issued and delivered to you digitally'
      },
    ];
  }
}

// ── Reusable Section Container ─────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? badge;

  const _Section(
      {required this.title,
      required this.icon,
      required this.child,
      this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.headlineSmall),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(badge!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Stat Tile ──────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(value,
                style: AppTextStyles.titleMedium
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Price Row ──────────────────────────────────────────────────────────────────
// ── Category Badge ─────────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Availability Badge ─────────────────────────────────────────────────────────
class _AvailabilityBadge extends StatelessWidget {
  final bool available;
  const _AvailabilityBadge({required this.available});

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              available
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              color: color,
              size: 12),
          const SizedBox(width: 4),
          Text(
            available ? 'Available' : 'Coming Soon',
            style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Contact Sheet (unified call + WhatsApp) ──────────────────────────────────
class _ContactSheet extends StatelessWidget {
  final ServiceEntity service;
  final UserEntity user;
  final BuildContext hostContext;

  const _ContactSheet({
    required this.service,
    required this.user,
    required this.hostContext,
  });

  void _snack(BuildContext context, String msg, Color color) {
    Navigator.of(hostContext).pop();
    ScaffoldMessenger.of(hostContext).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitLeadRequest() async {
    final bridge = CrossAppBridgeDataSource();
    final requestId = await bridge.submitLeadRequest(
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
      userPhone: user.phone ?? '',
      organization: user.ngoName ?? user.name,
      serviceId: service.id,
      serviceName: service.name,
      message: 'Lead submitted from service detail consultation sheet.',
    );

    if (!hostContext.mounted) {
      return;
    }
    Navigator.of(hostContext).pop();
    ScaffoldMessenger.of(hostContext).showSnackBar(
      SnackBar(
        content: Text('Lead submitted successfully. Request ID: $requestId'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startAgoraCall({
    required String callType,
    required String targetTeam,
  }) async {
    try {
      final initiateCall = GetIt.instance<InitiateCallUseCase>();
      final call = await initiateCall(callType: callType, targetTeam: targetTeam);

      if (!hostContext.mounted) return;

      Navigator.of(hostContext).pop();
      Navigator.of(hostContext).push(
        MaterialPageRoute(
          builder: (_) => AgoraCallPage(
            callId: call.id,
            callType: callType,
            displayName: user.name,
          ),
        ),
      );
    } catch (e) {
      if (!hostContext.mounted) return;
      Navigator.of(hostContext).pop();
      ScaffoldMessenger.of(hostContext).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Get Free Consultation', style: AppTextStyles.headlineSmall),
                  Text('Our experts reply within minutes', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Service chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Enquiry: ${service.name}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Phone call option
          GestureDetector(
            onTap: () => _snack(context, 'Calling ${AppConstants.salesPhone}...', AppColors.primary),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Call Sales Team', style: AppTextStyles.titleMedium),
                      Text(AppConstants.salesPhone, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // WhatsApp option
          GestureDetector(
            onTap: () => _snack(context, 'Opening WhatsApp...', const Color(0xFF25D366)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8FBF0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chat on WhatsApp', style: AppTextStyles.titleMedium),
                      Text('Response within minutes', style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF128C7E))),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Email option
          GestureDetector(
            onTap: () => _snack(context, 'Opening email...', AppColors.accentCyan),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.email_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email Us', style: AppTextStyles.titleMedium),
                      Text(AppConstants.salesEmail, style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentCyan)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startAgoraCall(
                    callType: 'voice',
                    targetTeam: 'support',
                  ),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Agora Voice'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startAgoraCall(
                    callType: 'video',
                    targetTeam: 'sales',
                  ),
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Agora Video'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitLeadRequest,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Submit Lead Request'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Painter ───────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}
