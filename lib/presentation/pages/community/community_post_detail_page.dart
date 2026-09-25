import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/moderation/content_filter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/datasources/community_safety_store.dart';
import '../../../domain/entities/community_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import 'community_moderation.dart';
import 'community_widgets.dart';

/// Full question/discussion thread: vote on the post and answers, read the
/// accepted solution, post an answer, and (as the author) accept an answer.
/// Other members' posts and answers can be reported, and their authors
/// blocked; answers from blocked members are not shown.
class CommunityPostDetailPage extends StatefulWidget {
  final CommunityPost post;
  final String currentUserId;

  const CommunityPostDetailPage({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  @override
  State<CommunityPostDetailPage> createState() =>
      _CommunityPostDetailPageState();
}

class _CommunityPostDetailPageState extends State<CommunityPostDetailPage> {
  final _getPost = GetIt.instance<GetCommunityPostUseCase>();
  final _votePost = GetIt.instance<VoteCommunityPostUseCase>();
  final _voteAnswer = GetIt.instance<VoteCommunityAnswerUseCase>();
  final _addAnswer = GetIt.instance<AddCommunityAnswerUseCase>();
  final _accept = GetIt.instance<AcceptCommunityAnswerUseCase>();
  final _safety = GetIt.instance<CommunitySafetyStore>();

  final _answerCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late CommunityPost _post;
  bool _loading = true;
  bool _posting = false;
  bool _changed = false;
  String? _error;

  bool get _isAuthor => widget.currentUserId == _post.author.id;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _safety.addListener(_onSafetyChanged);
    _load();
  }

  @override
  void dispose() {
    _safety.removeListener(_onSafetyChanged);
    _answerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSafetyChanged() {
    if (mounted) setState(() {});
  }

  /// Report / Block for the post or one of its answers. Leaves the thread
  /// when the post itself is no longer shown (reported, or author blocked).
  Future<void> _openActions(CommunityReportTarget target) async {
    await showCommunityContentActions(context, target: target);
    if (!mounted) return;
    if (!_safety.allowsPost(_post)) Navigator.of(context).pop(true);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await _getPost(_post.id);
      if (!mounted) return;
      setState(() => _post = fresh);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onVotePost(int desired) async {
    final value = _post.myVote == desired ? 0 : desired;
    try {
      final r = await _votePost(postId: _post.id, value: value);
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(voteScore: r.voteScore, myVote: r.myVote);
        _changed = true;
      });
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _onVoteAnswer(CommunityAnswer ans, int desired) async {
    final value = ans.myVote == desired ? 0 : desired;
    try {
      final r = await _voteAnswer(answerId: ans.id, value: value);
      if (!mounted) return;
      setState(() {
        _post = _replaceAnswer(
            ans.copyWith(voteScore: r.voteScore, myVote: r.myVote));
        _changed = true;
      });
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _onAccept(CommunityAnswer ans) async {
    try {
      final fresh = await _accept(postId: _post.id, answerId: ans.id);
      if (!mounted) return;
      setState(() {
        _post = fresh;
        _changed = true;
      });
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.length < 2 || _posting) return;
    if (ContentFilter.isObjectionable(text)) {
      _snack('Your reply contains language that is not allowed in the '
          'Community. Please edit it and try again.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _posting = true);
    try {
      await _addAnswer(postId: _post.id, body: text);
      _answerCtrl.clear();
      final fresh = await _getPost(_post.id);
      if (!mounted) return;
      setState(() {
        _post = fresh;
        _changed = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  CommunityPost _replaceAnswer(CommunityAnswer updated) {
    final answers =
        _post.answers.map((a) => a.id == updated.id ? updated : a).toList();
    return CommunityPost(
      id: _post.id, title: _post.title, body: _post.body, postType: _post.postType,
      tags: _post.tags, viewCount: _post.viewCount, voteScore: _post.voteScore,
      answerCount: _post.answerCount, acceptedAnswerId: _post.acceptedAnswerId,
      isResolved: _post.isResolved, isClosed: _post.isClosed, author: _post.author,
      myVote: _post.myVote, createdAt: _post.createdAt, updatedAt: _post.updatedAt,
      answers: answers,
    );
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.toString().replaceFirst('Exception: ', '')),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(_post.isQuestion ? 'Question' : 'Discussion',
              style: AppTextStyles.headlineSmall),
          actions: [
            if (!_isAuthor)
              IconButton(
                tooltip: 'Report or block',
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () =>
                    _openActions(CommunityReportTarget.post(_post)),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            if (!_post.isClosed) _buildComposer(),
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
          ShimmerBox(width: double.infinity, height: 120),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 90),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 90),
        ],
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 46, color: AppColors.textMuted),
              const SizedBox(height: 14),
              Text(_error!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              SizedBox(width: 150, child: GoldButton(label: 'Retry', color: CommunityTheme.accent, onTap: _load)),
            ],
          ),
        ),
      );
    }

    final answers = _post.answers.where(_safety.allowsAnswer).toList();
    final hiddenCount = _post.answers.length - answers.length;
    return RefreshIndicator(
      color: CommunityTheme.accent,
      onRefresh: _load,
      child: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          _buildQuestionCard(),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                _post.isQuestion
                    ? '${answers.length} ${answers.length == 1 ? 'Answer' : 'Answers'}'
                    : '${answers.length} ${answers.length == 1 ? 'Reply' : 'Replies'}',
                style: AppTextStyles.headlineSmall,
              ),
              const Spacer(),
              if (_post.isResolved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.verified_rounded, size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('Solved',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success, fontWeight: FontWeight.w800)),
                  ]),
                ),
            ],
          ),
          if (hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$hiddenCount hidden: from members you blocked, reported by '
                'you, or flagged by the content filter.',
                style: AppTextStyles.caption,
              ),
            ),
          const SizedBox(height: 12),
          if (answers.isEmpty)
            _emptyAnswers()
          else
            ...answers.map(_buildAnswerCard),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_post.title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VoteControl(
                score: _post.voteScore,
                myVote: _post.myVote,
                onUp: () => _onVotePost(1),
                onDown: () => _onVotePost(-1),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(_post.body, style: AppTextStyles.bodyLarge),
              ),
            ],
          ),
          if (_post.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _post.tags.map((t) => CommunityTagChip(tag: t, small: true)).toList(),
            ),
          ],
          const Divider(height: 26, color: AppColors.divider),
          Row(
            children: [
              CommunityStat(icon: Icons.visibility_outlined, value: '${_post.viewCount} views'),
              const SizedBox(width: 14),
              CommunityStat(
                  icon: Icons.forum_outlined, value: '${_post.answerCount}'),
              const Spacer(),
              Flexible(child: AuthorBadge(author: _post.author, time: _post.createdAt, prefix: 'Asked by ')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(CommunityAnswer ans) {
    final accepted = ans.isAccepted;
    final canAccept = _isAuthor && _post.isQuestion;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: accepted
              ? LinearGradient(colors: [
                  AppColors.successBg,
                  Colors.white,
                ], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accepted
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.borderSubtle,
            width: accepted ? 1.4 : 0.9,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accepted)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.verified_rounded, size: 15, color: AppColors.success),
                  const SizedBox(width: 5),
                  Text('Accepted solution',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w800)),
                ]),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    VoteControl(
                      score: ans.voteScore,
                      myVote: ans.myVote,
                      onUp: () => _onVoteAnswer(ans, 1),
                      onDown: () => _onVoteAnswer(ans, -1),
                    ),
                    if (canAccept) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _onAccept(ans),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: accepted
                                ? AppColors.success
                                : AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.6)),
                          ),
                          child: Icon(Icons.check_rounded,
                              size: 18,
                              color: accepted ? Colors.white : AppColors.success),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(ans.body, style: AppTextStyles.bodyLarge)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (ans.author.id != widget.currentUserId)
                  CommunityMoreButton(
                    alignment: Alignment.centerLeft,
                    onTap: () => _openActions(
                        CommunityReportTarget.answer(ans, postId: _post.id)),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AuthorBadge(author: ans.author, time: ans.createdAt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyAnswers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 38, color: CommunityTheme.accent.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Text(_post.isQuestion ? 'No answers yet' : 'No replies yet',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            _post.isQuestion
                ? 'Know the answer? Help a fellow NGO out below.'
                : 'Be the first to join this discussion.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
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
                controller: _answerCtrl,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: _post.isQuestion ? 'Write an answer…' : 'Add a reply…',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _answerCtrl.text.trim().length >= 2 && !_posting
                ? _submitAnswer
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: _answerCtrl.text.trim().length >= 2 && !_posting
                    ? CommunityTheme.gradient
                    : null,
                color: _answerCtrl.text.trim().length >= 2 && !_posting
                    ? null
                    : AppColors.textMuted.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _posting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
