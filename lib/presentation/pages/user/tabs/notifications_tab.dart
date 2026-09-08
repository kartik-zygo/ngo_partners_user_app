import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../blocs/app/app_blocs.dart';

class NotificationsTab extends StatelessWidget {
  final String userId;
  const NotificationsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.info,
      onRefresh: () {
        final future = context.read<NotifBloc>().stream
            .firstWhere((s) => s is NotifLoaded);
        context.read<NotifBloc>().add(LoadNotifications(userId));
        return future;
      },
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C4A6E), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.info.withValues(alpha: 0.26),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stay updated on your applications and tasks',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<NotifBloc, NotifState>(
                    builder: (ctx, state) {
                      if (state is! NotifLoaded) return const SizedBox.shrink();
                      final unread = state.unreadCount;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '$unread unread',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: BlocBuilder<NotifBloc, NotifState>(
              builder: (ctx, state) {
                if (state is! NotifLoaded || state.unreadCount == 0) {
                  return const SizedBox.shrink();
                }
                return Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      for (final n in state.notifications.where((n) => !n.isRead)) {
                        context.read<NotifBloc>().add(MarkRead(n.id));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'Mark all read',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.accentDark,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        BlocBuilder<NotifBloc, NotifState>(
          builder: (ctx, state) {
            if (state is NotifLoading) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ShimmerBox(width: double.infinity, height: 72),
                    ),
                    childCount: 4,
                  ),
                ),
              );
            }

            if (state is! NotifLoaded || state.notifications.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          color: AppColors.textMuted, size: 56),
                      const SizedBox(height: 16),
                      Text('All caught up!',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 8),
                      Text('No new notifications',
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final n = state.notifications[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => context
                            .read<NotifBloc>()
                            .add(MarkRead(n.id)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? AppColors.glassSurface.withValues(alpha: 0.95)
                                : AppColors.info.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: n.isRead
                                  ? AppColors.borderSubtle
                                  : AppColors.info.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (n.isRead ? AppColors.primary : AppColors.info)
                                    .withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _typeColor(n.type)
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _typeIcon(n.type),
                                  color: _typeColor(n.type),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (n.title.isNotEmpty)
                                      Text(n.title,
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: n.isRead
                                                ? AppColors.textSecondary
                                                : AppColors.textPrimary,
                                          )),
                                    if (n.title.isNotEmpty && n.text.isNotEmpty)
                                      const SizedBox(height: 2),
                                    if (n.text.isNotEmpty)
                                      Text(n.text,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontSize: 12,
                                            color: n.isRead
                                                ? AppColors.textMuted
                                                : AppColors.textSecondary,
                                          )),
                                    const SizedBox(height: 3),
                                    Text(n.timeAgo,
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.info,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: state.notifications.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
      ),
    );
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'case':
        return AppColors.info;
      case 'document':
        return AppColors.success;
      case 'collab':
        return AppColors.roleNGO;
      case 'payment_approved':
        return AppColors.success;
      case 'payment_rejected':
        return AppColors.error;
      case 'payment_request_submitted':
        return AppColors.warning;
      default:
        return AppColors.gold;
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'case':
        return Icons.folder_rounded;
      case 'document':
        return Icons.description_rounded;
      case 'collab':
        return Icons.handshake_rounded;
      case 'payment_approved':
        return Icons.verified_rounded;
      case 'payment_rejected':
        return Icons.report_gmailerrorred_rounded;
      case 'payment_request_submitted':
        return Icons.receipt_long_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
