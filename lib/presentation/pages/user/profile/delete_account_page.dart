import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/usecases/auth_usecases.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';

/// Account deletion, as App Review guideline 5.1.1(v) requires: the public
/// page explaining what is removed and kept, with the in-app deletion action
/// pinned beneath it.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, required this.url});

  final String url;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loadFailed = false);
          },
          onWebResourceError: (error) {
            // A failed font or image must not hide a page that rendered.
            if (error.isForMainFrame == false) return;
            if (mounted) setState(() => _loadFailed = true);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }
            // mailto: / tel: links have no handler inside a web view.
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _reload() {
    setState(() {
      _loadFailed = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _openInBrowser() async {
    await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
  }

  /// System back walks the page's own history before leaving the screen.
  Future<void> _handleBack(bool didPop, Object? _) async {
    if (didPop) return;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _startDeletion() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authBloc = context.read<AuthBloc>();

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: AppColors.bgCard,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _DeleteAccountSheet(),
    );
    if (message == null) return;

    // The account and its tokens are gone. Unwind to the dashboard so the
    // auth state change can swap it for the login screen, then sign out.
    navigator.popUntil((route) => route.isFirst);
    authBloc.add(AuthLogoutRequested());
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message.isEmpty ? 'Your account has been deleted.' : message,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = _progress < 100 && !_loadFailed;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Delete Account'),
          actions: [
            IconButton(
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reload,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: loading
                ? LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loadFailed)
                Positioned.fill(
                  child: _LoadError(
                    onRetry: _reload,
                    onOpenInBrowser: _openInBrowser,
                  ),
                ),
            ],
          ),
        ),
        // Kept outside the web view so deletion works even if the page fails.
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.bgDark,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GoldButton(
                  label: 'Delete My Account',
                  icon: Icons.delete_forever_rounded,
                  color: AppColors.error,
                  onTap: _startDeletion,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Collects the current password and a typed confirmation, then deletes.
/// Pops with the server's confirmation message on success.
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  static const _confirmWord = 'DELETE';

  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _reason = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The delete button tracks what has been typed.
    _password.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSubmit =>
      !_submitting &&
      _password.text.isNotEmpty &&
      _confirm.text.trim().toUpperCase() == _confirmWord;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final message = await GetIt.instance<DeleteAccountUseCase>()(
        password: _password.text,
        reason: _reason.text,
      );
      if (mounted) Navigator.of(context).pop(message);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // Leaving mid-request could delete the account without signing out.
      canPop: !_submitting,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Delete your account?',
                      style: AppTextStyles.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This permanently removes your profile and signs you out on '
                'every device. It cannot be undone.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              Text('Current password', style: AppTextStyles.labelMedium),
              const SizedBox(height: 6),
              TextField(
                controller: _password,
                enabled: !_submitting,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Type DELETE to confirm', style: AppTextStyles.labelMedium),
              const SizedBox(height: 6),
              TextField(
                controller: _confirm,
                enabled: !_submitting,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(hintText: 'DELETE'),
              ),
              const SizedBox(height: 14),
              Text(
                'Why are you leaving? (optional)',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reason,
                enabled: !_submitting,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Your feedback helps us improve',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              Opacity(
                opacity: _canSubmit || _submitting ? 1 : 0.5,
                child: GoldButton(
                  label: 'Permanently Delete Account',
                  color: AppColors.error,
                  isLoading: _submitting,
                  onTap: _canSubmit ? _submit : null,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, required this.onOpenInBrowser});

  final VoidCallback onRetry;
  final VoidCallback onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgDark,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  "Couldn't load this page",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection and try again. You can '
                  'still delete your account with the button below.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),
                GoldButton(label: 'Try Again', onTap: onRetry),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onOpenInBrowser,
                  child: const Text('Open in Browser'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
