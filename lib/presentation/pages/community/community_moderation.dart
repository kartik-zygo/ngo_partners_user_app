import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/datasources/community_safety_store.dart';
import '../../../domain/entities/community_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import 'community_widgets.dart';

enum _ContentAction { report, block }

/// Report and Block, offered on every post and answer written by someone
/// else (App Store guideline 1.2). Completes once the chosen action has been
/// applied on this device. The caller's screen may then no longer show
/// [target], because reported content and blocked members are hidden at once
/// through [CommunitySafetyStore].
Future<void> showCommunityContentActions(
  BuildContext context, {
  required CommunityReportTarget target,
}) async {
  final action = await showModalBottomSheet<_ContentAction>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ActionsSheet(target: target),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _ContentAction.report:
      await _report(context, target);
    case _ContentAction.block:
      await _block(context, target);
  }
}

Future<void> _report(BuildContext context, CommunityReportTarget target) async {
  final messenger = ScaffoldMessenger.of(context);
  final alsoBlocked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReportSheet(target: target),
  );
  if (alsoBlocked == null) return;

  // Applied only after the sheet has closed, so a screen that leaves when its
  // content disappears never pops the sheet instead of itself. The server
  // already recorded the report, and the block when [alsoBlocked].
  final store = GetIt.instance<CommunitySafetyStore>();
  await store.hideContent(target.id);
  if (alsoBlocked) await store.block(target.author, onServer: true);

  messenger.showSnackBar(SnackBar(
    content: Text(alsoBlocked
        ? 'Report sent and ${target.author.name} is blocked. Our moderation '
            'team will review it within 24 hours.'
        : 'Report sent. Our moderation team will review it within 24 hours. '
            'This ${target.isPost ? 'post' : 'answer'} is now hidden for you.'),
    backgroundColor: AppColors.success,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<void> _block(BuildContext context, CommunityReportTarget target) async {
  final messenger = ScaffoldMessenger.of(context);
  final name = target.author.name;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text('Block $name?', style: AppTextStyles.headlineSmall),
      content: Text(
        "You won't see $name's questions, answers or replies anymore. This "
        "${target.isPost ? 'post' : 'answer'} will also be sent to our "
        'moderation team for review.\n\nYou can unblock them later from '
        'Community → Blocked members.',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Block',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await _applyBlock(messenger, target);
}

/// The member disappears from the screen before the request is sent. If the
/// server cannot be reached they stay hidden on this device, and Retry sends
/// the block (and the moderation alert) again.
Future<void> _applyBlock(
    ScaffoldMessengerState messenger, CommunityReportTarget target) async {
  final name = target.author.name;
  try {
    await GetIt.instance<CommunitySafetyStore>()
        .block(target.author, target: target);
    messenger.showSnackBar(SnackBar(
      content: Text('$name is blocked. Their posts and answers are hidden, '
          'and our moderation team has been notified.'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  } catch (_) {
    messenger.showSnackBar(SnackBar(
      content: Text("$name is hidden on this device, but we couldn't reach "
          'our moderation team.'),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: () => _applyBlock(messenger, target),
      ),
    ));
  }
}

// ── Actions sheet ──────────────────────────────────────────────────────────────
class _ActionsSheet extends StatelessWidget {
  final CommunityReportTarget target;
  const _ActionsSheet({required this.target});

  @override
  Widget build(BuildContext context) {
    final kind = target.isPost ? 'post' : 'answer';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            const SizedBox(height: 8),
            _tile(
              context,
              icon: Icons.flag_outlined,
              color: AppColors.error,
              title: 'Report $kind',
              subtitle: 'Tell our moderators it breaks the Community rules',
              action: _ContentAction.report,
            ),
            if (target.author.id.isNotEmpty)
              _tile(
                context,
                icon: Icons.block_rounded,
                color: AppColors.textPrimary,
                title: 'Block ${target.author.name}',
                subtitle: 'Hide everything they post and alert our moderators',
                action: _ContentAction.block,
              ),
            ListTile(
              onTap: () => Navigator.of(context).pop(),
              leading: const Icon(Icons.close_rounded,
                  color: AppColors.textMuted),
              title: Text('Cancel', style: AppTextStyles.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required _ContentAction action,
  }) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(action),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: AppTextStyles.titleMedium.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
    );
  }
}

// ── Report sheet ───────────────────────────────────────────────────────────────
/// Pops `true`/`false` (whether the author should also be blocked) once the
/// report has reached the server, or nothing if the user backs out.
class _ReportSheet extends StatefulWidget {
  final CommunityReportTarget target;
  const _ReportSheet({required this.target});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _reportContent = GetIt.instance<ReportCommunityContentUseCase>();
  final _detailsCtrl = TextEditingController();

  CommunityReportReason? _reason;
  bool _alsoBlock = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _reportContent(
        target: widget.target,
        reason: reason,
        details: _detailsCtrl.text,
        blockAuthor: _alsoBlock,
      );
      if (mounted) Navigator.of(context).pop(_alsoBlock);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + media.padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: _Handle()),
              const SizedBox(height: 14),
              Text('Report this ${target.isPost ? 'post' : 'answer'}',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 6),
              Text(
                "Reports are confidential: ${target.author.name} won't know "
                'who reported them. Our moderation team reviews every report '
                'within 24 hours and removes content that breaks the rules.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 14),
              Text('Why are you reporting it?', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              for (final reason in CommunityReportReason.values)
                _ReasonTile(
                  reason: reason,
                  selected: _reason == reason,
                  onTap: _sending ? null : () => setState(() => _reason = reason),
                ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgMid,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _detailsCtrl,
                  enabled: !_sending,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Add details (optional)',
                    border: InputBorder.none,
                    isCollapsed: true,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (target.author.id.isNotEmpty) ...[
                const SizedBox(height: 6),
                CheckboxListTile(
                  value: _alsoBlock,
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _alsoBlock = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: CommunityTheme.accent,
                  title: Text('Also block ${target.author.name}',
                      style: AppTextStyles.bodyLarge),
                  subtitle: Text('Hide everything they post from your feed',
                      style: AppTextStyles.bodySmall),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: 12),
              GoldButton(
                label: 'Submit Report',
                icon: Icons.flag_rounded,
                color: AppColors.error,
                isLoading: _sending,
                onTap: _reason == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final CommunityReportReason reason;
  final bool selected;
  final VoidCallback? onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.error.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.error : AppColors.borderSubtle,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected ? AppColors.error : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reason.label, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(reason.description, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.borderSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
