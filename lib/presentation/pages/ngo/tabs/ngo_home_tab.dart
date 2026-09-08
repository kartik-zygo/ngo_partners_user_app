import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/case_entity.dart';
import '../../../../domain/entities/collaboration_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../blocs/app/app_blocs.dart';
import '../../../blocs/services/services_bloc.dart';
import '../../../blocs/services/services_bloc_events_states.dart';

List<(String, String, Color)> _complianceItems() {
  final now = DateTime.now();
  DateTime nextDate(int month, int day) {
    final d = DateTime(now.year, month, day);
    return d.isBefore(now) ? DateTime(now.year + 1, month, day) : d;
  }
  int daysUntil(DateTime date) => date.difference(DateTime(now.year, now.month, now.day)).inDays;
  return [
    ('12A Renewal', 'Due in ${daysUntil(nextDate(12, 31))} days', AppColors.warning),
    ('Annual Audit', 'Due in ${daysUntil(nextDate(9, 30))} days', AppColors.info),
    ('FCRA Report', 'Due in ${daysUntil(nextDate(12, 31))} days', AppColors.success),
  ];
}

class NgoHomeTab extends StatelessWidget {
  final UserEntity user;
  final void Function(int) onNavigate;

  const NgoHomeTab({super.key, required this.user, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _NgoStatsRow(user: user),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: SectionHeader(
              title: 'Active Registrations',
              action: 'View All',
              onAction: () => onNavigate(2),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildActiveCases(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: SectionHeader(
              title: 'Collaborations',
              action: 'View All',
              onAction: () => onNavigate(1),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildCollabs(context)),
        // Compliance calendar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Compliance Calendar', style: AppTextStyles.headlineSmall),
          ),
        ),
        SliverToBoxAdapter(child: _buildComplianceCalendar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.roleNGO.withValues(alpha: 0.26),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '🏛️ NGO',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.ngoName ?? user.name,
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.ngoType ?? 'NGO Organization',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: Text(
                (user.ngoName ?? user.name)[0].toUpperCase(),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                ),
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
        if (state is! ServicesLoaded) return const SizedBox.shrink();
        final active = state.cases
            .where((c) =>
                c.status != CaseStatus.approved &&
                c.status != CaseStatus.rejected)
            .take(3)
            .toList();
        if (active.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Text('No active registrations', style: AppTextStyles.bodyMedium),
              ]),
            ),
          );
        }
        return Column(
          children: active.map((c) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _NgoRegistrationCard(appCase: c),
          )).toList(),
        );
      },
    );
  }

  Widget _buildCollabs(BuildContext context) {
    return BlocBuilder<CollabBloc, CollabState>(
      builder: (ctx, state) {
        if (state is! CollabLoaded) return const SizedBox.shrink();
        final pending = state.collaborations
            .where((c) => c.status == CollabStatus.pending)
            .take(2)
            .toList();
        if (pending.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              child: Row(children: [
                const Icon(Icons.handshake_outlined, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Text('No pending collaborations', style: AppTextStyles.bodyMedium),
              ]),
            ),
          );
        }
        return Column(
          children: pending.map((c) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _CollabChip(collab: c),
          )).toList(),
        );
      },
    );
  }

  Widget _buildComplianceCalendar() {
    final items = _complianceItems();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.$3.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.$3.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: item.$3.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_today_rounded, color: item.$3, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$1, style: AppTextStyles.titleMedium),
                    Text(item.$2, style: AppTextStyles.caption.copyWith(color: item.$3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: item.$3, size: 18),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ── NGO Stats ─────────────────────────────────────────────────────────────────
class _NgoStatsRow extends StatelessWidget {
  final UserEntity user;
  const _NgoStatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (ctx, state) {
        final cases = state is ServicesLoaded ? state.cases : [];
        final active = cases.where((c) =>
            c.status != CaseStatus.approved &&
            c.status != CaseStatus.rejected).length;
        return BlocBuilder<CollabBloc, CollabState>(
          builder: (ctx2, collabState) {
            final collabs = collabState is CollabLoaded
                ? collabState.collaborations
                    .where((c) => c.status == CollabStatus.approved)
                    .length
                : 0;
            return Row(
              children: [
                _StatTile(label: 'Registrations', value: '$active', icon: Icons.assignment_rounded, color: AppColors.roleNGO),
                const SizedBox(width: 10),
                _StatTile(label: 'Partners', value: '$collabs', icon: Icons.handshake_rounded, color: AppColors.gold),
                const SizedBox(width: 10),
                _StatTile(label: 'Compliance', value: '${_complianceItems().length}', icon: Icons.verified_rounded, color: AppColors.success),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _NgoRegistrationCard extends StatelessWidget {
  final CaseEntity appCase;
  const _NgoRegistrationCard({required this.appCase});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.roleNGO.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: AppColors.roleNGO, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appCase.serviceName, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text('${appCase.documents.length} docs uploaded',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusBadge(status: appCase.statusLabel),
        ],
      ),
    );
  }
}

class _CollabChip extends StatelessWidget {
  final CollaborationEntity collab;
  const _CollabChip({required this.collab});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.handshake_outlined,
                color: AppColors.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collab.ngoName, style: AppTextStyles.titleMedium),
                Text(collab.typeLabel, style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusBadge(status: collab.status == CollabStatus.pending ? 'Pending' : 'Approved'),
        ],
      ),
    );
  }
}
