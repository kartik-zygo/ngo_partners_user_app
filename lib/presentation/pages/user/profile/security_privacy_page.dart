import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/common_widgets.dart';

class SecurityPrivacyPage extends StatefulWidget {
  const SecurityPrivacyPage({super.key});

  @override
  State<SecurityPrivacyPage> createState() => _SecurityPrivacyPageState();
}

class _SecurityPrivacyPageState extends State<SecurityPrivacyPage> {
  bool _biometric = true;
  bool _appLock = false;
  bool _loginAlerts = true;

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Security & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Security Controls', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 10),
                _toggleTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Login',
                  subtitle: 'Use fingerprint or face unlock',
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                ),
                _toggleTile(
                  icon: Icons.lock_clock_rounded,
                  title: 'App Lock',
                  subtitle: 'Auto lock app after inactivity',
                  value: _appLock,
                  onChanged: (v) => setState(() => _appLock = v),
                ),
                _toggleTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Login Alerts',
                  subtitle: 'Notify on every account sign in',
                  value: _loginAlerts,
                  onChanged: (v) => setState(() => _loginAlerts = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Current Password',
                  controller: _currentPassCtrl,
                  obscure: true,
                  prefix: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'New Password',
                  controller: _newPassCtrl,
                  obscure: true,
                  prefix: const Icon(Icons.vpn_key_outlined, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Confirm New Password',
                  controller: _confirmPassCtrl,
                  obscure: true,
                  prefix: const Icon(Icons.verified_user_outlined, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GoldButton(
            label: 'Update Security Settings',
            icon: Icons.shield_rounded,
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 16),
      ),
      title: Text(title, style: AppTextStyles.titleMedium),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Security settings updated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }
}
