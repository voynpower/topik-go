import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/practice/data/practice_session_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';

class QuestionDetailPage extends ConsumerStatefulWidget {
  const QuestionDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends ConsumerState<QuestionDetailPage> {
  String? _sessionId;
  String? _selectedAnswer;
  bool _saving = false;
  bool _bookmarkSaving = false;
  bool _submitted = false;
  PracticeResult? _result;
  final DateTime _startedAt = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(questionProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('문제 풀이'),
        actions: [
          question.when(
            data: (item) => _BookmarkButton(
              questionId: item.id,
              saving: _bookmarkSaving,
              onToggle: _toggleBookmark,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: question.when(
        data: (item) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _QuestionHeader(question: item),
            const SizedBox(height: 16),
            if (item.passageText?.isNotEmpty ?? false) ...[
              _PassageCard(text: item.passageText!),
              const SizedBox(height: 16),
            ],
            Text(item.prompt, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (item.options.isEmpty)
              const Text('이 문제에는 선택지가 없습니다.')
            else
              ...item.options.map(
                (option) => _OptionTile(
                  option: option,
                  selected: option.label == _selectedAnswer,
                  onTap: _saving
                      ? null
                      : () => _saveSelectedAnswer(item, option.label),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving || _selectedAnswer == null || _submitted
                  ? null
                  : () => _submitAndLoadResult(item),
              child: Text(_saving ? '저장 중...' : '정답 확인'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultCard(result: _result!),
            ],
            if (_submitted && (item.explanation?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 16),
              _ExplanationCard(title: '해설', text: item.explanation!),
            ],
            if (_submitted && (item.aiExplanation?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              _ExplanationCard(title: 'AI 해설', text: item.aiExplanation!),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(questionProvider(widget.id)),
        ),
      ),
    );
  }

  Future<String?> _ensureSession(Question question) async {
    if (_sessionId != null) return _sessionId;

    final setId = question.setId;
    if (setId == null || setId.isEmpty) {
      _showMessage('이 문제에는 question set 정보가 없어 세션을 시작할 수 없습니다.');
      return null;
    }

    final repository = ref.read(practiceSessionRepositoryProvider);
    final session = await repository.createSession(
      questionSetId: setId,
      section: question.section,
      level: question.level,
    );
    if (session.id.isEmpty) {
      _showMessage('세션 ID를 받지 못했습니다.');
      return null;
    }

    _sessionId = session.id;
    await repository.updateProgress(sessionId: session.id, currentIndex: 0);
    return session.id;
  }

  Future<void> _saveSelectedAnswer(Question question, String answer) async {
    setState(() {
      _saving = true;
      _selectedAnswer = answer;
    });

    try {
      final sessionId = await _ensureSession(question);
      if (sessionId == null) return;

      final spentSeconds = DateTime.now().difference(_startedAt).inSeconds;
      await ref
          .read(practiceSessionRepositoryProvider)
          .saveAnswer(
            sessionId: sessionId,
            questionId: question.id,
            selectedAnswer: answer,
            spentTimeSeconds: spentSeconds,
          );
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _submitAndLoadResult(Question question) async {
    setState(() => _saving = true);

    try {
      final sessionId = await _ensureSession(question);
      if (sessionId == null) return;

      final repository = ref.read(practiceSessionRepositoryProvider);
      await repository.submitSession(sessionId);
      final result = await repository.getResult(sessionId);

      if (!mounted) return;
      setState(() {
        _result = result;
        _submitted = true;
      });
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleBookmark(String questionId, bool bookmarked) async {
    setState(() => _bookmarkSaving = true);

    try {
      await ref
          .read(bookmarkRepositoryProvider)
          .setQuestionBookmark(questionId: questionId, bookmarked: bookmarked);
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedQuestionsProvider);
      ref.invalidate(bookmarkedQuestionIdsProvider);
      _showMessage(bookmarked ? '북마크에 저장되었습니다.' : '북마크가 해제되었습니다.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _bookmarkSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BookmarkButton extends ConsumerWidget {
  const _BookmarkButton({
    required this.questionId,
    required this.saving,
    required this.onToggle,
  });

  final String questionId;
  final bool saving;
  final Future<void> Function(String questionId, bool bookmarked) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarkedQuestionIdsProvider);

    return bookmarkedIds.when(
      data: (ids) {
        final bookmarked = ids.contains(questionId);
        return IconButton(
          tooltip: bookmarked ? '북마크 해제' : '북마크',
          onPressed: saving ? null : () => onToggle(questionId, !bookmarked),
          icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => IconButton(
        tooltip: '북마크',
        onPressed: saving ? null : () => onToggle(questionId, true),
        icon: const Icon(Icons.bookmark_border),
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final levelLabel = question.level == null ? '' : ' / ${question.level}급';
    final numberLabel = question.questionNumber > 0
        ? '${question.questionNumber}번'
        : '문제';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(numberLabel, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '${_sectionLabel(question.section)}$levelLabel / ${question.questionType}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.mintDark),
            ),
            if (question.questionSetTitle?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text(question.questionSetTitle!),
            ],
          ],
        ),
      ),
    );
  }

  String _sectionLabel(String section) {
    switch (section.toLowerCase()) {
      case 'reading':
        return '읽기';
      case 'listening':
        return '듣기';
      case 'writing':
        return '쓰기';
      default:
        return section;
    }
  }
}

class _PassageCard extends StatelessWidget {
  const _PassageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final QuestionOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.mint.withValues(alpha: 0.16),
          foregroundColor: AppColors.mintDark,
          child: Text(option.label.isEmpty ? '-' : option.label),
        ),
        title: Text(option.text),
        selected: selected,
        selectedTileColor: AppColors.mint.withValues(alpha: 0.08),
        onTap: onTap,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final PracticeResult result;

  @override
  Widget build(BuildContext context) {
    final scoreLabel = result.score == null ? '' : ' / ${result.score}점';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('결과', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '${result.correctCount}/${result.totalQuestions} 정답$scoreLabel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
