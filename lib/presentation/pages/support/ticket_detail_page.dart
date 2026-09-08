import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/ticket_entity.dart';
import '../../../domain/usecases/app_usecases.dart';

/// Full-screen support-ticket conversation. Shows the ticket header, the
/// original request, and the chat thread (`updates`), and lets the user post
/// replies. Pops `true` when the user added at least one reply so the caller
/// can refresh its list.
class TicketDetailPage extends StatefulWidget {
  final TicketEntity ticket;
  const TicketDetailPage({super.key, required this.ticket});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _getTicket = GetIt.instance<GetTicketByIdUseCase>();
  final _addReply = GetIt.instance<AddTicketReplyUseCase>();

  final _composerCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late TicketEntity _ticket;
  bool _loading = true;
  bool _sending = false;
  bool _didReply = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _load();
  }

  @override
  void dispose() {
    _composerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _isClosed =>
      _ticket.status == TicketStatus.closed ||
      _ticket.status == TicketStatus.resolved;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await _getTicket(_ticket.id);
      if (!mounted) return;
      setState(() => _ticket = fresh);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _composerCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _addReply(ticketId: _ticket.id, message: text);
      _composerCtrl.clear();
      _didReply = true;
      final fresh = await _getTicket(_ticket.id);
      if (!mounted) return;
      setState(() => _ticket = fresh);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_didReply);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _ticket.subject,
                style: AppTextStyles.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text('Ticket #${_shortId(_ticket.id)}',
                  style: AppTextStyles.caption),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: StatusBadge(status: _ticket.statusLabel)),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ShimmerBox(width: double.infinity, height: 70),
          SizedBox(height: 12),
          ShimmerBox(width: 220, height: 56),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ShimmerBox(width: 200, height: 56),
          ),
        ],
      );
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    final messages = <_Bubble>[
      // The opening request is rendered as the first user message.
      _Bubble(
        message: _ticket.description.isEmpty
            ? _ticket.subject
            : _ticket.description,
        authorRole: 'user',
        createdAt: _ticket.createdAt,
      ),
      ..._ticket.updates.map(
        (u) => _Bubble(
          message: u.message,
          authorRole: u.authorRole,
          createdAt: u.createdAt,
        ),
      ),
    ];

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: messages.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildMetaHeader();
          return messages[i - 1];
        },
      ),
    );
  }

  Widget _buildMetaHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _priorityColor(_ticket.priority).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.confirmation_number_outlined,
                  color: _priorityColor(_ticket.priority), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InfoChip(
                        label: '${_priorityLabel(_ticket.priority)} priority',
                        color: _priorityColor(_ticket.priority),
                        icon: Icons.flag_outlined,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Opened ${_dateLabel(_ticket.createdAt)}',
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    if (_isClosed) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              'This ticket is ${_ticket.statusLabel.toLowerCase()}. Open a new ticket if you need more help.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.bgMid,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _composerCtrl,
                style: AppTextStyles.bodyLarge,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a reply…',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            enabled: _composerCtrl.text.trim().isNotEmpty && !_sending,
            loading: _sending,
            onTap: _send,
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) =>
      id.length <= 8 ? id : id.substring(0, 8);

  String _dateLabel(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final local = dt.toLocal();
    return '${local.day} ${months[local.month]} ${local.year}';
  }

  String _priorityLabel(TicketPriority p) =>
      p.name[0].toUpperCase() + p.name.substring(1);

  Color _priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.urgent:
      case TicketPriority.high:
        return AppColors.error;
      case TicketPriority.medium:
        return AppColors.warning;
      case TicketPriority.low:
        return AppColors.success;
    }
  }
}

// ── Chat bubble ────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final String message;
  final String authorRole;
  final DateTime? createdAt;

  const _Bubble({
    required this.message,
    required this.authorRole,
    this.createdAt,
  });

  bool get _isUser => authorRole == 'user';

  @override
  Widget build(BuildContext context) {
    final align = _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = _isUser ? AppColors.primary : Colors.white;
    final textColor = _isUser ? Colors.white : AppColors.textPrimary;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(_isUser ? 16 : 4),
      bottomRight: Radius.circular(_isUser ? 4 : 16),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!_isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded,
                        color: Colors.white, size: 11),
                  ),
                  const SizedBox(width: 6),
                  Text('Support Team',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.secondaryDark,
                        letterSpacing: 0.2,
                      )),
                ],
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
              border: _isUser
                  ? null
                  : Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: (_isUser ? AppColors.primary : AppColors.textMuted)
                      .withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(color: textColor),
            ),
          ),
          if (createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(_timeLabel(createdAt!),
                  style: AppTextStyles.labelSmall),
            ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    final time = '$h:$m $ampm';
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Today, $time';
    }
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${local.day} ${months[local.month]}, $time';
  }
}

// ── Send button ─────────────────────────────────────────────────────────────
class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: enabled
              ? AppColors.primaryGradient
              : LinearGradient(colors: [
                  AppColors.textMuted.withValues(alpha: 0.4),
                  AppColors.textMuted.withValues(alpha: 0.4),
                ]),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.2),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────
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
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Couldn\'t load conversation',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 6),
            Text(message,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              child: GoldButton(label: 'Retry', onTap: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}
