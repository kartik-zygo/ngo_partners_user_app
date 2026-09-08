import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/common_widgets.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _push = true;
  bool _email = true;
  bool _sms = false;
  bool _caseUpdates = true;
  bool _docReminders = true;
  bool _offers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery Channels', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 10),
                _tile('Push Notifications', 'Instant in-app updates', _push, (v) => setState(() => _push = v)),
                _tile('Email Notifications', 'Service and ticket updates', _email, (v) => setState(() => _email = v)),
                _tile('SMS Alerts', 'Critical reminders only', _sms, (v) => setState(() => _sms = v)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What You Receive', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 10),
                _tile('Case Status Updates', 'Every stage change in your case', _caseUpdates, (v) => setState(() => _caseUpdates = v)),
                _tile('Document Reminders', 'Pending uploads and corrections', _docReminders, (v) => setState(() => _docReminders = v)),
                _tile('Tips and Offers', 'Product education and promos', _offers, (v) => setState(() => _offers = v)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GoldButton(
            label: 'Save Notification Settings',
            icon: Icons.notifications_active_rounded,
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
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
        content: const Text('Notification preferences updated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }
}
