import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import 'package:get_it/get_it.dart';
import '../../../data/datasources/cross_app_bridge_data_source.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import '../support/agora_call_page.dart';

/// Contact Sales page — replaces the payment flow.
/// Shows pricing info (from ₹500) and lets users call the sales team.
class PaymentPage extends StatelessWidget {
  final ServiceEntity service;
  final UserEntity user;
  const PaymentPage({super.key, required this.service, required this.user});

  @override
  Widget build(BuildContext context) {
    return ContactSalesPage(service: service, user: user);
  }
}

class ContactSalesPage extends StatefulWidget {
  final ServiceEntity service;
  final UserEntity user;
  const ContactSalesPage({super.key, required this.service, required this.user});

  @override
  State<ContactSalesPage> createState() => _ContactSalesPageState();
}

class _ContactSalesPageState extends State<ContactSalesPage>
    with SingleTickerProviderStateMixin {
  final CrossAppBridgeDataSource _bridge = CrossAppBridgeDataSource();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _catColor {
    switch (widget.service.category) {
      case ServiceCategory.ngo: return AppColors.secondary;
      case ServiceCategory.compliance: return AppColors.accent;
      case ServiceCategory.business: return AppColors.accentCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildHero(context),
          SliverToBoxAdapter(child: _buildPricingCard()),
          SliverToBoxAdapter(child: _buildFeaturesSection()),
          SliverToBoxAdapter(child: _buildContactSection()),
          SliverToBoxAdapter(child: _buildWhyUs()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildCTA(context),
    );
  }

  Widget _buildHero(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 16),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_catColor, _catColor.withValues(alpha: 0.6), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.service.categoryLabel.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.white, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.service.name,
                      style: AppTextStyles.headlineLarge.copyWith(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Service Pricing',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✓ Transparent',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.service.pricingLabel.isNotEmpty
                  ? widget.service.pricingLabel
                  : 'Custom Quote',
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Final pricing based on your requirements. Our team will provide a tailored quote after a quick consultation.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8), height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Processing time: ${widget.service.durationDays} working days',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      ('Expert CA/CS guidance', Icons.school_rounded, AppColors.primary),
      ('100% government compliant', Icons.verified_rounded, AppColors.secondary),
      ('Secure document handling', Icons.security_rounded, AppColors.accentCyan),
      ('Real-time case tracking', Icons.track_changes_rounded, AppColors.accent),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s Included', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          ...features.map((f) => _FeatureRow(label: f.$1, icon: f.$2, color: f.$3)),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GlassCard(
        backgroundColor: AppColors.secondarySurface,
        borderColor: AppColors.secondary.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(alpha: 0.15 + 0.08 * _pulseCtrl.value),
                    ),
                    child: const Center(
                      child: Text('📞', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Talk to Our Sales Team', style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondaryDark)),
                      Text('Get a personalised quote in minutes', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            _ContactTile(
              icon: Icons.phone_rounded,
              title: 'Call Us',
              subtitle: AppConstants.salesPhone,
              color: AppColors.secondary,
              onTap: () => _copyToClipboard(context, AppConstants.salesPhone, 'Phone number copied'),
            ),
            const SizedBox(height: 8),
            _ContactTile(
              icon: Icons.chat_rounded,
              title: 'WhatsApp',
              subtitle: 'Chat with us instantly',
              color: const Color(0xFF25D366),
              onTap: () => _showWhatsAppSheet(context),
            ),
            const SizedBox(height: 8),
            _ContactTile(
              icon: Icons.email_rounded,
              title: 'Email',
              subtitle: AppConstants.salesEmail,
              color: AppColors.primary,
              onTap: () => _copyToClipboard(context, AppConstants.salesEmail, 'Email copied'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlineGoldButton(
                    label: 'Agora Voice Call',
                    onTap: () => _startAgoraCall(callType: 'voice', targetTeam: 'support'),
                    color: AppColors.secondary,
                    icon: Icons.call_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlineGoldButton(
                    label: 'Agora Video Call',
                    onTap: () => _startAgoraCall(callType: 'video', targetTeam: 'sales'),
                    color: AppColors.primary,
                    icon: Icons.videocam_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GoldButton(
              label: 'Submit Lead Request',
              onTap: _submitLeadRequest,
              icon: Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyUs() {
    final points = [
      ('10,000+', 'NGOs Registered', AppColors.primary),
      ('99.8%', 'Success Rate', AppColors.secondary),
      ('48hrs', 'Avg. Response', AppColors.accent),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why NGO Partners?', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          Row(
            children: points.map((p) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.$3.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.$3.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(p.$1, style: AppTextStyles.headlineMedium.copyWith(color: p.$3, fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(p.$2, style: AppTextStyles.caption, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlineGoldButton(
                label: 'WhatsApp',
                onTap: () => _showWhatsAppSheet(context),
                color: const Color(0xFF25D366),
                icon: Icons.chat_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GoldButton(
                label: 'Call Sales Team',
                onTap: () => _showCallSheet(context),
                icon: Icons.phone_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLeadRequest() async {
    final requestId = await _bridge.submitLeadRequest(
      userId: widget.user.id,
      userName: widget.user.name,
      userEmail: widget.user.email,
      userPhone: widget.user.phone ?? '',
      organization: widget.user.ngoName ?? widget.user.name,
      serviceId: widget.service.id,
      serviceName: widget.service.name,
      message: 'Lead submitted from contact sales screen.',
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
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

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgoraCallPage(
            callId: call.id,
            callType: callType,
            displayName: widget.user.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCallSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CallSheet(service: widget.service),
    );
  }

  void _showWhatsAppSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WhatsAppSheet(service: widget.service),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Feature Row ───────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _FeatureRow({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Contact Tile ──────────────────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _ContactTile({required this.icon, required this.title, required this.subtitle, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium.copyWith(color: color)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Call Sheet ────────────────────────────────────────────────────────────────
class _CallSheet extends StatelessWidget {
  final ServiceEntity service;
  const _CallSheet({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.phone_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Call Sales Team', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text('Our experts are available ${AppConstants.salesAvailability}', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(AppConstants.salesPhone, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GoldButton(
            label: 'Tap to Call Now',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Opening dialer...'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: Icons.call_rounded,
          ),
        ],
      ),
    );
  }
}

// ── WhatsApp Sheet ────────────────────────────────────────────────────────────
class _WhatsAppSheet extends StatelessWidget {
  final ServiceEntity service;
  const _WhatsAppSheet({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Chat on WhatsApp', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text('Get instant response from our team', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FBF0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
            ),
            child: Text(
              'Enquiry: ${service.name}\nService: ${service.pricingLabel.isNotEmpty ? service.pricingLabel : 'Custom Quote'}',
              style: AppTextStyles.caption.copyWith(color: const Color(0xFF128C7E)),
            ),
          ),
          const SizedBox(height: 16),
          GoldButton(
            label: 'Open WhatsApp',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Opening WhatsApp...'),
                  backgroundColor: const Color(0xFF25D366),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            color: const Color(0xFF25D366),
            icon: Icons.chat_rounded,
          ),
        ],
      ),
    );
  }
}

