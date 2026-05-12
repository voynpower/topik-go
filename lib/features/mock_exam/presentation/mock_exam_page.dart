import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/mock_exam/data/mock_exam_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';

class MockExamPage extends ConsumerStatefulWidget {
  const MockExamPage({super.key});

  @override
  ConsumerState<MockExamPage> createState() => _MockExamPageState();
}

class _MockExamPageState extends ConsumerState<MockExamPage> {
  MockExamDetail? _detail;
  MockExamResult? _result;
  String? _selectedSetId;
  int _currentIndex = 0;
  bool _loading = false;

  Map<String, String> get _selectedAnswers {
    final answers = _detail?.answers ?? const <MockExamAnswer>[];
    return {
      for (final answer in answers)
        if (answer.selectedAnswer != null)
          answer.questionId: answer.selectedAnswer!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final questionSets = ref.watch(questionSetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('모의고사')),
      body: questionSets.when(
        data: (sets) {
          final mockSets = sets.where(_isMockLike).toList();
          _selectedSetId ??= mockSets.isNotEmpty ? mockSets.first.id : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('모의고사 풀기', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '실제 시험과 같은 환경에서 문제를 풀고 결과를 확인하세요.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.mintDark),
              ),
              const SizedBox(height: 16),
              if (_result != null)
                _ResultCard(result: _result!, onRestart: _reset)
              else if (_detail != null)
                _ExamPanel(
                  detail: _detail!,
                  currentIndex: _currentIndex,
                  selectedAnswers: _selectedAnswers,
                  loading: _loading,
                  onAnswer: _saveAnswer,
                  onPrevious: _currentIndex > 0
                      ? () => _moveToQuestion(_currentIndex - 1)
                      : null,
                  onNext: _currentIndex < (_detail!.questions.length - 1)
                      ? () => _moveToQuestion(_currentIndex + 1)
                      : null,
                  onSubmit: _submit,
                )
              else
                _StartPanel(
                  sets: mockSets,
                  selectedSetId: _selectedSetId,
                  loading: _loading,
                  onSelected: (value) => setState(() => _selectedSetId = value),
                  onStart: _start,
                  onLoadActive: _loadActive,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(apiErrorMessage(error), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  bool _isMockLike(QuestionSet set) {
    final section = set.section.toLowerCase();
    return section == 'mock' || section == 'exam';
  }

  Future<void> _start() async {
    final setId = _selectedSetId;
    if (setId == null || setId.isEmpty) return;

    await _run(() async {
      final detail = await ref
          .read(mockExamRepositoryProvider)
          .createSession(setId: setId);
      setState(() {
        _detail = detail;
        _result = null;
        _currentIndex = detail.session.currentIndex;
      });
    });
  }

  Future<void> _loadActive() async {
    await _run(() async {
      final detail = await ref
          .read(mockExamRepositoryProvider)
          .getActiveSession();
      if (!mounted) return;
      if (detail == null) {
        _showMessage('진행 중인 모의고사가 없습니다.');
        return;
      }

      setState(() {
        _detail = detail;
        _result = null;
        _currentIndex = detail.session.currentIndex;
      });
    });
  }

  Future<void> _moveToQuestion(int index) async {
    final detail = _detail;
    if (detail == null) return;

    await _run(() async {
      final session = await ref
          .read(mockExamRepositoryProvider)
          .updateProgress(
            sessionId: detail.session.id,
            currentIndex: index,
            remainingSeconds: detail.session.remainingSeconds,
          );
      setState(() {
        _detail = MockExamDetail(
          session: session,
          questions: detail.questions,
          answers: detail.answers,
        );
        _currentIndex = index;
      });
    });
  }

  Future<void> _saveAnswer(String questionId, String answer) async {
    final detail = _detail;
    if (detail == null) return;

    await _run(() async {
      final saved = await ref
          .read(mockExamRepositoryProvider)
          .saveAnswer(
            sessionId: detail.session.id,
            questionId: questionId,
            selectedAnswer: answer,
          );
      final updatedAnswers = [
        ...detail.answers.where((item) => item.questionId != questionId),
        saved,
      ];
      setState(() {
        _detail = MockExamDetail(
          session: detail.session,
          questions: detail.questions,
          answers: updatedAnswers,
        );
      });
    });
  }

  Future<void> _submit() async {
    final detail = _detail;
    if (detail == null) return;

    await _run(() async {
      final result = await ref
          .read(mockExamRepositoryProvider)
          .submitSession(detail.session.id);
      setState(() => _result = result);
    });
  }

  void _reset() {
    setState(() {
      _detail = null;
      _result = null;
      _currentIndex = 0;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (error) {
      _showMessage(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({
    required this.sets,
    required this.selectedSetId,
    required this.loading,
    required this.onSelected,
    required this.onStart,
    required this.onLoadActive,
  });

  final List<QuestionSet> sets;
  final String? selectedSetId;
  final bool loading;
  final ValueChanged<String?> onSelected;
  final VoidCallback onStart;
  final VoidCallback onLoadActive;

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return const _InfoCard(
        title: '등록된 모의고사가 없습니다',
        message: '백엔드에 section이 mock 또는 exam인 question set을 추가하면 여기에 표시됩니다.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시험 세트 선택', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedSetId,
              items: sets
                  .map(
                    (set) => DropdownMenuItem(
                      value: set.id,
                      child: Text('${set.title} / ${set.level}급'),
                    ),
                  )
                  .toList(),
              onChanged: loading ? null : onSelected,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: loading ? null : onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('시작하기'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: loading ? null : onLoadActive,
              icon: const Icon(Icons.restore),
              label: const Text('진행 중인 시험 불러오기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamPanel extends StatelessWidget {
  const _ExamPanel({
    required this.detail,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.loading,
    required this.onAnswer,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final MockExamDetail detail;
  final int currentIndex;
  final Map<String, String> selectedAnswers;
  final bool loading;
  final void Function(String questionId, String answer) onAnswer;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final questions = detail.questions;
    if (questions.isEmpty) {
      return const _InfoCard(title: '문제가 없습니다', message: '이 세트에 문제가 없습니다.');
    }

    final question = questions[currentIndex.clamp(0, questions.length - 1)];
    final selectedAnswer = selectedAnswers[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${currentIndex + 1} / ${questions.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${detail.session.remainingSeconds}초'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (question.passageText?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(question.passageText!),
                ],
                const SizedBox(height: 16),
                for (final option in question.options)
                  _OptionTile(
                    option: option,
                    selected: selectedAnswer == option.label,
                    enabled: !loading && option.label.isNotEmpty,
                    onTap: () => onAnswer(question.id, option.label),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : onPrevious,
                child: const Text('이전'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : onNext,
                child: const Text('다음'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: loading ? null : onSubmit,
          icon: const Icon(Icons.check),
          label: const Text('제출하기'),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final QuestionOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.mintDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(8),
            color: selected ? AppColors.mint.withValues(alpha: 0.12) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('${option.label}. ${option.text}')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onRestart});

  final MockExamResult result;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final summary = result.summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('결과', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('점수: ${summary.scorePercent}%'),
            Text('정답: ${summary.correctCount} / ${summary.totalQuestions}'),
            Text('응답: ${summary.answeredCount}개'),
            Text('오답: ${summary.incorrectCount}개'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRestart, child: const Text('다시 선택하기')),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
