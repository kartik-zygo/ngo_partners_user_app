import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/case_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../blocs/services/services_bloc.dart';
import '../../../blocs/services/services_bloc_events_states.dart';

class CasesTab extends StatelessWidget {
  final UserEntity user;
  const CasesTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accentCyan,
      onRefresh: () {
        final future = context.read<ServicesBloc>().stream
            .firstWhere((s) => s is ServicesLoaded || s is ServicesError);
        context.read<ServicesBloc>().add(LoadCases(user.id));
        return future;
      },
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Cases',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track progress and upload pending documents quickly',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildOverview(),
          ),
        ),
        BlocBuilder<ServicesBloc, ServicesState>(
          builder: (ctx, state) {
            if (state is ServicesLoading) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerBox(width: double.infinity, height: 120),
                    ),
                    childCount: 3,
                  ),
                ),
              );
            }

            if (state is! ServicesLoaded) return const SliverToBoxAdapter(child: SizedBox.shrink());

            final cases = [...state.cases]
              ..sort((a, b) => _statusRank(a.status).compareTo(_statusRank(b.status)));
            if (cases.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.folder_open_rounded,
                          color: AppColors.textMuted, size: 56),
                      const SizedBox(height: 16),
                      Text('No cases yet', style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Purchase a service to get started',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CaseCard(
                      appCase: cases[i],
                      onUpload: () => _showUploadDialog(ctx, cases[i]),
                    ),
                  ),
                  childCount: cases.length,
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

  Widget _buildOverview() {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (ctx, state) {
        final cases = state is ServicesLoaded ? state.cases : const <CaseEntity>[];
        final activeCount = cases.where((c) => _isActive(c.status)).length;
        final approvedCount = cases.where((c) => c.status == CaseStatus.approved).length;

        return Row(
          children: [
            Expanded(
              child: _OverviewTile(
                label: 'Active',
                value: '$activeCount',
                color: AppColors.accentCyan,
                icon: Icons.bolt_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewTile(
                label: 'Approved',
                value: '$approvedCount',
                color: AppColors.success,
                icon: Icons.verified_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewTile(
                label: 'Total',
                value: '${cases.length}',
                color: AppColors.primary,
                icon: Icons.folder_open_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isActive(CaseStatus status) {
    return status != CaseStatus.approved && status != CaseStatus.rejected;
  }

  int _statusRank(CaseStatus status) {
    if (_isActive(status)) return 0;
    if (status == CaseStatus.approved) return 1;
    return 2;
  }

  static const _fallbackDocs = [
    'PAN Card.pdf',
    'Address Proof.pdf',
    'MOA.pdf',
    'AOA.pdf',
    'IT Returns.pdf',
    'Bank Statement.pdf',
  ];

  void _showUploadDialog(BuildContext context, CaseEntity appCase) {
    final state = context.read<ServicesBloc>().state;
    List<String> docs = _fallbackDocs;
    if (state is ServicesLoaded && appCase.serviceId.isNotEmpty) {
      final idx = state.services.indexWhere((s) => s.id == appCase.serviceId);
      if (idx != -1 && state.services[idx].documents.isNotEmpty) {
        docs = state.services[idx].documents;
      }
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Upload Document', style: AppTextStyles.headlineSmall),
          ),
          const Divider(color: AppColors.divider),
          ...docs.map((doc) => ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
                title: Text(doc, style: AppTextStyles.bodyLarge),
                trailing: const Icon(Icons.upload_rounded, color: AppColors.gold),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUpload(context, appCase, doc);
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    CaseEntity appCase,
    String docName,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    final filePath = result.files.single.path!;

    context.read<ServicesBloc>().add(UploadDocument(
          caseId: appCase.id,
          docName: docName,
          filePath: filePath,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Uploading $docName…'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _OverviewTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: color,
                  )),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Case Card ─────────────────────────────────────────────────────────────────
class _CaseCard extends StatelessWidget {
  final CaseEntity appCase;
  final VoidCallback onUpload;

  const _CaseCard({required this.appCase, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded, color: AppColors.gold, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appCase.serviceName, style: AppTextStyles.titleLarge),
                    if (appCase.createdAt != null)
                      Text(
                        'Filed: ${_formatDate(appCase.createdAt!)}',
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              StatusBadge(status: appCase.statusLabel),
            ],
          ),
          // Progress bar
          const SizedBox(height: 14),
          _ProgressStepper(status: appCase.status),
          const SizedBox(height: 12),
          // Documents
          if (appCase.documents.isNotEmpty) ...[
            Text('Documents (${appCase.documents.length})',
                style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: appCase.documents.map((d) => _DocChip(name: d)).toList(),
            ),
            const SizedBox(height: 10),
          ],
          // Resubmit note
          if (appCase.resubmitNote != null &&
              appCase.resubmitNote!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(appCase.resubmitNote!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.warning)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Upload button
          SizedBox(
            width: double.infinity,
            child: OutlineGoldButton(
              label: '+ Upload Document',
              onTap: onUpload,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Progress Stepper ──────────────────────────────────────────────────────────
class _ProgressStepper extends StatelessWidget {
  final CaseStatus status;
  const _ProgressStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (CaseStatus.submitted, 'Submitted'),
      (CaseStatus.filingInProgress, 'Filing'),
      (CaseStatus.underReview, 'Review'),
      (CaseStatus.approved, 'Approved'),
    ];

    int activeIdx = steps.indexWhere((s) => s.$1 == status);
    if (activeIdx == -1) activeIdx = 0;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector
          final filled = i ~/ 2 < activeIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? AppColors.gold : AppColors.borderSubtle,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step = steps[stepIdx];
        final done = stepIdx < activeIdx;
        final current = stepIdx == activeIdx;
        return Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.gold
                    : current
                        ? AppColors.gold.withValues(alpha: 0.2)
                        : AppColors.glassSurface,
                border: Border.all(
                  color: done || current ? AppColors.gold : AppColors.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, color: AppColors.bgDark, size: 12)
                  : current
                      ? Container(
                          margin: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                          ),
                        )
                      : null,
            ),
            const SizedBox(height: 4),
            Text(step.$2,
                style: AppTextStyles.caption.copyWith(
                  color: done || current ? AppColors.gold : AppColors.textMuted,
                  fontSize: 9,
                )),
          ],
        );
      }),
    );
  }
}

class _DocChip extends StatelessWidget {
  final String name;
  const _DocChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 12),
          const SizedBox(width: 4),
          Text(name,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
