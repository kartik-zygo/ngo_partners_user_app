import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/common_widgets.dart';

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      (
        'How do I start a new service?',
        'Go to Services tab, open any service, and tap the consultation button to start the process.'
      ),
      (
        'How can I upload missing documents?',
        'Open Cases tab, pick your case, and tap Upload Document. You can upload as many files as needed.'
      ),
      (
        'Where can I check ticket status?',
        'In Profile, scroll to Support Tickets. Each ticket shows current status and priority.'
      ),
      (
        'How long does verification take?',
        'Most document verifications are completed within 24 to 72 hours depending on case complexity.'
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need Help?', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Find answers quickly or reach support directly.',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...faqs.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                title: Text(item.$1, style: AppTextStyles.titleMedium),
                children: [
                  Text(item.$2, style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact Support', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 10),
                _contactRow(Icons.mail_outline_rounded, 'support@ngopartners.in'),
                const SizedBox(height: 8),
                _contactRow(Icons.phone_outlined, '+91 98765 43210'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
