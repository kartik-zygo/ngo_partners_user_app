import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/moderation/content_filter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/community_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import '../legal/terms_of_use_page.dart';
import 'community_widgets.dart';

/// Compose a new community question or discussion. Pops the created
/// [CommunityPost] on success.
class AskQuestionPage extends StatefulWidget {
  const AskQuestionPage({super.key});

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  final _create = GetIt.instance<CreateCommunityPostUseCase>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  String _postType = 'question';
  final List<String> _tags = [];
  bool _submitting = false;

  static const _suggested = [
    'fundraising', 'grants', 'compliance', '80g-12a', 'fcra',
    'csr', 'volunteers', 'governance', 'tax-exemption', 'impact',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final t = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    if (t.length < 2) return;
    if (_tags.length >= 5 || _tags.contains(t)) return;
    setState(() {
      _tags.add(t);
      _tagCtrl.clear();
    });
  }

  bool get _valid =>
      _titleCtrl.text.trim().length >= 8 && _bodyCtrl.text.trim().length >= 15;

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    if (ContentFilter.anyObjectionable(
        [_titleCtrl.text, _bodyCtrl.text, ..._tags])) {
      _showError('Your post contains language that is not allowed in the '
          'Community. Please edit it and try again.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final post = await _create(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        postType: _postType,
        tags: _tags,
      );
      if (!mounted) return;
      Navigator.of(context).pop<CommunityPost>(post);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Ask the Community'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // Type toggle
          Row(
            children: [
              _typeOption('question', 'Question', Icons.help_outline_rounded),
              const SizedBox(width: 10),
              _typeOption('discussion', 'Discussion', Icons.forum_outlined),
            ],
          ),
          const SizedBox(height: 18),
          _label('Title'),
          const SizedBox(height: 6),
          _field(
            controller: _titleCtrl,
            hint: _postType == 'question'
                ? 'e.g. How do we apply for 80G & 12A registration?'
                : 'e.g. Best tools for volunteer management?',
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text('Be specific — at least 8 characters.',
              style: AppTextStyles.caption),
          const SizedBox(height: 16),
          _label('Details'),
          const SizedBox(height: 6),
          _field(
            controller: _bodyCtrl,
            hint:
                'Share the full context — what you have tried, documents involved, deadlines, etc.',
            maxLines: 8,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _label('Tags (up to 5)'),
          const SizedBox(height: 6),
          _field(
            controller: _tagCtrl,
            hint: 'Type a tag and press enter',
            maxLines: 1,
            onSubmitted: _addTag,
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((t) => GestureDetector(
                        onTap: () => setState(() => _tags.remove(t)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: CommunityTheme.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(prettyTag(t),
                                  style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10)),
                              const SizedBox(width: 4),
                              const Icon(Icons.close_rounded,
                                  size: 13, color: Colors.white),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text('Suggested', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggested
                .where((t) => !_tags.contains(t))
                .map((t) => CommunityTagChip(tag: t, onTap: () => _addTag(t)))
                .toList(),
          ),
          const SizedBox(height: 20),
          _buildRulesNotice(),
        ],
      ),
      bottomSheet: Wrap(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            child: GoldButton(
              label: _postType == 'question'
                  ? 'Post Question'
                  : 'Start Discussion',
              color: CommunityTheme.accent,
              isLoading: _submitting,
              onTap: _valid ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeOption(String value, String label, IconData icon) {
    final selected = _postType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _postType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: selected ? CommunityTheme.gradient : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.borderSubtle,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : CommunityTheme.accent,
                  size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CommunityTheme.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CommunityTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              size: 18, color: CommunityTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep it respectful. Abusive or objectionable posts are '
                  'removed, and their authors are removed from the Community.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TermsOfUsePage())),
                  child: Text(
                    'Read the Community rules',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: CommunityTheme.accent,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.labelLarge);

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        style: AppTextStyles.bodyLarge,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
