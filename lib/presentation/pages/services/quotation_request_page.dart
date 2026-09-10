import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/quotations/quotations_bloc.dart';
import 'quotation_success_page.dart';

/// The "Get Quotation" form. Contact details are prefilled from the profile
/// but stay editable — this is the record sales will call.
class QuotationRequestPage extends StatelessWidget {
  final ServiceEntity service;
  final UserEntity user;

  const QuotationRequestPage({
    super.key,
    required this.service,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<QuotationsBloc>(),
      child: _QuotationRequestView(service: service, user: user),
    );
  }
}

class _QuotationRequestView extends StatefulWidget {
  final ServiceEntity service;
  final UserEntity user;

  const _QuotationRequestView({required this.service, required this.user});

  @override
  State<_QuotationRequestView> createState() => _QuotationRequestViewState();
}

class _QuotationRequestViewState extends State<_QuotationRequestView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _organization;
  late final TextEditingController _message;

  /// Per-field messages returned by a 422, cleared as soon as the user edits.
  Map<String, String> _serverErrors = const {};

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name = TextEditingController(text: user.name);
    _email = TextEditingController(text: user.email);
    _phone = TextEditingController(text: _digitsOnly(user.phone ?? ''));
    _organization = TextEditingController(
      text: user.organizationName ?? user.ngoName ?? '',
    );
    _message = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _organization.dispose();
    _message.dispose();
    super.dispose();
  }

  /// Profiles often store `+91 98765 43210`; the API wants the bare 10 digits.
  String _digitsOnly(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  void _clearServerError(String field) {
    if (!_serverErrors.containsKey(field)) return;
    setState(() {
      _serverErrors = Map.of(_serverErrors)..remove(field);
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<QuotationsBloc>().add(SubmitQuotation(
          serviceId: widget.service.id,
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          organizationName: _organization.text.trim(),
          message: _message.text.trim(),
        ));
  }

  void _onSubmission(BuildContext context, QuotationsState state) {
    final submission = state.submission;

    if (submission is SubmissionSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuotationSuccessPage(quotation: submission.quotation),
        ),
      );
      return;
    }

    if (submission is SubmissionInvalid) {
      setState(() => _serverErrors = submission.fieldErrors);
      _formKey.currentState!.validate();
      if (submission.fieldErrors.isEmpty) {
        _snack(submission.message, AppColors.error);
      }
      context.read<QuotationsBloc>().add(const ResetQuotationSubmission());
      return;
    }

    if (submission is SubmissionAlreadyOpen) {
      _showAlreadyOpenSheet(submission.reference);
      context.read<QuotationsBloc>().add(const ResetQuotationSubmission());
      return;
    }

    if (submission is SubmissionServiceGone) {
      _snack(
        'This service is no longer available. Pull to refresh the services list.',
        AppColors.warning,
      );
      context.read<QuotationsBloc>().add(const ResetQuotationSubmission());
      return;
    }

    if (submission is SubmissionFailure) {
      _snack(submission.message, AppColors.error);
      context.read<QuotationsBloc>().add(const ResetQuotationSubmission());
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// A 409 means they already have an open request — reassurance, not an error.
  void _showAlreadyOpenSheet(String? reference) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(sheetContext).padding.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.infoBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded,
                  color: AppColors.info, size: 28),
            ),
            const SizedBox(height: 16),
            Text('You already have an open request',
                style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              reference == null
                  ? 'Our sales team will contact you soon about this service.'
                  : 'Request $reference is still open. Our sales team will contact you soon.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: 'Got it',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuotationsBloc, QuotationsState>(
      listenWhen: (prev, curr) => prev.submission != curr.submission,
      listener: _onSubmission,
      builder: (context, state) {
        final isSubmitting = state.submission is SubmissionInProgress;
        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            title: const Text('Get Quotation'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _ServiceHeader(service: widget.service),
                  const SizedBox(height: 20),
                  _Field(
                    label: 'Full name',
                    controller: _name,
                    hint: 'Who should we ask for?',
                    textCapitalization: TextCapitalization.words,
                    serverError: _serverErrors['name'],
                    onChanged: (_) => _clearServerError('name'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 2) return 'Enter at least 2 characters';
                      if (text.length > 200) {
                        return 'Keep this under 200 characters';
                      }
                      return null;
                    },
                  ),
                  _Field(
                    label: 'Email',
                    controller: _email,
                    hint: 'name@organisation.org',
                    keyboardType: TextInputType.emailAddress,
                    serverError: _serverErrors['email'],
                    onChanged: (_) => _clearServerError('email'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Email is required';
                      if (text.length > 255) {
                        return 'Keep this under 255 characters';
                      }
                      if (!_emailPattern.hasMatch(text)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  _Field(
                    label: 'Phone',
                    controller: _phone,
                    hint: '10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    serverError: _serverErrors['phone'],
                    onChanged: (_) => _clearServerError('phone'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (!_phonePattern.hasMatch(text)) {
                        return 'Enter a 10-digit mobile number starting with 6-9';
                      }
                      return null;
                    },
                  ),
                  _Field(
                    label: 'Organisation',
                    optional: true,
                    controller: _organization,
                    hint: 'Your NGO or company name',
                    textCapitalization: TextCapitalization.words,
                    serverError: _serverErrors['organizationName'],
                    onChanged: (_) => _clearServerError('organizationName'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length > 255) {
                        return 'Keep this under 255 characters';
                      }
                      return null;
                    },
                  ),
                  _Field(
                    label: 'What do you need help with?',
                    optional: true,
                    controller: _message,
                    hint: 'Tell us a little about your requirement',
                    maxLines: 4,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    serverError: _serverErrors['message'],
                    onChanged: (_) => _clearServerError('message'),
                  ),
                  const SizedBox(height: 8),
                  const _PricingNote(),
                  const SizedBox(height: 20),
                  GoldButton(
                    label: 'Submit query',
                    icon: Icons.send_rounded,
                    isLoading: isSubmitting,
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _phonePattern = RegExp(r'^[6-9][0-9]{9}$');

// ── Service header ────────────────────────────────────────────────────────────
class _ServiceHeader extends StatelessWidget {
  final ServiceEntity service;
  const _ServiceHeader({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.request_quote_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  service.categoryLabel,
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pricing note ──────────────────────────────────────────────────────────────
class _PricingNote extends StatelessWidget {
  const _PricingNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pricing is shared by our sales team once they understand your '
              'requirement. No payment is collected in the app.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field ─────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final bool optional;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final String? serverError;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.optional = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.serverError,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.labelLarge),
              if (optional) ...[
                const SizedBox(width: 6),
                Text('Optional', style: AppTextStyles.caption),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            style: AppTextStyles.bodyLarge,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
            ),
            // A server message for this field outranks the local rule that let
            // the value through in the first place.
            validator: (value) => serverError ?? validator?.call(value),
          ),
        ],
      ),
    );
  }
}
