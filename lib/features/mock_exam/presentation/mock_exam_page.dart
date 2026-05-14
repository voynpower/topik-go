import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/mock_exam/data/mock_exam_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart'
    show QuestionOption;

class MockExamPage extends ConsumerStatefulWidget {
  const MockExamPage({super.key});

  @override
  ConsumerState<MockExamPage> createState() => _MockExamPageState();
}

class _MockExamPageState extends ConsumerState<MockExamPage> {
  MockExamDetail? _detail;
  MockExamResult? _result;
  String _selectedTab = 'reading_mock';
  int _currentIndex = 0;
  int _remainingSeconds = 0;
  bool _loading = false;
  Timer? _timer;
  int _syncCounter = 0;

  Map<String, String> get _selectedAnswers {
    final answers = _detail?.answers ?? const <MockExamAnswer>[];
    return {
      for (final answer in answers)
        if (answer.selectedAnswer != null)
          answer.questionId: answer.selectedAnswer!,
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _syncCounter = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        _syncCounter++;
        if (_syncCounter >= 30) {
          _syncCounter = 0;
          _syncProgress();
        }
      } else {
        _timer?.cancel();
        _submit(); // Auto-submit when time is up
      }
    });
  }

  Future<void> _syncProgress() async {
    final detail = _detail;
    if (detail == null) return;

    try {
      await ref
          .read(mockExamRepositoryProvider)
          .updateProgress(
            sessionId: detail.session.id,
            currentIndex: _currentIndex,
            remainingSeconds: _remainingSeconds,
          );
    } catch (e) {
      debugPrint('Failed to sync progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(mockExamCatalogProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('모의고사 풀기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: catalog.when(
        data: (catalog) {
          if (_result != null) {
            return _ResultCard(result: _result!, onRestart: _reset);
          }

          if (_detail != null) {
            return _ExamPanel(
              detail: _detail!,
              currentIndex: _currentIndex,
              remainingSeconds: _remainingSeconds,
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
            );
          }

          final tabs = catalog.tabs;
          final currentItems = tabs[_selectedTab] ?? [];

          return RefreshIndicator(
            onRefresh: () => ref.refresh(mockExamCatalogProvider.future),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 10),
                Text(
                  '실제 시험과 같은 환경에서 모의고사 풀기!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mintDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                _ActiveSessionBanner(
                  session: catalog.activeSession,
                  loading: _loading,
                  onStart: (setId) => _start(setId),
                  onContinue: () => _loadActive(),
                ),
                const SizedBox(height: 24),
                const Text(
                  '문제 유형',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: tabs.keys.map((tab) {
                      final isSelected = _selectedTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_getTabLabel(tab)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedTab = tab);
                          },
                          selectedColor: AppColors.mint.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.mintDark
                                : Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.mint.withValues(alpha: 0.4)
                                : Colors.grey[300]!,
                          ),
                          backgroundColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: currentItems.length,
                  itemBuilder: (context, index) {
                    return _ExamItemCard(
                      item: currentItems[index],
                      onTap: () => _start(currentItems[index].setId),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
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

  String _getTabLabel(String key) {
    switch (key) {
      case 'reading_mock':
        return '읽기 모의고사';
      case 'reading_type':
        return '읽기 유형별';
      case 'listening_mock':
        return '듣기 모의고사';
      case 'listening_type':
        return '듣기 유형별';
      default:
        return key;
    }
  }

  Future<void> _start(String setId) async {
    await _run(() async {
      final repository = ref.read(mockExamRepositoryProvider);
      MockExamDetail? detail;

      try {
        detail = await repository.createSession(setId: setId);
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 409) {
          detail = await repository.getActiveSession();
        } else {
          rethrow;
        }
      }

      if (detail != null) {
        setState(() {
          _detail = detail;
          _result = null;
          _currentIndex = detail!.session.currentIndex;
          _remainingSeconds = detail.session.remainingSeconds;
        });
        _startTimer();
      }
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
        _remainingSeconds = detail.session.remainingSeconds;
      });
      _startTimer();
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
            remainingSeconds: _remainingSeconds,
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
      _timer?.cancel();
      final repository = ref.read(mockExamRepositoryProvider);
      await repository.submitSession(detail.session.id);
      final result = await repository.getResult(detail.session.id);
      setState(() => _result = result);
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _detail = null;
      _result = null;
      _currentIndex = 0;
      _remainingSeconds = 0;
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

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({
    required this.session,
    required this.loading,
    required this.onStart,
    required this.onContinue,
  });

  final MockExamSession? session;
  final bool loading;
  final Function(String) onStart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_outlined, color: AppColors.mint),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '모의고사 풀기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to history
                },
                child: Text(
                  '최근 학습 기록',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (session != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        session?.title ?? '모의고사',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      InkWell(
                        onTap: loading ? null : onContinue,
                        child: Row(
                          children: [
                            Text(
                              '이어풀기',
                              style: TextStyle(
                                color: AppColors.mintDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.mintDark,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.assignment_outlined,
                        label: '남은 문제',
                        value:
                            '${session?.remainingQuestions ?? 0}/${session?.totalQuestions ?? 0}',
                      ),
                      const SizedBox(width: 24),
                      _StatItem(
                        icon: Icons.timer_outlined,
                        label: '남은 시간',
                        value: session?.remainingTimeLabel ?? '00:00',
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '진행 중인 시험이 없습니다.\n아래에서 시험을 선택해 보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

class _ExamItemCard extends StatelessWidget {
  const _ExamItemCard({required this.item, required this.onTap});

  final MockExamCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _PriceBadge(
                  label: item.priceLabel ?? 'free',
                  isFree: item.isFree,
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.assignment_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '총 ${item.totalQuestions}문항',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item.durationLabel ?? '70:00',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.book_outlined,
                color: AppColors.mint.withValues(alpha: 0.3),
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.label, required this.isFree});

  final String label;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.mint.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFree ? Icons.eco : Icons.monetization_on,
            size: 12,
            color: isFree ? AppColors.mintDark : Colors.orange,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isFree ? AppColors.mintDark : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({
    required this.sets,
    required this.activeSession,
    required this.selectedSetId,
    required this.loading,
    required this.onSelected,
    required this.onStart,
    required this.onLoadActive,
  });

  final List<MockExamCatalogItem> sets;
  final MockExamDetail? activeSession;
  final String? selectedSetId;
  final bool loading;
  final ValueChanged<String?> onSelected;
  final VoidCallback onStart;
  final VoidCallback onLoadActive;

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty && activeSession == null) {
      return const _InfoCard(
        title: '등록된 모의고사가 없습니다',
        message: '백엔드 catalog에 모의고사 세트를 추가하면 여기에 표시됩니다.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시험 세트 선택', style: Theme.of(context).textTheme.titleMedium),
            if (activeSession != null) ...[
              const SizedBox(height: 12),
              _ActiveSessionCard(
                activeSession: activeSession!,
                loading: loading,
                onLoadActive: onLoadActive,
              ),
            ],
            const SizedBox(height: 12),
            if (sets.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: selectedSetId,
                items: sets
                    .map(
                      (set) => DropdownMenuItem(
                        value: set.setId,
                        child: Text(
                          '${set.title} / ${set.level == 0 ? 'TOPIK II' : '${set.level}급'}',
                        ),
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
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.activeSession,
    required this.loading,
    required this.onLoadActive,
  });

  final MockExamDetail activeSession;
  final bool loading;
  final VoidCallback onLoadActive;

  @override
  Widget build(BuildContext context) {
    final session = activeSession.session;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('진행 중인 시험', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('문항 ${session.currentIndex + 1} / ${session.totalQuestions}'),
          Text('남은 시간: ${session.remainingSeconds}초'),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: loading ? null : onLoadActive,
            icon: const Icon(Icons.restore),
            label: const Text('이어 풀기'),
          ),
        ],
      ),
    );
  }
}

class _ExamPanel extends StatelessWidget {
  const _ExamPanel({
    required this.detail,
    required this.currentIndex,
    required this.remainingSeconds,
    required this.selectedAnswers,
    required this.loading,
    required this.onAnswer,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final MockExamDetail detail;
  final int currentIndex;
  final int remainingSeconds;
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
                Text('$remainingSeconds초'),
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
