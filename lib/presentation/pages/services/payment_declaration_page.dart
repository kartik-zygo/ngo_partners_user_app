import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/order_entity.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../../domain/usecases/app_usecases.dart';

class PaymentDeclarationPage extends StatefulWidget {
  final OrderEntity order;

  const PaymentDeclarationPage({super.key, required this.order});

  @override
  State<PaymentDeclarationPage> createState() => _PaymentDeclarationPageState();
}

class _PaymentDeclarationPageState extends State<PaymentDeclarationPage> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _amountController = TextEditingController();
  final _payerNameController = TextEditingController();
  final _payerNoteController = TextEditingController();

  PaymentMethod _method = PaymentMethod.upi;
  DateTime _paidAt = DateTime.now();
  String? _proofPath;
  String? _proofName;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController.text = _formatAmount(widget.order.amount);
    _payerNameController.text = widget.order.customerName ?? '';
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _amountController.dispose();
    _payerNameController.dispose();
    _payerNoteController.dispose();
    super.dispose();
  }

  String _formatAmount(double value) {
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  Future<void> _pickProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    if (file.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      setState(() => _error = 'Proof file must be 10 MB or smaller.');
      return;
    }
    setState(() {
      _proofPath = file.path;
      _proofName = file.name;
      _error = null;
    });
  }

  Future<void> _pickPaidAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_paidAt),
    );
    if (!mounted) return;

    setState(() {
      _paidAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _paidAt.hour,
        time?.minute ?? _paidAt.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final submit = GetIt.instance<SubmitPaymentRequestUseCase>();
      await submit(
        orderId: widget.order.id,
        paymentMethod: _method.apiValue,
        referenceNumber: _referenceController.text.trim(),
        amountPaid: double.parse(_amountController.text.trim()),
        paidAt: _paidAt,
        payerName: _payerNameController.text.trim(),
        payerNote: _payerNoteController.text.trim(),
        proofFilePath: _proofPath,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Declare Payment', style: AppTextStyles.titleMedium),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _buildOrderSummary(),
              const SizedBox(height: 20),
              _label('Payment method'),
              const SizedBox(height: 8),
              _buildMethodPicker(),
              const SizedBox(height: 18),
              _label(_method.referenceHint),
              const SizedBox(height: 8),
              TextFormField(
                controller: _referenceController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration('e.g. UTR123456789012'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 3) {
                    return 'Enter at least 3 characters';
                  }
                  if (text.length > 120) {
                    return 'Maximum 120 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _label('Amount paid'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('0').copyWith(
                  prefixText: '₹ ',
                  prefixStyle: AppTextStyles.titleMedium,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _buildAmountHint(),
              const SizedBox(height: 18),
              _label('Paid on'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickPaidAt,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(_formatDateTime(_paidAt),
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textPrimary)),
                      const Spacer(),
                      const Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _label('Payer name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _payerNameController,
                decoration: _inputDecoration('Name on the bank account'),
                validator: (value) {
                  if ((value?.trim().length ?? 0) > 255) {
                    return 'Maximum 255 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _label('Note (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _payerNoteController,
                maxLines: 3,
                decoration: _inputDecoration('Anything our team should know'),
                validator: (value) {
                  if ((value?.trim().length ?? 0) > 1000) {
                    return 'Maximum 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _label('Payment proof (optional)'),
              const SizedBox(height: 8),
              _buildProofPicker(),
              if (_error != null) ...[
                const SizedBox(height: 18),
                _buildError(),
              ],
              const SizedBox(height: 26),
              _buildSubmitButton(),
              const SizedBox(height: 12),
              Text(
                'Our team verifies every payment manually. You will be notified once it is approved.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.order.serviceName,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Order total ₹${_formatAmount(widget.order.amount)}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((method) {
        final selected = method == _method;
        return GestureDetector(
          onTap: () => setState(() => _method = method),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderSubtle,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              method.label,
              style: AppTextStyles.labelMedium.copyWith(
                color:
                    selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountHint() {
    final entered = double.tryParse(_amountController.text.trim());
    final matches = entered != null && entered == widget.order.amount;
    return Row(
      children: [
        Icon(
          matches ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 14,
          color: matches ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            matches
                ? 'Matches the order total'
                : 'Transfer the exact order total to avoid delays in verification',
            style: AppTextStyles.caption.copyWith(
              color: matches ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProofPicker() {
    if (_proofPath != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file_rounded,
                size: 18, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _proofName ?? 'Attached',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                _proofPath = null;
                _proofName = null;
              }),
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _pickProof,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderSubtle,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined,
                size: 26, color: AppColors.primary),
            const SizedBox(height: 8),
            Text('Attach screenshot or receipt',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('JPG, PNG or PDF up to 10 MB',
                style: AppTextStyles.caption),
          ],
        ),
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
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _submitting ? null : AppColors.primaryGradient,
          color: _submitting ? AppColors.textMuted : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _submitting
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text('Submit for verification',
                style: AppTextStyles.buttonText
                    .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
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
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}, $hour:$minute $period';
  }
}
