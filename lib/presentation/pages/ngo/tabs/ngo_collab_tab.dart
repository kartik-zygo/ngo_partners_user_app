import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/collaboration_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../blocs/app/app_blocs.dart';

class NgoCollabTab extends StatelessWidget {
  final UserEntity user;
  const NgoCollabTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0891B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.24),
                    blurRadius: 20,
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
                          'Collaborations',
                          style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                        ),
                        Text(
                          'Build and manage your NGO network',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GoldButton(
                    label: '+ Request',
                    onTap: () => _showRequestDialog(context),
                    width: 110,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        BlocBuilder<CollabBloc, CollabState>(
          builder: (ctx, state) {
            if (state is CollabLoading) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerBox(width: double.infinity, height: 100),
                    ),
                    childCount: 3,
                  ),
                ),
              );
            }

            if (state is! CollabLoaded || state.collaborations.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.handshake_outlined,
                          color: AppColors.textMuted, size: 56),
                      const SizedBox(height: 16),
                      Text('No collaborations yet',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Request a new collaboration to build your network',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center),
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
                    final c = state.collaborations[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CollabCard(collab: c),
                    );
                  },
                  childCount: state.collaborations.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  void _showRequestDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final aboutCtrl = TextEditingController();
    CollabType selectedType = CollabType.fundingPartner;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Request Collaboration', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                Text('NGO / Organization Name', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(hintText: 'Organization name'),
                ),
                const SizedBox(height: 14),
                Text('Collaboration Type', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CollabType.values.map((t) {
                    final selected = selectedType == t;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.gold.withValues(alpha: 0.2)
                              : AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppColors.gold : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          _typeLabel(t),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: selected ? AppColors.gold : AppColors.textMuted,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('About', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: aboutCtrl,
                  maxLines: 3,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Describe the collaboration purpose',
                  ),
                ),
                const SizedBox(height: 20),
                BlocBuilder<CollabBloc, CollabState>(
                  builder: (bCtx, bState) {
                    final requesting =
                        bState is CollabLoaded && bState.isRequesting;
                    return GoldButton(
                      label: 'Submit Request',
                      isLoading: requesting,
                      onTap: () {
                        if (nameCtrl.text.isEmpty) return;
                        context.read<CollabBloc>().add(RequestCollab(
                              ngoName: nameCtrl.text,
                              type: selectedType,
                              about: aboutCtrl.text,
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

  String _typeLabel(CollabType t) {
    switch (t) {
      case CollabType.fundingPartner:
        return 'Funding Partner';
      case CollabType.resourceSharing:
        return 'Resource Sharing';
      case CollabType.csrPartner:
        return 'CSR Partner';
      case CollabType.technical:
        return 'Technical Partner';
    }
  }
}

// ── Collab Card ───────────────────────────────────────────────────────────────
class _CollabCard extends StatelessWidget {
  final CollaborationEntity collab;
  const _CollabCard({required this.collab});

  @override
  Widget build(BuildContext context) {
    final statusColor = collab.status == CollabStatus.approved
        ? AppColors.success
        : collab.status == CollabStatus.rejected
            ? AppColors.error
            : AppColors.pending;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  collab.ngoName[0].toUpperCase(),
                  style: AppTextStyles.headlineSmall.copyWith(color: statusColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collab.ngoName, style: AppTextStyles.titleLarge),
                    Text(collab.typeLabel,
                        style: AppTextStyles.caption.copyWith(color: AppColors.gold)),
                  ],
                ),
              ),
              StatusBadge(
                status: collab.status == CollabStatus.approved
                    ? 'Approved'
                    : collab.status == CollabStatus.rejected
                        ? 'Rejected'
                        : 'Pending',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.divider, height: 0),
          const SizedBox(height: 10),
          Text(collab.about,
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (collab.status == CollabStatus.approved) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlineGoldButton(
                    label: 'View Details',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
