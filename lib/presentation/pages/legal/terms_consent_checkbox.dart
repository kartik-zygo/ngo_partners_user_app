import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'terms_of_use_page.dart';

/// "I agree to the Terms of Use" checkbox for the sign-in and sign-up forms.
/// The link opens the full terms; agreeing there ticks the box.
class TermsConsentCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Highlights the box after the user tried to continue without ticking it.
  final bool showError;

  const TermsConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  @override
  State<TermsConsentCheckbox> createState() => _TermsConsentCheckboxState();
}

class _TermsConsentCheckboxState extends State<TermsConsentCheckbox> {
  late final TapGestureRecognizer _link = TapGestureRecognizer()
    ..onTap = _openTerms;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    final agreed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TermsOfUsePage.review()),
    );
    if (agreed == true && mounted) widget.onChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.showError && !widget.value
        ? AppColors.error
        : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onChanged(!widget.value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: widget.value ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: borderColor, width: 1.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: widget.value
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary, height: 1.45),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Use (EULA)',
                        recognizer: _link,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(
                        text: '. I understand there is no tolerance for '
                            'objectionable content or abusive users.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showError && !widget.value)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 6),
            child: Text(
              'Please agree to the Terms of Use to continue.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
