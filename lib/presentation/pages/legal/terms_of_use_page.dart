import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/terms_consent.dart';
import '../../../core/widgets/common_widgets.dart';

/// The Terms of Use (EULA). Shown three ways:
/// - plain reading, from Profile, About and the Community menu;
/// - [TermsOfUsePage.review], from the sign-in and sign-up consent checkbox,
///   where "I Agree" pops `true`;
/// - [TermsOfUsePage.gate], shown instead of the dashboard to anyone signed in
///   who has not agreed to the current [TermsConsent.version].
class TermsOfUsePage extends StatelessWidget {
  final bool askToAgree;
  final VoidCallback? onAgree;
  final VoidCallback? onDecline;

  const TermsOfUsePage({super.key})
      : askToAgree = false,
        onAgree = null,
        onDecline = null;

  const TermsOfUsePage.review({super.key})
      : askToAgree = true,
        onAgree = null,
        onDecline = null;

  const TermsOfUsePage.gate({
    super.key,
    required VoidCallback this.onAgree,
    required VoidCallback this.onDecline,
  }) : askToAgree = true;

  bool get _isGate => onDecline != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Terms of Use'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !_isGate,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_isGate) ...[
            _Notice(
              icon: Icons.info_outline_rounded,
              color: AppColors.primary,
              text: 'Please review and agree to our Terms of Use to keep '
                  'using NGO Partners.',
            ),
            const SizedBox(height: 12),
          ],
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Terms of Use (End User Licence Agreement)',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 6),
                Text('Last updated ${_formatVersion(TermsConsent.version)}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _Notice(
            icon: Icons.gpp_bad_outlined,
            color: AppColors.error,
            title: 'Zero tolerance',
            text: 'There is no tolerance for objectionable content or abusive '
                'users. Content that breaks these terms is removed, and the '
                'account that posted it is removed from NGO Partners.',
          ),
          const SizedBox(height: 12),
          for (final section in _sections) ...[
            _SectionCard(section: section),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: askToAgree ? _buildAgreeBar(context) : null,
    );
  }

  Widget _buildAgreeBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          if (_isGate) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Decline & Sign Out'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GoldButton(
              label: 'I Agree',
              icon: Icons.check_rounded,
              onTap: onAgree ?? () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatVersion(String isoDate) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

class _Section {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final String? closing;

  const _Section(this.title, this.paragraphs,
      {this.bullets = const [], this.closing});
}

const _sections = [
  _Section('1. Agreement', [
    'These Terms of Use are an agreement between you and NGO Partners '
        '("we", "us"). By creating an account, signing in or using the NGO '
        'Partner app you agree to them. If you do not agree, do not use the '
        'app.',
  ]),
  _Section('2. Your account', [
    'You must be at least 18, or be authorised to act for the organisation '
        'you register. Keep your details accurate and your password private. '
        'You are responsible for everything done with your account.',
  ]),
  _Section('3. The Community and your content', [
    'The Community is a public forum. Questions, answers and replies you '
        'post can be read by every member. You are responsible for what you '
        'post. You keep ownership of it, and you allow us to store, display '
        'and moderate it so the Community can work.',
  ]),
  _Section(
    '4. No objectionable content or abusive behaviour',
    [
      'There is no tolerance for objectionable content or abusive users. '
          'You must not post anything, or use the app in any way, that:',
    ],
    bullets: [
      'harasses, bullies, threatens, intimidates or impersonates anyone;',
      'attacks people for their religion, caste, race, ethnicity, gender, '
          'sexual orientation, disability or any other characteristic;',
      'is sexually explicit, pornographic or obscene, or sexualises minors '
          'in any way;',
      'is violent or graphic, or encourages self-harm, terrorism or any '
          'illegal activity;',
      'is spam, a scam, fraudulent fundraising, misleading, or unsolicited '
          'advertising;',
      "shares someone else's personal information without consent, or "
          "infringes someone else's rights;",
      'contains malware, or tries to disrupt the service or access it '
          'without permission.',
    ],
  ),
  _Section(
    '5. How we keep the Community safe',
    [],
    bullets: [
      'Filtering: posts and replies are checked for objectionable language '
          'before they are published, and matching content is hidden.',
      'Reporting: every post and answer has a Report option. Reports go '
          'straight to our moderation team.',
      'Blocking: you can block any member. Their posts and answers disappear '
          'from your feed at once, and our moderation team is notified.',
      'Action within 24 hours: we review every report within 24 hours. '
          'Content that breaks these terms is removed, and the member who '
          'posted it is ejected: their account is suspended or permanently '
          'closed.',
    ],
    closing: 'We may report illegal content to the authorities. You can '
        'manage the members you have blocked from Community → Blocked members.',
  ),
  _Section('6. Our services', [
    'Community posts come from members and are not professional advice. Our '
        'registration, compliance and advisory services are provided under '
        'the quotation you accept for each engagement.',
  ]),
  _Section('7. Ending your use', [
    'You can delete your account at any time from Profile → Delete Account. '
        'We may suspend or close any account that breaks these terms, without '
        'notice where the breach is serious.',
  ]),
  _Section('8. Disclaimers and liability', [
    'The app is provided "as is". To the extent the law allows, we are not '
        'liable for indirect or consequential loss, or for content posted by '
        'other members.',
  ]),
  _Section('9. Apple App Store', [
    'These terms are between you and NGO Partners only, not Apple Inc. Apple '
        'is not responsible for the app or its content, has no obligation to '
        'provide maintenance or support for it, and is not responsible for '
        'any claim relating to it. Apple and its subsidiaries are third-party '
        'beneficiaries of these terms and may enforce them against you. '
        "Apple's Standard Licensed Application End User License Agreement "
        'also applies.',
  ]),
  _Section('10. Changes and contact', [
    'If we change these terms materially, we will ask you to agree again in '
        'the app. These terms are governed by the laws of India. Questions '
        'or concerns: ${AppConstants.supportEmail}.',
  ]),
];

class _SectionCard extends StatelessWidget {
  final _Section section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: AppTextStyles.titleLarge),
          for (final p in section.paragraphs) ...[
            const SizedBox(height: 8),
            Text(p, style: AppTextStyles.bodyMedium),
          ],
          for (final b in section.bullets)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(child: Text(b, style: AppTextStyles.bodyMedium)),
                ],
              ),
            ),
          if (section.closing != null) ...[
            const SizedBox(height: 8),
            Text(section.closing!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? title;
  final String text;

  const _Notice({
    required this.icon,
    required this.color,
    this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!,
                      style: AppTextStyles.titleMedium.copyWith(color: color)),
                  const SizedBox(height: 4),
                ],
                Text(text,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
