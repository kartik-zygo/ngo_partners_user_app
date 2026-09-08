import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/community_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../injection_container.dart';
import '../../blocs/community/community_bloc.dart';
import 'ask_question_page.dart';
import 'community_post_detail_page.dart';
import 'community_widgets.dart';

/// The Community Hub feed — a Q&A / discussion forum for NGOs.
class CommunityTab extends StatelessWidget {
  final UserEntity user;
  const CommunityTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunityBloc>(
      create: (_) => sl<CommunityBloc>()..add(const CommunityFeedRequested()),
      child: _CommunityView(user: user),
    );
  }
}

class _CommunityView extends StatefulWidget {
  final UserEntity user;
  const _CommunityView({required this.user});

  @override
  State<_CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<_CommunityView> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _sorts = [
    ('newest', 'New', Icons.fiber_new_rounded),
    ('top', 'Top', Icons.trending_up_rounded),
    ('unanswered', 'Unanswered', Icons.help_outline_rounded),
    ('active', 'Active', Icons.bolt_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 320) {
        context.read<CommunityBloc>().add(const CommunityLoadMore());
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAsk() async {
    final post = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(builder: (_) => const AskQuestionPage()),
    );
    if (!mounted || post == null) return;
    context.read<CommunityBloc>().add(const CommunityRefreshed());
    _openPost(post);
  }

  Future<void> _openPost(CommunityPost post) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailPage(
          post: post,
          currentUserId: widget.user.id,
        ),
      ),
    );
    if (changed == true && mounted) {
      context.read<CommunityBloc>().add(const CommunityRefreshed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: BlocBuilder<CommunityBloc, CommunityState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: CommunityTheme.accent,
                onRefresh: () async {
                  context.read<CommunityBloc>().add(const CommunityRefreshed());
                },
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildFilters(state)),
                    _buildList(state),
                    if (state.loadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: SizedBox(
                              width: 26, height: 26,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: CommunityTheme.accent),
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: CommunityTheme.gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CommunityTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Community', style: AppTextStyles.headlineLarge),
                    Text('Ask, answer & learn with fellow NGOs',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildSearch()),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openAsk,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: CommunityTheme.gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: CommunityTheme.accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Ask',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search the community',
                border: InputBorder.none,
                isCollapsed: true,
              ),
              onSubmitted: (v) =>
                  context.read<CommunityBloc>().add(CommunitySearchChanged(v.trim())),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                context.read<CommunityBloc>().add(const CommunitySearchChanged(''));
                setState(() {});
              },
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(CommunityState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _sorts.map((s) {
              final selected = state.sort == s.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => context.read<CommunityBloc>().add(CommunitySortChanged(s.$1)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? CommunityTheme.gradient : null,
                      color: selected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Colors.transparent : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(s.$3,
                            size: 14,
                            color: selected ? Colors.white : AppColors.textMuted),
                        const SizedBox(width: 5),
                        Text(s.$2,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (state.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: state.tags.take(15).map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CommunityTagChip(
                    tag: t.tag,
                    count: t.count,
                    selected: state.tag == t.tag,
                    onTap: () =>
                        context.read<CommunityBloc>().add(CommunityTagSelected(t.tag)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildList(CommunityState state) {
    if (state.status == CommunityStatus.loading) {
      return const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              ShimmerBox(width: double.infinity, height: 130),
              SizedBox(height: 12),
              ShimmerBox(width: double.infinity, height: 130),
              SizedBox(height: 12),
              ShimmerBox(width: double.infinity, height: 130),
            ],
          ),
        ),
      );
    }
    if (state.status == CommunityStatus.failure && state.posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _CenterMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn\'t load the community',
          subtitle: state.error ?? 'Please try again.',
        ),
      );
    }
    if (state.posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _CenterMessage(
          icon: Icons.forum_outlined,
          title: state.search.isNotEmpty || state.tag != null
              ? 'No posts match your filter'
              : 'No posts yet',
          subtitle: 'Be the first to start a conversation.',
          actionLabel: 'Ask the community',
          onAction: _openAsk,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PostCard(post: state.posts[i], onTap: () => _openPost(state.posts[i])),
          ),
          childCount: state.posts.length,
        ),
      ),
    );
  }
}

// ── Post card ──────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!post.isQuestion)
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 1),
                  child: Icon(Icons.forum_outlined, size: 15, color: CommunityTheme.accent2),
                ),
              Expanded(
                child: Text(post.title,
                    style: AppTextStyles.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              if (post.isResolved) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(post.body,
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  post.tags.take(4).map((t) => CommunityTagChip(tag: t, small: true)).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              CommunityStat(
                icon: Icons.arrow_upward_rounded,
                value: '${post.voteScore}',
                color: post.voteScore > 0 ? CommunityTheme.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              CommunityStat(
                icon: Icons.forum_outlined,
                value: '${post.answerCount}',
                color: post.answerCount > 0 ? AppColors.secondaryDark : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              CommunityStat(icon: Icons.visibility_outlined, value: '${post.viewCount}'),
              const Spacer(),
              Flexible(child: AuthorBadge(author: post.author, time: post.createdAt)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenterMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: CommunityTheme.accent.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text(title, style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 200,
                child: GoldButton(
                    label: actionLabel!, color: CommunityTheme.accent, onTap: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
