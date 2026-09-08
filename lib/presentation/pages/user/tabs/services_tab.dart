import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/service_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../blocs/services/services_bloc.dart';
import '../../../blocs/services/services_bloc_events_states.dart';
import '../../services/service_detail_page.dart';

class ServicesTab extends StatelessWidget { 
  final UserEntity user;
  const ServicesTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () {
        final future = context.read<ServicesBloc>().stream
            .firstWhere((s) => s is ServicesLoaded || s is ServicesError);
        context.read<ServicesBloc>()
          ..add(LoadServices())
          ..add(LoadCases(user.id));
        return future;
      },
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF0891B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
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
                              'Services',
                              style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Register, comply and scale with expert support',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: BlocBuilder<ServicesBloc, ServicesState>(
                          builder: (_, state) {
                            final count = state is ServicesLoaded
                                ? state.filteredServices.length
                                : 0;
                            return Text(
                              '$count services',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _CategoryFilter(),
                const SizedBox(height: 16),
                _FeaturedBanner(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          sliver: BlocBuilder<ServicesBloc, ServicesState>(
            builder: (ctx, state) {
              if (state is ServicesLoading) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ShimmerBox(width: double.infinity, height: 180),
                    ),
                    childCount: 4,
                  ),
                );
              }
              if (state is! ServicesLoaded) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final services = state.filteredServices;
              if (services.isEmpty) {
                return SliverToBoxAdapter(child: _EmptyState());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ServiceCard(service: services[i], user: user),
                  ),
                  childCount: services.length,
                ),
              );
            },
          ),
        ),
      ],
      ),
    );
  }
}

// ── Featured Banner ───────────────────────────────────────────────────────────
class _FeaturedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expert Assistance Included',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(
                    'Every service comes with dedicated CA/CS guidance',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'From ₹${AppConstants.basePriceOnwards} onwards',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Filter ───────────────────────────────────────────────────────────
class _CategoryFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (ctx, state) {
        final active = state is ServicesLoaded ? state.activeFilter : null;
        final cats = [
          (null, 'All', Icons.apps_rounded, AppColors.gold),
          (ServiceCategory.ngo, 'NGO', Icons.account_balance_rounded,
              AppColors.accentEmerald),
          (ServiceCategory.compliance, 'Compliance', Icons.gavel_rounded,
              AppColors.gold),
          (ServiceCategory.business, 'Business',
              Icons.business_center_rounded, AppColors.accentCyan),
        ];
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: cats.map((c) {
              final selected = active == c.$1;
              final color = c.$4;
              return GestureDetector(
                onTap: () => ctx
                    .read<ServicesBloc>()
                    .add(FilterByCategory(c.$1)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected ? color : AppColors.borderSubtle,
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(c.$3,
                          size: 14,
                          color: selected ? color : AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        c.$2,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: selected
                              ? color
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ── Service Card ──────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final UserEntity user;

  const _ServiceCard({required this.service, required this.user});

  Color _catColor(ServiceCategory cat) {
    switch (cat) {
      case ServiceCategory.ngo:
        return AppColors.accentEmerald;
      case ServiceCategory.compliance:
        return AppColors.gold;
      case ServiceCategory.business:
        return AppColors.accentCyan;
    }
  }

  IconData _catIcon(ServiceCategory cat) {
    switch (cat) {
      case ServiceCategory.ngo:
        return Icons.account_balance_rounded;
      case ServiceCategory.compliance:
        return Icons.gavel_rounded;
      case ServiceCategory.business:
        return Icons.business_center_rounded;
    }
  }

  void _navigate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => BlocProvider.value(
          value: context.read<ServicesBloc>(),
          child: ServiceDetailPage(service: service, user: user),
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(service.category);
    final isAvailable = service.status == 'approved';

    return GestureDetector(
      onTap: isAvailable ? () => _navigate(context) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAvailable
                ? catColor.withValues(alpha: 0.2)
                : AppColors.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: isAvailable
                  ? catColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient Header Strip ─────────────────────────────────
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    catColor.withValues(alpha: 0.25),
                    catColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon in glow container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: catColor.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(_catIcon(service.category),
                        color: catColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Name + category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: AppTextStyles.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                service.categoryLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: catColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (!isAvailable) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Coming Soon',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.warning,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Duration badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: catColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, color: catColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${service.durationDays}d',
                          style: AppTextStyles.caption.copyWith(
                            color: catColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.description != null)
                    Text(
                      service.description!,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Chip(
                        icon: Icons.description_outlined,
                        label: '${service.documents.length} docs',
                        color: AppColors.textMuted,
                      ),
                      const Spacer(),
                      if (isAvailable)
                        GestureDetector(
                          onTap: () => _navigate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Details',
                                  style: AppTextStyles.labelMedium.copyWith(
                                      color: Colors.white, fontSize: 11),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppColors.textMuted, size: 40),
          ),
          const SizedBox(height: 16),
          Text('No services found', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 6),
          Text('Try a different category filter',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
