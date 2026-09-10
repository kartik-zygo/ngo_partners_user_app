import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/quotation_entity.dart';
import '../user/profile/my_quotations_page.dart';

/// Shown right after a successful submit. The headline is the server's
/// [QuotationEntity.confirmationMessage] — never the client's own note.
class QuotationSuccessPage extends StatefulWidget {
  final QuotationEntity quotation;

  const QuotationSuccessPage({super.key, required this.quotation});

  @override
  State<QuotationSuccessPage> createState() => _QuotationSuccessPageState();
}

class _QuotationSuccessPageState extends State<QuotationSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _confirmation {
    final message = widget.quotation.confirmationMessage;
    if (message != null && message.isNotEmpty) return message;
    // Fallback only — the create response normally carries this sentence.
    return 'Your query has been submitted. Our sales team will contact you soon.';
  }

  void _copyReference() {
    Clipboard.setData(ClipboardData(text: widget.quotation.reference));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reference copied'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quotation = widget.quotation;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutBack,
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.success, size: 46),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Query submitted',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _confirmation,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (quotation.reference.isNotEmpty)
                GestureDetector(
                  onTap: _copyReference,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reference', style: AppTextStyles.caption),
                            const SizedBox(height: 2),
                            Text(
                              quotation.reference,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.copy_rounded,
                            size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (quotation.serviceName.isNotEmpty)
                InfoChip(
                  icon: Icons.design_services_outlined,
                  label: quotation.serviceName,
                  color: AppColors.primary,
                ),
              const Spacer(),
              _NextSteps(statusLabel: quotation.statusLabel),
              const SizedBox(height: 20),
              GoldButton(
                label: 'Track my requests',
                icon: Icons.timeline_rounded,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyQuotationsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlineGoldButton(
                label: 'Back to services',
                onTap: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Next steps ────────────────────────────────────────────────────────────────
class _NextSteps extends StatelessWidget {
  final String statusLabel;
  const _NextSteps({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('What happens next',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            statusLabel.isNotEmpty
                ? statusLabel
                : 'Submitted — our sales team will contact you soon',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'A sales representative will call you to understand your '
            'requirement and share pricing.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
