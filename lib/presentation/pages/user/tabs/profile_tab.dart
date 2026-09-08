import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ticket_entity.dart';
import '../../../../domain/usecases/app_usecases.dart';
import '../../../../domain/entities/user_entity.dart';
import '../profile/about_app_page.dart';
import '../profile/edit_profile_page.dart';
import '../profile/help_faq_page.dart';
import '../profile/my_orders_page.dart';
import '../profile/notification_settings_page.dart';
import '../profile/security_privacy_page.dart';
import '../../../blocs/app/app_blocs.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../support/agora_call_page.dart';
import '../../support/ticket_detail_page.dart';

class ProfileTab extends StatelessWidget {
  final UserEntity user;
  const ProfileTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header card
        SliverToBoxAdapter(
          child: _buildProfileHeader(context),
        ),
        // Menu items
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Account', style: AppTextStyles.headlineSmall),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildMenuSection(context),
        ),
        // Support tickets
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: SectionHeader(
              title: 'Support Tickets',
              action: '+ New',
              onAction: () => _showTicketDialog(context),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instant Help via Agora', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlineGoldButton(
                          label: 'Voice Support',
                          onTap: () => _startSupportCall(
                            context,
                            callType: 'voice',
                            targetTeam: 'support',
                          ),
                          color: AppColors.secondary,
                          icon: Icons.call_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlineGoldButton(
                          label: 'Video Sales',
                          onTap: () => _startSupportCall(
                            context,
                            callType: 'video',
                            targetTeam: 'sales',
                          ),
                          color: AppColors.primary,
                          icon: Icons.videocam_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildTickets(context),
        ),
        // Logout
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: GestureDetector(
              onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withValues(alpha: 0.14),
                      AppColors.error.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Text('Logout',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.error)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF134E4A), Color(0xFF0F766E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFDE68A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: AppTextStyles.headlineLarge
                        .copyWith(color: AppColors.textPrimary, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(user.email,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Text(
                          '👤 User Account',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (user.phone != null) ...[
              const SizedBox(height: 14),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, color: Colors.white70, size: 15),
                  const SizedBox(width: 8),
                  Text(user.phone!,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final items = [
      _MenuItem(
        Icons.edit_outlined,
        'Edit Profile',
        AppColors.gold,
        () => _openPage(context, EditProfilePage(user: user)),
      ),
      _MenuItem(
        Icons.receipt_long_rounded,
        'My Orders',
        AppColors.primary,
        () => _openPage(context, const MyOrdersPage()),
      ),
      _MenuItem(
        Icons.security_outlined,
        'Security & Privacy',
        AppColors.info,
        () => _openPage(context, const SecurityPrivacyPage()),
      ),
      _MenuItem(
        Icons.notifications_outlined,
        'Notification Settings',
        AppColors.warning,
        () => _openPage(context, const NotificationSettingsPage()),
      ),
      _MenuItem(
        Icons.help_outline_rounded,
        'Help & FAQ',
        AppColors.success,
        () => _openPage(context, const HelpFaqPage()),
      ),
      _MenuItem(
        Icons.info_outline_rounded,
        'About App',
        AppColors.textMuted,
        () => _openPage(context, const AboutAppPage()),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            return Column(
              children: [
                ListTile(
                  onTap: item.onTap,
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 16),
                  ),
                  title: Text(item.label, style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                if (i < items.length - 1)
                  const Divider(indent: 60, color: AppColors.divider, height: 0),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _buildTickets(BuildContext context) {
    return BlocBuilder<TicketsBloc, TicketState>(
      builder: (ctx, state) {
        if (state is TicketLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: double.infinity, height: 80),
          );
        }
        if (state is! TicketLoaded || state.tickets.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: AppColors.textMuted, size: 22),
                  const SizedBox(width: 12),
                  Text('No support tickets yet',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          );
        }
        return Column(
          children: state.tickets.map((t) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                onTap: () => _openTicket(context, t),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _priorityColor(t.priority).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.support_agent_rounded,
                          color: _priorityColor(t.priority), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.subject, style: AppTextStyles.titleMedium),
                          Text(t.statusLabel, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    StatusBadge(status: t.statusLabel),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 18),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.urgent:
      case TicketPriority.high:
        return AppColors.error;
      case TicketPriority.medium:
        return AppColors.warning;
      case TicketPriority.low:
        return AppColors.success;
    }
  }

  Future<void> _startSupportCall(
    BuildContext context, {
    required String callType,
    required String targetTeam,
  }) async {
    try {
      final initiateCall = GetIt.instance<InitiateCallUseCase>();
      final call = await initiateCall(
          callType: callType, targetTeam: targetTeam);

      if (!context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgoraCallPage(
            callId: call.id,
            callType: callType,
            displayName: user.name,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openTicket(BuildContext context, TicketEntity ticket) async {
    final bloc = context.read<TicketsBloc>();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TicketDetailPage(ticket: ticket)),
    );
    if (changed == true) {
      bloc.add(LoadTickets(user.id));
    }
  }

  void _showTicketDialog(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TicketPriority priority = TicketPriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('New Support Ticket', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                Text('Subject', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectCtrl,
                  style: AppTextStyles.bodyLarge,
                  decoration:
                      const InputDecoration(hintText: 'Brief issue title'),
                ),
                const SizedBox(height: 14),
                Text('Description', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                      hintText: 'Describe your issue in detail'),
                ),
                const SizedBox(height: 14),
                Text('Priority', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Row(
                  children: TicketPriority.values.map((p) {
                    final selected = priority == p;
                    final color = p == TicketPriority.high
                        ? AppColors.error
                        : p == TicketPriority.medium
                            ? AppColors.warning
                            : AppColors.success;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                              right: p != TicketPriority.low ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.2)
                                : AppColors.glassSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.name[0].toUpperCase() + p.name.substring(1),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: selected ? color : AppColors.textMuted,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                BlocBuilder<TicketsBloc, TicketState>(
                  builder: (bCtx, bState) {
                    final creating =
                        bState is TicketLoaded && bState.isCreating;
                    return GoldButton(
                      label: 'Submit Ticket',
                      isLoading: creating,
                      onTap: () {
                        if (subjectCtrl.text.isEmpty) return;
                        context.read<TicketsBloc>().add(CreateTicket(
                              userId: user.id,
                              subject: subjectCtrl.text,
                              description: descCtrl.text,
                              priority: priority,
                            ));
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.color, this.onTap);
}
