import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/features/practice/data/practice_session_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';
import 'package:topik_go/features/questions/data/practice_set_resolution.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';
import 'package:topik_go/features/questions/data/writing_practice_set.dart';

class WritingPracticePage extends ConsumerStatefulWidget {
  const WritingPracticePage({super.key});

  @override
  ConsumerState<WritingPracticePage> createState() =>
      _WritingPracticePageState();
}

class _WritingPracticePageState extends ConsumerState<WritingPracticePage> {
  int _currentIndex = 0;
  bool _submitted = false;
  bool _saving = false;
  String? _sessionId;
  final Map<String, TextEditingController> _controllers = {};
  final DateTime _startedAt = DateTime.now();

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setId = ref.watch(questionSetsProvider).maybeWhen(
          data: (sets) => resolvedPracticeSetId(
            sets: sets,
            section: WritingPracticeSet.section,
            fallbackId: WritingPracticeSet.id,
          ),
          orElse: () => WritingPracticeSet.id,
        );
    final questions = ref.watch(
      practiceQuestionsProvider(
        PracticeSetQuestionsKey(
          section: WritingPracticeSet.section,
          setId: setId,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(title: const Text('TOPIK II 쓰기')),
      body: questions.when(
        data: (page) {
          if (page.items.isEmpty) {
            return const Center(child: Text('쓰기 문제가 없습니다.'));
          }

          final safeIndex = _currentIndex.clamp(0, page.items.length - 1);
          final question = page.items[safeIndex];
          final controller = _controllerFor(question);
          final config = _WritingInputConfig.fromQuestion(question);

          return Column(
            children: [
              _ProgressHeader(
                current: safeIndex + 1,
                total: page.items.length,
                question: question,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_submitted) ...[
                      _SummaryCard(
                        answered: _answeredCount(page.items),
                        total: page.items.length,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _ExamPaper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ExamInstruction(question: question),
                          const SizedBox(height: 14),
                          if (question.passageText?.isNotEmpty ?? false) ...[
                            _PassageCard(text: question.passageText!),
                            const SizedBox(height: 18),
                          ],
                          Text(
                            question.prompt,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _WritingEditor(
                            controller: controller,
                            config: config,
                            enabled: !_submitted && !_saving,
                          ),
                          if (_submitted) ...[
                            const SizedBox(height: 16),
                            _ReviewCard(
                              textAnswer: controller.text,
                              explanation: question.explanation,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _BottomControls(
                canGoPrevious: safeIndex > 0,
                canGoNext: safeIndex < page.items.length - 1,
                saving: _saving,
                submitted: _submitted,
                onPrevious: () => setState(() => _currentIndex = safeIndex - 1),
                onNext: () => setState(() => _currentIndex = safeIndex + 1),
                onSubmit: () => _submitWriting(page.items),
                onEditAgain: () => setState(() => _submitted = false),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(
                practiceQuestionsProvider(
                  PracticeSetQuestionsKey(
                    section: WritingPracticeSet.section,
                    setId: readResolvedPracticeSetId(
                      ref,
                      section: WritingPracticeSet.section,
                      fallbackId: WritingPracticeSet.id,
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  TextEditingController _controllerFor(Question question) {
    return _controllers.putIfAbsent(question.id, TextEditingController.new);
  }

  int _answeredCount(List<Question> questions) {
    return questions
        .where((question) => _controllerFor(question).text.trim().isNotEmpty)
        .length;
  }

  Future<void> _submitWriting(List<Question> questions) async {
    if (_answeredCount(questions) == 0) {
      _showMessage('먼저 답안을 작성해주세요.');
      return;
    }

    setState(() => _saving = true);

    try {
      final repository = ref.read(practiceSessionRepositoryProvider);
      final sessionId = await _ensureSession(repository);
      final spentSeconds = DateTime.now().difference(_startedAt).inSeconds;

      for (final question in questions) {
        final answer = _controllerFor(question).text.trim();
        if (answer.isEmpty) continue;
        await repository.saveAnswer(
          sessionId: sessionId,
          questionId: question.id,
          textAnswer: answer,
          spentTimeSeconds: spentSeconds,
        );
      }

      if (!mounted) return;
      setState(() => _submitted = true);
      _showMessage('쓰기 답안이 저장되었습니다.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<String> _ensureSession(PracticeSessionRepository repository) async {
    if (_sessionId != null) return _sessionId!;

    final session = await repository.createSession(
      questionSetId: WritingPracticeSet.id,
      section: WritingPracticeSet.section,
      level: WritingPracticeSet.level,
    );
    if (session.id.isEmpty) {
      throw StateError('세션 ID를 받지 못했습니다.');
    }

    _sessionId = session.id;
    await repository.updateProgress(sessionId: session.id, currentIndex: 0);
    return session.id;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WritingInputConfig {
  const _WritingInputConfig({
    required this.label,
    required this.hint,
    required this.minLines,
    required this.maxLines,
    required this.targetLabel,
  });

  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final String targetLabel;

  factory _WritingInputConfig.fromQuestion(Question question) {
    switch (question.questionType) {
      case 'writing_graph_description':
        return const _WritingInputConfig(
          label: '답안 작성',
          hint: '그래프나 표의 핵심 내용을 200-300자로 쓰세요.',
          minLines: 8,
          maxLines: 12,
          targetLabel: '권장 200-300자',
        );
      case 'writing_essay':
        return const _WritingInputConfig(
          label: '답안 작성',
          hint: '주제에 맞게 600-700자로 글을 쓰세요.',
          minLines: 12,
          maxLines: 18,
          targetLabel: '권장 600-700자',
        );
      case 'writing_short_completion':
      default:
        return const _WritingInputConfig(
          label: '답안',
          hint: '알맞은 내용을 쓰세요.',
          minLines: 2,
          maxLines: 4,
          targetLabel: '짧은 답안',
        );
    }
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.question,
  });

  final int current;
  final int total;
  final Question question;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOPIK II 쓰기',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('$current / $total'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: total == 0 ? 0 : current / total,
                backgroundColor: Colors.black12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '문항 ${question.questionNumber}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamPaper extends StatelessWidget {
  const _ExamPaper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ExamInstruction extends StatelessWidget {
  const _ExamInstruction({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final numberLabel = question.questionNumber > 0
        ? '${question.questionNumber}.'
        : '문제';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numberLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _instructionFor(question.questionType),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  String _instructionFor(String type) {
    switch (type) {
      case 'writing_graph_description':
        return '다음 자료를 보고 설명하는 글을 쓰십시오.';
      case 'writing_essay':
        return '다음 주제에 대해 자신의 생각을 쓰십시오.';
      case 'writing_short_completion':
      default:
        return '다음을 읽고 알맞은 내용을 쓰십시오.';
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
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black38),
      ),
      child: Text(text, style: const TextStyle(height: 1.55)),
    );
  }
}

class _WritingEditor extends StatefulWidget {
  const _WritingEditor({
    required this.controller,
    required this.config,
    required this.enabled,
  });

  final TextEditingController controller;
  final _WritingInputConfig config;
  final bool enabled;

  @override
  State<_WritingEditor> createState() => _WritingEditorState();
}

class _WritingEditorState extends State<_WritingEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _WritingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.text.characters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.config.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text('$count자 / ${widget.config.targetLabel}'),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          minLines: widget.config.minLines,
          maxLines: widget.config.maxLines,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: widget.config.hint,
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.textAnswer, required this.explanation});

  final String textAnswer;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFAFAFA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('제출한 답안', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(textAnswer.trim().isEmpty ? '미작성' : textAnswer.trim()),
            if (explanation?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              const Text(
                '예시 답안 / 검토 가이드',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(explanation!, style: const TextStyle(height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.saving,
    required this.submitted,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.onEditAgain,
  });

  final bool canGoPrevious;
  final bool canGoNext;
  final bool saving;
  final bool submitted;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final VoidCallback onEditAgain;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canGoPrevious ? onPrevious : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('이전'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canGoNext ? onNext : null,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('다음'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving
                      ? null
                      : (submitted ? onEditAgain : onSubmit),
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(submitted ? Icons.edit_outlined : Icons.upload),
                  label: Text(
                    saving ? '저장 중...' : (submitted ? '다시 작성' : '답안 제출'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.answered, required this.total});

  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '쓰기 제출 완료',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('작성 $answered문항 / 전체 $total문항'),
            const SizedBox(height: 6),
            const Text('쓰기 문제는 자동 채점하지 않고 예시 답안과 검토 가이드를 제공합니다.'),
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
