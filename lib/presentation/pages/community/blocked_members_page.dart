import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/datasources/community_safety_store.dart';
import '../../../domain/entities/community_entity.dart';
import 'community_widgets.dart';

/// Members the user has blocked in the Community, with the option to unblock.
class BlockedMembersPage extends StatefulWidget {
  final String userId;
  const BlockedMembersPage({super.key, required this.userId});

  @override
  State<BlockedMembersPage> createState() => _BlockedMembersPageState();
}

class _BlockedMembersPageState extends State<BlockedMembersPage> {
  final _store = GetIt.instance<CommunitySafetyStore>();

  @override
  void initState() {
    super.initState();
    _store.load(widget.userId);
    _store.syncBlocks();
  }

  Future<void> _unblock(BlockedCommunityMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Unblock ${member.name}?',
            style: AppTextStyles.headlineSmall),
        content: Text(
          'Their questions, answers and replies will appear in your '
          'Community feed again.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unblock',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _store.unblock(member.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Blocked members'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final members = _store.blockedMembers;
          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 52,
                        color: CommunityTheme.accent.withValues(alpha: 0.6)),
                    const SizedBox(height: 14),
                    Text("You haven't blocked anyone",
                        style: AppTextStyles.headlineSmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(
                      'To block a member, tap ••• on any of their posts or '
                      'answers in the Community.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final member = members[i];
              return GlassCard(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: CommunityTheme.gradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.name,
                              style: AppTextStyles.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('Blocked ${timeAgo(member.blockedAt)}',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _unblock(member),
                      style: TextButton.styleFrom(
                          foregroundColor: CommunityTheme.accent),
                      child: const Text('Unblock',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
