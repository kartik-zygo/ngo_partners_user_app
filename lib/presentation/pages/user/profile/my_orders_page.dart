import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/order_entity.dart';
import '../../../../domain/usecases/app_usecases.dart';

/// Read-only history of orders placed before the quotation cutover. Orders can
/// no longer be created or paid from the app.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  String? _activeFilter;
  List<OrderEntity> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? status}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final getOrders = GetIt.instance<GetOrdersUseCase>();
      final orders = await getOrders(status: status);
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter(String? status) {
    setState(() => _activeFilter = status);
    _load(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const _LegacyNotice(),
          _FilterBar(active: _activeFilter, onSelect: _applyFilter),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerBox(width: double.infinity, height: 120),
        ),
      );
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: () => _load(status: _activeFilter));
    }
    if (_orders.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: () => _load(status: _activeFilter),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OrderCard(order: _orders[i]),
        ),
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final String? active;
  final void Function(String?) onSelect;

  const _FilterBar({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = <(String?, String, Color)>[
      (null, 'All', AppColors.primary),
      (OrderStatus.pendingPayment, 'To Pay', AppColors.warning),
      (OrderStatus.paymentSubmitted, 'In Review', AppColors.info),
      (OrderStatus.paid, 'Paid', AppColors.success),
      (OrderStatus.rejected, 'Rejected', AppColors.error),
      (OrderStatus.cancelled, 'Cancelled', AppColors.textMuted),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: filters.map((f) {
            final selected = active == f.$1;
            final color = f.$3;
            return GestureDetector(
              onTap: () => onSelect(f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.12) : AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? color : AppColors.borderSubtle,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  f.$2,
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

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  const _OrderCard({required this.order});

  Color get _statusColor {
    if (order.isPaid) return AppColors.success;
    if (order.isRejected) return AppColors.error;
    if (order.isCancelled || order.isExpired) return AppColors.textMuted;
    if (order.isAwaitingApproval) return AppColors.info;
    return AppColors.warning;
  }

  Color get _fulfillmentColor {
    switch (order.fulfillmentStatus) {
      case 'completed':
        return AppColors.success;
      case 'refund_initiated':
      case 'refunded':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String get _dateDisplay {
    final dt = order.paidAt ?? order.createdAt;
    if (dt == null) return '';
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  String _month(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: service name + amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.serviceName,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_dateDisplay.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(_dateDisplay, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${order.amount.toStringAsFixed(order.amount.truncateToDouble() == order.amount ? 0 : 2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row: payment status badge + fulfillment label
            Row(
              children: [
                _StatusBadge(
                  label: order.statusLabel,
                  color: _statusColor,
                ),
                if (order.isPaid && order.fulfillmentLabel.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: order.fulfillmentLabel,
                    color: _fulfillmentColor,
                    outlined: true,
                  ),
                ],
                const Spacer(),
                if (order.notes != null && order.notes!.isNotEmpty)
                  Tooltip(
                    message: order.notes!,
                    child: const Icon(Icons.sticky_note_2_outlined,
                        size: 16, color: AppColors.textMuted),
                  ),
              ],
            ),
            if (order.canSubmitPayment) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Contact our sales team to settle this order.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Legacy notice ─────────────────────────────────────────────────────────────
class _LegacyNotice extends StatelessWidget {
  const _LegacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.history_rounded, size: 16, color: AppColors.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Past orders only. New services now start with a quotation '
                'request handled by our sales team.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: outlined ? 0.6 : 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              child: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.textMuted, size: 40),
            ),
            const SizedBox(height: 20),
            Text('No past orders', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Orders placed before the quotation flow would appear here.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
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
