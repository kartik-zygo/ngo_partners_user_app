import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/common_widgets.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final points = [
      ('Smart case tracking', Icons.track_changes_rounded),
      ('Document upload workflow', Icons.upload_file_rounded),
      ('Dedicated support tickets', Icons.support_agent_rounded),
      ('Secure account controls', Icons.shield_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('About App')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text('NP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                ),
                const SizedBox(height: 10),
                Text(
                  'NGO Partners',
                  style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What this app offers', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 10),
                ...points.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(p.$2, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(p.$1, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Legal', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text('Terms of Service', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 6),
                Text('Privacy Policy', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 6),
                Text('Data Usage and Consent', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
