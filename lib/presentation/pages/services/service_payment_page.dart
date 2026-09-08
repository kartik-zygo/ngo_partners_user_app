import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import 'order_payment_page.dart';

class ServicePaymentPage extends StatefulWidget {
  final ServiceEntity service;
  final UserEntity user;

  const ServicePaymentPage({
    super.key,
    required this.service,
    required this.user,
  });

  @override
  State<ServicePaymentPage> createState() => _ServicePaymentPageState();
}

class _ServicePaymentPageState extends State<ServicePaymentPage> {
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    try {
      final createOrder = GetIt.instance<CreateOrderUseCase>();
      final notes = _notesController.text.trim();
      final order = await createOrder(
        serviceId: widget.service.id,
        customerPhone: widget.user.phone,
        notes: notes.isEmpty ? null : notes,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderPaymentPage(order: order)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String get _priceDisplay => widget.service.pricingLabel.isNotEmpty
      ? widget.service.pricingLabel
      : '₹${widget.service.price}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
          widget.service.name,
          style: AppTextStyles.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            _buildPriceCard(),
            const SizedBox(height: 20),
            _buildStepsCard(),
            const SizedBox(height: 20),
            _buildNotesField(),
            const SizedBox(height: 28),
            _buildPlaceOrderButton(),
            const SizedBox(height: 12),
            Text(
              'No payment is taken now. You will get the bank and UPI details on the next screen.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_rupee_rounded,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            _priceDisplay,
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.service.name,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.service.durationDays} working days · ${widget.service.categoryLabel}',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildFeatureRow(Icons.verified_rounded,
              'Government-certified process', AppColors.success),
          const SizedBox(height: 10),
          _buildFeatureRow(Icons.support_agent_rounded,
              'Dedicated CA/CS expert', AppColors.primary),
          const SizedBox(height: 10),
          _buildFeatureRow(Icons.fact_check_rounded,
              'Every payment manually verified', AppColors.accentCyan),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    const steps = [
      ('1', 'Place the order', 'We reserve this service for you.'),
      ('2', 'Transfer the amount', 'Use the bank or UPI details we show next.'),
      ('3', 'Declare the payment', 'Enter the reference number and attach a receipt.'),
      ('4', 'We verify and start', 'Our team confirms the transfer and begins work.'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How payment works', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          ...steps.map((step) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderPrimary),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      step.$1,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.$2,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textPrimary)),
                        Text(step.$3, style: AppTextStyles.caption),
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

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes for our team (optional)',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Anything we should know before we start',
            hintStyle:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return GestureDetector(
      onTap: _loading ? null : _placeOrder,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: _loading
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF6366F1)],
                ),
          color: _loading ? AppColors.textMuted : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Place order · $_priceDisplay',
                    style: AppTextStyles.buttonText
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}
