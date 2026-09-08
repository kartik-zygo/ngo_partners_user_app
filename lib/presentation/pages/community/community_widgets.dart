import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/community_entity.dart';

/// Community accent — a distinct indigo→violet identity for the forum.
class CommunityTheme {
  CommunityTheme._();
  static const Color accent = Color(0xFF6366F1); // indigo
  static const Color accent2 = AppColors.accentPurple; // violet
  static const LinearGradient gradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

String timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final local = dt.toLocal();
  return '${local.day} ${months[local.month]} ${local.year}';
}

String prettyTag(String slug) => slug
    .split('-')
    .map((w) => w.isEmpty ? w : (w.length <= 3 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}'))
    .join(' ');

// ── Tag chip ─────────────────────────────────────────────────────────────────
class CommunityTagChip extends StatelessWidget {
  final String tag;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;
  final bool small;

  const CommunityTagChip({
    super.key,
    required this.tag,
    this.count,
    this.selected = false,
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 8 : 11, vertical: small ? 4 : 6),
        decoration: BoxDecoration(
          color: selected
              ? CommunityTheme.accent
              : CommunityTheme.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? CommunityTheme.accent
                : CommunityTheme.accent.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          count != null ? '${prettyTag(tag)} · $count' : prettyTag(tag),
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? Colors.white : CommunityTheme.accent,
            fontWeight: FontWeight.w700,
            fontSize: small ? 9 : 10,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ── Author badge ───────────────────────────────────────────────────────────────
class AuthorBadge extends StatelessWidget {
  final CommunityAuthor author;
  final DateTime? time;
  final String? prefix;

  const AuthorBadge({super.key, required this.author, this.time, this.prefix});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: author.isTeam
                ? AppColors.heroEmeraldGradient
                : CommunityTheme.gradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(author.initial,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              )),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${prefix ?? ''}${author.name}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (author.isTeam) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('TEAM',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondaryDark,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      )),
                ),
              ] else if (author.reputation > 0) ...[
                const SizedBox(width: 4),
                Icon(Icons.bolt_rounded, size: 11, color: AppColors.accent),
                Text('${author.reputation}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    )),
              ],
            ],
          ),
        ),
        if (time != null) ...[
          const SizedBox(width: 6),
          Text('· ${timeAgo(time)}',
              style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
        ],
      ],
    );
  }
}

// ── Vote control (vertical up/score/down) ──────────────────────────────────────
class VoteControl extends StatelessWidget {
  final int score;
  final int myVote;
  final bool busy;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const VoteControl({
    super.key,
    required this.score,
    required this.myVote,
    required this.onUp,
    required this.onDown,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(Icons.keyboard_arrow_up_rounded, myVote == 1, onUp),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '$score',
            style: AppTextStyles.titleMedium.copyWith(
              color: myVote == 1
                  ? CommunityTheme.accent
                  : myVote == -1
                      ? AppColors.error
                      : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _arrow(Icons.keyboard_arrow_down_rounded, myVote == -1, onDown),
      ],
    );
  }

  Widget _arrow(IconData icon, bool active, VoidCallback onTap) {
    final color = icon == Icons.keyboard_arrow_up_rounded
        ? CommunityTheme.accent
        : AppColors.error;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : AppColors.bgMid,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : AppColors.borderSubtle,
            width: active ? 1.3 : 1,
          ),
        ),
        child: Icon(icon,
            size: 20, color: active ? color : AppColors.textMuted),
      ),
    );
  }
}

// ── Small stat (icon + value) ───────────────────────────────────────────────────
class CommunityStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;
  const CommunityStat({super.key, required this.icon, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(value,
            style: AppTextStyles.labelSmall.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            )),
      ],
    );
  }
}
