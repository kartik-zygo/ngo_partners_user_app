import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/quotation_entity.dart';
import '../../../blocs/quotations/quotations_bloc.dart';

/// Tracker for the client's own quotation requests. The UI branches on
/// [QuotationEntity.status]; the sentence shown is always the server's
/// `statusLabel`, printed as-is.
class MyQuotationsPage extends StatelessWidget {
  const MyQuotationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<QuotationsBloc>()..add(const LoadQuotations()),
      child: const _MyQuotationsView(),
    );
  }
}

class _MyQuotationsView extends StatefulWidget {
  const _MyQuotationsView();

  @override
  State<_MyQuotationsView> createState() => _MyQuotationsViewState();
}

class _MyQuotationsViewState extends State<_MyQuotationsView> {
  StreamSubscription<Map<String, dynamic>>? _statusSub;

  @override
  void initState() {
    super.initState();
    // `quotation:statusChanged` lands in the client's own room whenever a rep
    // moves their request — refetch rather than patch, the label comes from
    // the server.
    _statusSub = GetIt.instance<SocketService>()
        .quotationStatusChangedStream
        .listen((_) {
      if (!mounted) return;
      context.read<QuotationsBloc>().add(const LoadQuotations());
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('My Quotations'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<QuotationsBloc, QuotationsState>(
        builder: (context, state) {
          return Column(
            children: [
              _StatusFilterBar(
                active: state.activeStatus,
                onSelect: (status) => context
                    .read<QuotationsBloc>()
                    .add(FilterQuotationsByStatus(status)),
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuotationsState state) {
    if (state.isLoading && state.quotations.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerBox(width: double.infinity, height: 130),
        ),
      );
    }

    if (state.listError != null) {
      return _ErrorState(
        message: state.listError!,
        onRetry: () =>
            context.read<QuotationsBloc>().add(const LoadQuotations()),
      );
    }

    if (state.quotations.isEmpty) {
      return _EmptyState(filtered: state.activeStatus != null);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<QuotationsBloc>().add(const LoadQuotations());
        await context
            .read<QuotationsBloc>()
            .stream
            .firstWhere((s) => !s.isLoading);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.quotations.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _QuotationCard(quotation: state.quotations[i]),
        ),
      ),
    );
  }
}

// ── Status colours ────────────────────────────────────────────────────────────
Color quotationStatusColor(String status) {
  switch (status) {
    case QuotationStatus.submitted:
      return AppColors.warning;
    case QuotationStatus.assigned:
    case QuotationStatus.contacted:
      return AppColors.info;
    case QuotationStatus.qualified:
    case QuotationStatus.quoted:
      return AppColors.primary;
    case QuotationStatus.closedWon:
      return AppColors.success;
    case QuotationStatus.closedLost:
      return AppColors.textMuted;
    default:
      return AppColors.textSecondary;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case QuotationStatus.submitted:
      return Icons.mark_email_unread_outlined;
    case QuotationStatus.assigned:
      return Icons.person_pin_rounded;
    case QuotationStatus.contacted:
      return Icons.phone_in_talk_rounded;
    case QuotationStatus.qualified:
      return Icons.forum_rounded;
    case QuotationStatus.quoted:
      return Icons.request_quote_rounded;
    case QuotationStatus.closedWon:
      return Icons.verified_rounded;
    case QuotationStatus.closedLost:
      return Icons.do_not_disturb_on_outlined;
    default:
      return Icons.help_outline_rounded;
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────
class _StatusFilterBar extends StatelessWidget {
  final String? active;
  final void Function(String?) onSelect;

  const _StatusFilterBar({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final entries = <(String?, String)>[
      (null, 'All'),
      ...QuotationStatus.filterable
          .map((s) => (s, QuotationStatus.shortLabel(s))),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: entries.map((entry) {
            final selected = active == entry.$1;
            final color =
                entry.$1 == null ? AppColors.primary : quotationStatusColor(entry.$1!);
            return GestureDetector(
              onTap: () => onSelect(entry.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.12)
                      : AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? color : AppColors.borderSubtle,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.$2,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────
class _QuotationCard extends StatelessWidget {
  final QuotationEntity quotation;
  const _QuotationCard({required this.quotation});

  String get _dateDisplay {
    final dt = quotation.createdAt;
    if (dt == null) return '';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  void _copyReference(BuildContext context) {
    Clipboard.setData(ClipboardData(text: quotation.reference));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${quotation.reference} copied'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = quotationStatusColor(quotation.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(quotation.status),
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quotation.serviceName.isEmpty
                          ? 'Service enquiry'
                          : quotation.serviceName,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_dateDisplay.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Raised $_dateDisplay',
                          style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
              if (quotation.reference.isNotEmpty)
                GestureDetector(
                  onTap: () => _copyReference(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      quotation.reference,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _StatusTrack(status: quotation.status),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quotation.statusLabel.isNotEmpty
                  ? quotation.statusLabel
                  : QuotationStatus.shortLabel(quotation.status),
              style: AppTextStyles.bodyMedium.copyWith(color: color),
            ),
          ),
          if (quotation.salesRepName != null &&
              quotation.salesRepName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.support_agent_rounded,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Handled by ${quotation.salesRepName}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (quotation.message != null && quotation.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    quotation.message!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

// ── Progress track ────────────────────────────────────────────────────────────
class _StatusTrack extends StatelessWidget {
  final String status;
  const _StatusTrack({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = quotationStatusColor(status);

    if (status == QuotationStatus.closedLost) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Closed', style: AppTextStyles.caption),
        ],
      );
    }

    final total = QuotationStatus.pipeline.length;
    final reached = status == QuotationStatus.closedWon
        ? total
        : QuotationStatus.pipeline.indexOf(status) + 1;

    return Row(
      children: List.generate(total, (i) {
        final filled = i < reached;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              height: 5,
              decoration: BoxDecoration(
                color: filled ? color : AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool filtered;
  const _EmptyState({required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(Icons.request_quote_outlined,
                  color: AppColors.textMuted, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              filtered ? 'Nothing in this status' : 'No quotation requests yet',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Try a different filter to see your other requests.'
                  : 'Pick a service and tap Get Quotation — our sales team '
                      'will take it from there.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
