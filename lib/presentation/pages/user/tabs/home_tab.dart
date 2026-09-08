import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/case_entity.dart';
import '../../../../domain/entities/service_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../blocs/app/app_blocs.dart';
import '../../../blocs/services/services_bloc.dart';
import '../../../blocs/services/services_bloc_events_states.dart';
import '../../services/service_detail_page.dart';

class HomeTab extends StatelessWidget {
  final UserEntity user;
  final void Function(int) onNavigate;

  const HomeTab({super.key, required this.user, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildQuickStats(context)),
        SliverToBoxAdapter(child: _buildHighlightBanner(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: SectionHeader(title: 'Active Cases', action: 'View All', onAction: () => onNavigate(2)),
          ),
        ),
        SliverToBoxAdapter(child: _buildActiveCases(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: SectionHeader(title: 'Popular Services', action: 'Explore All', onAction: () => onNavigate(1)),
          ),
        ),
        SliverToBoxAdapter(child: _buildFeaturedServices(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Text('Quick Actions', style: AppTextStyles.headlineSmall),
          ),
        ),
        SliverToBoxAdapter(child: _buildQuickActions(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user.name.split(' ').first} 👋',
                          style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your compliance partner',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'User Account',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification + Avatar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BlocBuilder<NotifBloc, NotifState>(
                        builder: (ctx, state) {
                          final unread = state is NotifLoaded ? state.unreadCount : 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () => onNavigate(4),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                  ),
                                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: NotificationDot(count: unread),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (ctx, state) {
        final cases = state is ServicesLoaded ? state.cases : <CaseEntity>[];
        final active = cases.where((c) =>
            c.status != CaseStatus.approved && c.status != CaseStatus.rejected).length;
        final completed = cases.where((c) => c.status == CaseStatus.approved).length;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatTile(label: 'Active', value: '$active', icon: Icons.folder_open_rounded, color: AppColors.primary),
                _buildDivider(),
                _StatTile(label: 'Completed', value: '$completed', icon: Icons.check_circle_rounded, color: AppColors.secondary),
                _buildDivider(),
                _StatTile(
                  label: 'Services',
                  value: '${user.purchasedServices.length}',
                  icon: Icons.grid_view_rounded,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.borderSubtle);
  }

  Widget _buildHighlightBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expert CA/CS Guidance Included',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondaryDark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Every service includes dedicated legal expert support',
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondaryDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCases(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (ctx, state) {
        if (state is ServicesLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: double.infinity, height: 90),
          );
        }
        if (state is! ServicesLoaded) return const SizedBox.shrink();

        final active = state.cases
            .where((c) =>
                c.status != CaseStatus.approved && c.status != CaseStatus.rejected)
            .toList();

        if (active.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgMid,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('No active cases. Browse services to get started.',
                        style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _CaseCard(appCase: active[i]),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedServices(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (ctx, state) {
        if (state is! ServicesLoaded) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: double.infinity, height: 130),
          );
        }
        final featured = state.services.take(5).toList();
        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ServiceCard(service: featured[i], user: user),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QA(icon: Icons.add_rounded, label: 'New\nService', colors: [const Color(0xFF1D4ED8), const Color(0xFF0EA5E9)], onTap: () => onNavigate(1)),
      _QA(icon: Icons.forum_rounded, label: 'Comm-\nunity', colors: [const Color(0xFF6366F1), const Color(0xFFA855F7)], onTap: () => onNavigate(2)),
      _QA(icon: Icons.folder_open_rounded, label: 'My\nCases', colors: [AppColors.secondary, AppColors.accentCyan], onTap: () => onNavigate(3)),
      _QA(icon: Icons.inventory_2_rounded, label: 'Doc\nVault', colors: [AppColors.accent, const Color(0xFFEF4444)], onTap: () => onNavigate(3)),
      _QA(icon: Icons.support_agent_rounded, label: 'Get\nSupport', colors: [AppColors.accentCyan, AppColors.primary], onTap: () => onNavigate(5)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: GestureDetector(
              onTap: a.onTap,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: a.colors.map((c) => c.withValues(alpha: 0.08)).toList()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: a.colors[0].withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: a.colors),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: a.colors[0].withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(a.icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(a.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color, fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Case Card ─────────────────────────────────────────────────────────────────
class _CaseCard extends StatelessWidget {
  final CaseEntity appCase;
  const _CaseCard({required this.appCase});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 14),
              ),
              const Spacer(),
              StatusBadge(status: appCase.statusLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(appCase.serviceName,
              style: AppTextStyles.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Service Card ─────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final UserEntity user;
  const _ServiceCard({required this.service, required this.user});

  Color get _catColor {
    switch (service.category) {
      case ServiceCategory.ngo: return AppColors.secondary;
      case ServiceCategory.compliance: return AppColors.accent;
      case ServiceCategory.business: return AppColors.accentCyan;
    }
  }

  IconData get _catIcon {
    switch (service.category) {
      case ServiceCategory.ngo: return Icons.account_balance_rounded;
      case ServiceCategory.compliance: return Icons.gavel_rounded;
      case ServiceCategory.business: return Icons.business_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ServiceDetailPage(service: service, user: user)),
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: _catColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_catIcon, color: _catColor, size: 18),
            ),
            const Spacer(),
            Text(service.name,
                style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _catColor),
                const SizedBox(width: 3),
                Text(
                  'View details',
                  style: AppTextStyles.caption.copyWith(color: _catColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  const _QA({required this.icon, required this.label, required this.colors, required this.onTap});
}


