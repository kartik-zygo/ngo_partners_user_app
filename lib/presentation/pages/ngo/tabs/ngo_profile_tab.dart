import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ticket_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../blocs/app/app_blocs.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';

class NgoProfileTab extends StatelessWidget {
  final UserEntity user;
  const NgoProfileTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('NGO Information', style: AppTextStyles.headlineSmall),
          ),
        ),
        SliverToBoxAdapter(child: _buildNgoInfo()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Account Settings', style: AppTextStyles.headlineSmall),
          ),
        ),
        SliverToBoxAdapter(child: _buildMenuSection(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: SectionHeader(
              title: 'Support Tickets',
              action: '+ New Ticket',
              onAction: () => _showCreateTicket(context),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildTickets()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: OutlineGoldButton(
              label: 'Logout',
              onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.roleNGO.withValues(alpha: 0.2),
            AppColors.roleNGO.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.roleNGO.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.roleNGO, Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              (user.ngoName ?? user.name)[0].toUpperCase(),
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.bgDark,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.ngoName ?? user.name, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.roleNGOBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.roleNGO.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '🏛️ NGO',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.roleNGO,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user.email, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNgoInfo() {
    final infoItems = [
      ('NGO Name', user.ngoName ?? '—', Icons.account_balance_rounded),
      ('Type', user.ngoType ?? '—', Icons.category_rounded),
      ('Email', user.email, Icons.email_outlined),
      if (user.phone != null) ('Phone', user.phone!, Icons.phone_outlined),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: infoItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.$3, color: AppColors.roleNGO, size: 18),
                      const SizedBox(width: 12),
                      Text(item.$1, style: AppTextStyles.caption),
                      const Spacer(),
                      Text(item.$2, style: AppTextStyles.titleMedium),
                    ],
                  ),
                ),
                if (i < infoItems.length - 1)
                  Divider(height: 1, color: AppColors.glassBorder.withValues(alpha: 0.5)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      (Icons.edit_outlined, 'Edit Profile', 'Update NGO details'),
      (Icons.lock_outline_rounded, 'Security', 'Password & 2FA'),
      (Icons.notifications_outlined, 'Notifications', 'Alert preferences'),
      (Icons.help_outline_rounded, 'Help & Support', 'FAQs and guides'),
      (Icons.info_outline_rounded, 'About', 'App version & terms'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: menuItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(i == 0
                      ? 0
                      : i == menuItems.length - 1
                          ? 0
                          : 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.roleNGO.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.$1, color: AppColors.roleNGO, size: 16),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2, style: AppTextStyles.titleMedium),
                              Text(item.$3, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),
                if (i < menuItems.length - 1)
                  Divider(height: 1, color: AppColors.glassBorder.withValues(alpha: 0.5)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTickets() {
    return BlocBuilder<TicketsBloc, TicketState>(
      builder: (ctx, state) {
        if (state is TicketLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.roleNGO));
        }
        if (state is TicketLoaded) {
          if (state.tickets.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Row(children: [
                  const Icon(Icons.support_agent_rounded, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  Text('No support tickets', style: AppTextStyles.bodyMedium),
                ]),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: state.tickets.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.roleNGO.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: AppColors.roleNGO, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.subject, style: AppTextStyles.titleMedium),
                            Text(t.priority.name, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      StatusBadge(status: t.statusLabel),
                    ],
                  ),
                ),
              )).toList(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showCreateTicket(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TicketPriority priority = TicketPriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setSt) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.bgMid,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('New Support Ticket', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Subject',
                  controller: subjectCtrl,
                  hint: 'Subject',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Description',
                  controller: descCtrl,
                  hint: 'Description',
                ),
                const SizedBox(height: 12),
                Row(
                  children: TicketPriority.values.map((p) {
                    final colors = {
                      TicketPriority.low: AppColors.success,
                      TicketPriority.medium: AppColors.warning,
                      TicketPriority.high: AppColors.error,
                    };
                    final labels = {
                      TicketPriority.low: 'Low',
                      TicketPriority.medium: 'Medium',
                      TicketPriority.high: 'High',
                    };
                    final sel = priority == p;
                    final c = colors[p]!;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSt(() => priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? c.withValues(alpha: 0.2) : AppColors.glassSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? c : AppColors.glassBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            labels[p]!,
                            style: AppTextStyles.caption.copyWith(
                              color: sel ? c : AppColors.textMuted,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'Submit Ticket',
                    onTap: () {
                      if (subjectCtrl.text.trim().isEmpty) return;
                      context.read<TicketsBloc>().add(
                            CreateTicket(
                              userId: user.id,
                              subject: subjectCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              priority: priority,
                            ),
                          );
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
