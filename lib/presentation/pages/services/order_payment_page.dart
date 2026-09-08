import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/socket_service.dart';
import '../../../domain/entities/order_entity.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import 'payment_declaration_page.dart';

class OrderPaymentPage extends StatefulWidget {
  final OrderEntity order;

  const OrderPaymentPage({super.key, required this.order});

  @override
  State<OrderPaymentPage> createState() => _OrderPaymentPageState();
}

class _OrderPaymentPageState extends State<OrderPaymentPage> {
  late OrderEntity _order;
  PaymentInstructions? _instructions;
  bool _loading = false;
  bool _cancelling = false;
  String? _error;

  StreamSubscription<Map<String, dynamic>>? _approvedSub;
  StreamSubscription<Map<String, dynamic>>? _rejectedSub;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _instructions = widget.order.paymentInstructions;
    _listenForDecisions();
    if (_instructions == null && _order.canSubmitPayment) {
      _loadInstructions();
    }
    if (_order.paymentRequests.isEmpty && !_order.isPendingPayment) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _approvedSub?.cancel();
    _rejectedSub?.cancel();
    super.dispose();
  }

  void _listenForDecisions() {
    final socket = GetIt.instance<SocketService>();
    _approvedSub = socket.paymentApprovedStream.listen(_onDecision);
    _rejectedSub = socket.paymentRejectedStream.listen(_onDecision);
  }

  void _onDecision(Map<String, dynamic> payload) {
    if (payload['orderId'] != _order.id) return;
    _refresh();
  }

  Future<void> _loadInstructions() async {
    try {
      final getInstructions = GetIt.instance<GetPaymentInstructionsUseCase>();
      final instructions = await getInstructions();
      if (mounted) setState(() => _instructions = instructions);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final getOrder = GetIt.instance<GetOrderUseCase>();
      final order = await getOrder(_order.id);
      if (!mounted) return;
      setState(() {
        _order = order;
        _instructions = order.paymentInstructions ?? _instructions;
      });
      if (_instructions == null && order.canSubmitPayment) {
        await _loadInstructions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDeclaration() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PaymentDeclarationPage(order: _order)),
    );
    if (submitted == true) {
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment submitted for verification'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Cancel this order?', style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can place the order again at any time.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      final cancel = GetIt.instance<CancelOrderUseCase>();
      final reason = reasonController.text.trim();
      final order = await cancel(_order.id, reason: reason.isEmpty ? null : reason);
      if (!mounted) return;
      setState(() {
        _order = order;
        _cancelling = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatAmount(double value) {
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour < 12 ? 'AM' : 'PM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month]} ${local.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Order Payment', style: AppTextStyles.titleMedium),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _buildOrderCard(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildError(),
            ],
            ..._buildStatusContent(),
            const SizedBox(height: 28),
            ..._buildActions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatusContent() {
    if (_order.isPendingPayment || _order.isRejected) {
      return [
        const SizedBox(height: 16),
        _buildInstructionsCard(),
        if (_order.paymentRequests.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildHistoryCard(),
        ],
      ];
    }
    if (_order.isAwaitingApproval) {
      final request = _order.latestPaymentRequest;
      return [
        if (request != null) ...[
          const SizedBox(height: 16),
          _buildRequestCard(request),
        ],
      ];
    }
    if (_order.isPaid) {
      final request = _order.latestPaymentRequest;
      return [
        const SizedBox(height: 16),
        _buildPaidCard(),
        if (request != null) ...[
          const SizedBox(height: 16),
          _buildRequestCard(request),
        ],
      ];
    }
    return const [];
  }

  Widget _buildStatusBanner() {
    late final Color color;
    late final IconData icon;
    late final String title;
    late final String subtitle;

    if (_order.isPaid) {
      color = AppColors.success;
      icon = Icons.verified_rounded;
      title = 'Payment approved';
      subtitle = 'Your order is placed and our team has started working on it.';
    } else if (_order.isAwaitingApproval) {
      color = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
      title = 'Awaiting verification';
      subtitle =
          'Our team is checking your payment against the bank statement. This usually takes a few hours.';
    } else if (_order.isRejected) {
      color = AppColors.error;
      icon = Icons.report_gmailerrorred_rounded;
      title = 'Payment could not be verified';
      subtitle = _order.rejectionReason ??
          'We could not match this payment. Please check the details and submit again.';
    } else if (_order.isCancelled) {
      color = AppColors.textMuted;
      icon = Icons.cancel_rounded;
      title = 'Order cancelled';
      subtitle = 'This order is no longer active.';
    } else if (_order.isExpired) {
      color = AppColors.textMuted;
      icon = Icons.timer_off_rounded;
      title = 'Order expired';
      subtitle = 'This order is no longer active.';
    } else {
      color = AppColors.warning;
      icon = Icons.account_balance_rounded;
      title = 'Complete your payment';
      subtitle =
          'Transfer the exact amount using the details below, then tap “I have paid”.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.titleMedium.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_order.serviceName,
                    style: AppTextStyles.titleMedium),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${_formatAmount(_order.amount)}',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _DetailRow(label: 'Order ID', value: _order.id, copyable: true, onCopy: _copy),
          _DetailRow(label: 'Status', value: _order.statusLabel),
          if (_order.createdAt != null)
            _DetailRow(
                label: 'Placed on', value: _formatDateTime(_order.createdAt!)),
          if (_order.paidAt != null)
            _DetailRow(
                label: 'Paid on', value: _formatDateTime(_order.paidAt!)),
          if (_order.isPaid && _order.fulfillmentLabel.isNotEmpty)
            _DetailRow(label: 'Progress', value: _order.fulfillmentLabel),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    final instructions = _instructions;
    if (instructions == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Text('Loading payment details…', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Where to pay', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (instructions.hasUpi) ...[
            _PayField(
              label: 'UPI ID',
              value: instructions.upiId!,
              onCopy: _copy,
              highlight: true,
            ),
            const SizedBox(height: 12),
          ],
          if (instructions.qrImageUrl != null &&
              instructions.qrImageUrl!.isNotEmpty) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  instructions.qrImageUrl!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (instructions.hasBankDetails) ...[
            if (instructions.accountName != null)
              _PayField(
                  label: 'Account name',
                  value: instructions.accountName!,
                  onCopy: _copy),
            if (instructions.accountNumber != null)
              _PayField(
                  label: 'Account number',
                  value: instructions.accountNumber!,
                  onCopy: _copy),
            if (instructions.ifsc != null)
              _PayField(
                  label: 'IFSC', value: instructions.ifsc!, onCopy: _copy),
            if (instructions.bankName != null)
              _PayField(
                  label: 'Bank', value: instructions.bankName!, onCopy: _copy),
            if (instructions.branch != null)
              _PayField(
                  label: 'Branch',
                  value: instructions.branch!,
                  onCopy: _copy),
          ],
          if (instructions.instructions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(instructions.instructions,
                        style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            ),
          ],
          if (instructions.supportContact != null &&
              instructions.supportContact!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.support_agent_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Need help? ${instructions.supportContact}',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(PaymentRequestEntity request) {
    final color = request.isApproved
        ? AppColors.success
        : request.isRejected
            ? AppColors.error
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Payment you submitted',
                  style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.label,
                  style: AppTextStyles.caption
                      .copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _DetailRow(label: 'Method', value: request.paymentMethod.label),
          _DetailRow(
            label: 'Reference',
            value: request.referenceNumber,
            copyable: true,
            onCopy: _copy,
          ),
          _DetailRow(
              label: 'Amount', value: '₹${_formatAmount(request.amountClaimed)}'),
          if (request.paidAt != null)
            _DetailRow(
                label: 'Paid on', value: _formatDateTime(request.paidAt!)),
          if (request.payerName != null && request.payerName!.isNotEmpty)
            _DetailRow(label: 'Payer', value: request.payerName!),
          if (request.payerNote != null && request.payerNote!.isNotEmpty)
            _DetailRow(label: 'Note', value: request.payerNote!),
          if (request.reviewNotes != null && request.reviewNotes!.isNotEmpty)
            _DetailRow(label: 'Review notes', value: request.reviewNotes!),
          if (request.proofUrl != null && request.proofUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                request.proofUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 60,
                  alignment: Alignment.center,
                  color: AppColors.bgMid,
                  child: Text('Proof attached', style: AppTextStyles.caption),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Previous attempts', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ..._order.paymentRequests.map((request) {
            final color = request.isApproved
                ? AppColors.success
                : request.isRejected
                    ? AppColors.error
                    : AppColors.warning;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${request.referenceNumber} · ₹${_formatAmount(request.amountClaimed)}',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        Text(
                          request.reviewNotes?.isNotEmpty == true
                              ? '${request.status.label} — ${request.reviewNotes}'
                              : request.status.label,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaidCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in_rounded,
              color: AppColors.success, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'A case has been created for this order. Track its progress from the Cases tab.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    final widgets = <Widget>[];

    if (_order.canSubmitPayment) {
      widgets.add(
        GestureDetector(
          onTap: _openDeclaration,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  _order.isRejected ? 'Submit again' : 'I have paid',
                  style: AppTextStyles.buttonText
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_order.canCancel) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(
        GestureDetector(
          onTap: _cancelling ? null : _cancelOrder,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            alignment: Alignment.center,
            child: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Cancel order',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error)),
          ),
        ),
      );
    }

    if (_order.isPaid || _order.isCancelled || _order.isExpired) {
      widgets.add(
        GestureDetector(
          onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text('Back to Home',
                style: AppTextStyles.buttonText
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final void Function(String, String)? onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (copyable && onCopy != null)
            GestureDetector(
              onTap: () => onCopy!(label, value),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.copy_rounded,
                    size: 15, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayField extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final void Function(String, String) onCopy;

  const _PayField({
    required this.label,
    required this.value,
    required this.onCopy,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primarySurface : AppColors.bgMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? AppColors.borderPrimary : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: highlight
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onCopy(label, value),
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
