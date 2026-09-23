import 'dart:async';
import 'dart:typed_data';
import 'package:image/image.dart' as image;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/core/network/api_media_url.dart';
import 'package:topik_go/features/explanation_video/data/explanation_video_repository.dart';
import 'package:topik_go/features/mock_exam/data/mock_exam_repository.dart';
import 'package:topik_go/features/mock_exam/data/mock_exam_history_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart'
    show Question, QuestionMedia, QuestionOption;

class MockExamPage extends ConsumerStatefulWidget {
  const MockExamPage({super.key});

  @override
  ConsumerState<MockExamPage> createState() => _MockExamPageState();
}

class _MockExamPageState extends ConsumerState<MockExamPage> {
  MockExamDetail? _detail;
  MockExamResult? _result;
  String? _selectedRound; // null = card selection, '83' or '102' = start screen
  int _currentIndex = 0;
  int _remainingSeconds = 0;
  bool _loading = false;
  Timer? _timer;
  int _syncCounter = 0;
  DateTime? _examStartTime;

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
        _submit(isAutoSubmit: true);
      }
    });
  }

  Future<void> _syncProgress() async {
    final detail = _detail;
    if (detail == null) return;

    try {
      await ref.read(mockExamRepositoryProvider).updateProgress(
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
    if (_result != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        appBar: AppBar(
          title: const Text('모의고사 결과'),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _reset,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [_ResultCard(result: _result!, onRestart: _reset)],
        ),
      );
    }

    if (_detail != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        appBar: AppBar(
          title: Text(_detail!.session.title ?? 'TOPIK II 실전 모의고사'),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('시험 중단'),
                  content: const Text('시험을 중단하고 나가시겠습니까?\n진행 상황은 저장되지 않습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('계속 풀기'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _reset();
                      },
                      child: const Text('나가기'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _ExamPanel(
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
              onSubmit: () => _confirmSubmit(context),
              onJumpTo: _moveToQuestion,
            ),
          ],
        ),
      );
    }

    // ── Phase: Start screen (exam info + 시작하기) ──
    if (_selectedRound != null) {
      final round = _selectedRound!;
      final historyAsync = ref.watch(mockExamHistoryListProvider);

      return Scaffold(
        extendBodyBehindAppBar: true,
        body: _GradientBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              children: [
                _StartScreenHeader(
                  round: round,
                  onBack: () => setState(() => _selectedRound = null),
                ),
                const SizedBox(height: 24),
                _RealExamCard(
                  round: round,
                  loading: _loading,
                  onStart: () => _startExam(round),
                ),
                const SizedBox(height: 28),
                historyAsync.when(
                  data: (history) {
                    final filtered = history
                        .where((h) => h.round == round)
                        .toList();
                    return _ExamHistorySection(
                      history: filtered,
                      onDelete: _deleteHistoryItem,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text('기록을 불러오지 못했습니다: $err'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Phase: Card selection (TOPIK 83 / 102) ──
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            children: [
              _RealExamHeader(
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 24),
              _TopikSelectCard(
                round: '83',
                title: 'TOPIK 제83회',
                subtitle: 'TOPIK II · 중·고급 (3~6급)',
                onTap: () => setState(() => _selectedRound = '83'),
              ),
              const SizedBox(height: 14),
              _TopikSelectCard(
                round: '102',
                title: 'TOPIK 제102회',
                subtitle: 'TOPIK II · 중·고급 (3~6급)',
                onTap: () => setState(() => _selectedRound = '102'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSubmit(BuildContext context) {
    final detail = _detail;
    if (detail == null) return;

    final total = detail.questions.length;
    final answered = _selectedAnswers.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모의고사 제출'),
        content: Text(
          '총 $total문항 중 $answered문항을 풀었습니다.\n정말 시험을 종료하고 제출하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submit(isAutoSubmit: false);
            },
            child: const Text('제출하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _startExam(String round) async {
    await _run(() async {
      _examStartTime = DateTime.now();
      final repository = ref.read(mockExamRepositoryProvider);
      final detail = await repository.loadFullTopikExam(
        ref: ref,
        round: round,
        totalDurationSeconds: 10800, // 180분 = 10,800초
      );

      setState(() {
        _detail = detail;
        _result = null;
        _currentIndex = 0;
        _remainingSeconds = detail.session.remainingSeconds;
      });
      _startTimer();
    });
  }

  Future<void> _moveToQuestion(int index) async {
    final detail = _detail;
    if (detail == null) return;

    setState(() {
      _currentIndex = index;
    });

    try {
      await ref.read(mockExamRepositoryProvider).updateProgress(
            sessionId: detail.session.id,
            currentIndex: index,
            remainingSeconds: _remainingSeconds,
          );
    } catch (e) {
      debugPrint('updateProgress error: $e');
    }
  }

  Future<void> _saveAnswer(String questionId, String answer) async {
    final detail = _detail;
    if (detail == null) return;

    final existingIndex =
        detail.answers.indexWhere((a) => a.questionId == questionId);
    List<MockExamAnswer> updatedAnswers;
    if (existingIndex >= 0) {
      updatedAnswers = List.of(detail.answers);
      updatedAnswers[existingIndex] = MockExamAnswer(
        id: detail.answers[existingIndex].id,
        questionId: questionId,
        selectedAnswer: answer,
      );
    } else {
      updatedAnswers = [
        ...detail.answers,
        MockExamAnswer(
          id: questionId,
          questionId: questionId,
          selectedAnswer: answer,
        ),
      ];
    }
    setState(() {
      _detail = MockExamDetail(
        session: detail.session,
        questions: detail.questions,
        answers: updatedAnswers,
      );
    });

    try {
      await ref.read(mockExamRepositoryProvider).saveAnswer(
            sessionId: detail.session.id,
            questionId: questionId,
            selectedAnswer: answer,
          );
    } catch (e) {
      debugPrint('saveAnswer sync error: $e');
    }
  }

  Future<void> _submit({bool isAutoSubmit = false}) async {
    final detail = _detail;
    if (detail == null) return;

    await _run(() async {
      _timer?.cancel();
      final repository = ref.read(mockExamRepositoryProvider);

      MockExamResult result;
      try {
        await repository.submitSession(detail.session.id);
        result = await repository.getResult(detail.session.id);
      } catch (e) {
        final questions = detail.questions;
        int correctCount = 0;
        for (final q in questions) {
          final sel = _selectedAnswers[q.id];
          if (sel != null &&
              sel.isNotEmpty &&
              q.correctAnswer != null &&
              sel == q.correctAnswer) {
            correctCount++;
          }
        }
        final total = questions.length;
        final answered = _selectedAnswers.length;
        final percent = total > 0 ? (correctCount * 100 ~/ total) : 0;
        result = MockExamResult(
          session: detail.session,
          summary: MockExamSummary(
            totalQuestions: total,
            answeredCount: answered,
            correctCount: correctCount,
            incorrectCount: answered - correctCount,
            scorePercent: percent,
          ),
          answers: [
            for (final entry in _selectedAnswers.entries)
              MockExamAnswer(
                id: entry.key,
                questionId: entry.key,
                selectedAnswer: entry.value,
              ),
          ],
          questions: questions,
        );
      }

      final finalResult = result.questions.isEmpty
          ? result.copyWith(questions: detail.questions)
          : result;

      final now = DateTime.now();
      final historyItem = MockExamHistoryItem(
        id: detail.session.id,
        title: detail.session.title ?? 'TOPIK II 제${_selectedRound ?? '83'}회',
        round: _selectedRound ?? '83',
        startedAt: _examStartTime ??
            now.subtract(Duration(seconds: 10800 - _remainingSeconds)),
        endedAt: now,
        isAutoSubmit: isAutoSubmit,
        sections: const ['L', 'R', 'W'],
        scorePercent: finalResult.summary.scorePercent,
        correctCount: finalResult.summary.correctCount,
        totalQuestions: finalResult.summary.totalQuestions,
      );

      try {
        await ref
            .read(mockExamHistoryRepositoryProvider)
            .saveAttempt(historyItem);
        ref.invalidate(mockExamHistoryListProvider);
      } catch (e) {
        debugPrint('Failed to save exam history: $e');
      }

      setState(() {
        _result = finalResult;
      });
    });
  }

  Future<void> _deleteHistoryItem(String id) async {
    await ref.read(mockExamHistoryRepositoryProvider).deleteAttempt(id);
    ref.invalidate(mockExamHistoryListProvider);
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

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F8F6), Color(0xFFF8FBFF), Color(0xFFFFF8EA)],
        ),
      ),
      child: child,
    );
  }
}

class _RealExamHeader extends StatelessWidget {
  const _RealExamHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: const Color(0xFF1F2937),
            onPressed: onBack,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '실전연습',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '모의고사와 똑같은 환경에서 실전 연습해요.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StartScreenHeader extends StatelessWidget {
  const _StartScreenHeader({
    super.key,
    required this.round,
    required this.onBack,
  });

  final String round;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: const Color(0xFF1F2937),
            onPressed: onBack,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'TOPIK 제$round회',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '모의고사와 똑같은 환경에서 실전 연습해요.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TopikSelectCard extends StatelessWidget {
  const _TopikSelectCard({
    super.key,
    required this.round,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String round;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TOPIK II',
                        style: TextStyle(
                          color: Color(0xFF1D8F86),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Color(0xFF1D8F86),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '듣기 50 · 쓰기 4 · 읽기 50 (총 180분)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RealExamCard extends StatelessWidget {
  const _RealExamCard({
    super.key,
    required this.round,
    required this.loading,
    required this.onStart,
  });

  final String round;
  final bool loading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TOPIK II',
                  style: TextStyle(
                    color: Color(0xFF1D8F86),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '중·고급 (3~6급 판정)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: const Column(
              children: [
                _ExamSectionRow(
                  section: '듣기',
                  count: '50문항',
                  time: '60분',
                  icon: Icons.headphones_outlined,
                ),
                Divider(height: 16, color: Color(0xFFE5E7EB)),
                _ExamSectionRow(
                  section: '쓰기',
                  count: '4문항',
                  time: '50분',
                  icon: Icons.edit_note_outlined,
                ),
                Divider(height: 16, color: Color(0xFFE5E7EB)),
                _ExamSectionRow(
                  section: '읽기',
                  count: '50문항',
                  time: '70분',
                  icon: Icons.menu_book_outlined,
                ),
                SizedBox(height: 12),
                _ExamTotalTimeRow(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4AC4B2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      '시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamTotalTimeRow extends StatelessWidget {
  const _ExamTotalTimeRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: Color(0xFF1D8F86)),
          SizedBox(width: 6),
          Text(
            '총 시험 시간 180분',
            style: TextStyle(
              color: Color(0xFF1D8F86),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamSectionRow extends StatelessWidget {
  const _ExamSectionRow({
    super.key,
    required this.section,
    required this.count,
    required this.time,
    required this.icon,
  });

  final String section;
  final String count;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          section,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const Spacer(),
        Text(
          count,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _ExamHistorySection extends StatelessWidget {
  const _ExamHistorySection({
    super.key,
    required this.history,
    required this.onDelete,
  });

  final List<MockExamHistoryItem> history;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '이전 응시 (${history.length})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            alignment: Alignment.center,
            child: const Text(
              '이전 응시 기록이 없습니다.',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          ...history.map(
            (item) => _ExamHistoryCard(
              item: item,
              onDelete: () => onDelete(item.id),
            ),
          ),
      ],
    );
  }
}

class _ExamHistoryCard extends StatelessWidget {
  const _ExamHistoryCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final MockExamHistoryItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isAutoSubmit ? '자동 제출' : '제출 완료',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(item.startedAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${_formatDurationMinutes(item.startedAt, item.endedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final s in item.sections)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D8F86),
                    ),
                  ),
                ),
              const Spacer(),
              if (item.scorePercent != null)
                Text(
                  '${item.scorePercent}% (${item.correctCount ?? 0}/${item.totalQuestions ?? 0})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y.$m.$d $hh:$mm';
  }

  String _formatDurationMinutes(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final m = diff.inMinutes;
    if (m <= 0) return '1분 미만';
    return '$m분';
  }
}

class _ExamPanel extends StatelessWidget {
  const _ExamPanel({
    super.key,
    required this.detail,
    required this.currentIndex,
    required this.remainingSeconds,
    required this.selectedAnswers,
    required this.loading,
    required this.onAnswer,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    this.onJumpTo,
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
  final void Function(int index)? onJumpTo;

  @override
  Widget build(BuildContext context) {
    final questions = detail.questions;
    if (questions.isEmpty) {
      return const _InfoCard(title: '문제가 없습니다', message: '이 세트에 문제가 없습니다.');
    }

    final question = questions[currentIndex.clamp(0, questions.length - 1)];
    final selectedAnswer = selectedAnswers[question.id];
    final audio = _firstMedia(question.media, 'audio');
    final images = question.media.where(_isImageMedia).toList();
    final documents = question.media.where((media) {
      final type = media.mediaType.toLowerCase();
      final url = media.url.toLowerCase();
      return type.contains('document') ||
          type.contains('pdf') ||
          url.endsWith('.pdf');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${currentIndex + 1} / ${questions.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4AC4B2).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Color(0xFF1D8F86),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatExamDuration(remainingSeconds),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D8F86),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '문항 목록',
                  icon: const Icon(Icons.grid_view_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () => _showQuestionGridSheet(context),
                ),
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
                if (audio != null) ...[
                  _MockAudioCard(media: audio),
                  const SizedBox(height: 14),
                ],
                if (images.isNotEmpty) ...[
                  for (final image in images) _QuestionImage(media: image),
                  const SizedBox(height: 14),
                ],
                if (documents.isNotEmpty &&
                    _isVisualChoiceQuestion(question)) ...[
                  _DocumentPreview(
                    media: documents.first,
                    questionNumber: question.questionNumber,
                  ),
                  const SizedBox(height: 14),
                ],
                _QuestionNumberLabel(question: question),
                const SizedBox(height: 12),
                if (question.passageText?.isNotEmpty ?? false) ...[
                  _PassageBox(text: question.passageText!),
                  const SizedBox(height: 14),
                ],
                if (question.prompt.trim().isNotEmpty) ...[
                  Text(
                    question.prompt,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final option in question.options)
                  _OptionTile(
                    option: option,
                    selected: selectedAnswer == option.label,
                    enabled: !loading && option.label.isNotEmpty,
                    onTap: () => onAnswer(question.id, option.label),
                  ),
                const SizedBox(height: 8),
                _QuestionExplanationVideoButton(question: question),
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
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: const Icon(Icons.check),
            label: const Text('제출하기'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4AC4B2),
            ),
          ),
        ),
      ],
    );
  }

  void _showQuestionGridSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        '전체 문항 목록',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '답변 완료: ${selectedAnswers.length}/${detail.questions.length}',
                        style: const TextStyle(
                          color: Color(0xFF4AC4B2),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: detail.questions.length,
                    itemBuilder: (context, index) {
                      final q = detail.questions[index];
                      final isAnswered = selectedAnswers.containsKey(q.id);
                      final isCurrent = index == currentIndex;

                      return InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          onJumpTo?.call(index);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF4AC4B2)
                                : (isAnswered
                                    ? const Color(0xFFE8F8F5)
                                    : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF4AC4B2)
                                  : (isAnswered
                                      ? const Color(0xFF4AC4B2)
                                          .withValues(alpha: 0.4)
                                      : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? Colors.white
                                  : (isAnswered
                                      ? const Color(0xFF1D8F86)
                                      : const Color(0xFF4B5563)),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  QuestionMedia? _firstMedia(List<QuestionMedia> media, String type) {
    for (final item in media) {
      if (item.mediaType.toLowerCase().contains(type)) return item;
    }
    return null;
  }

  bool _isImageMedia(QuestionMedia media) {
    final type = media.mediaType.toLowerCase();
    final url = media.url.toLowerCase();
    return type.contains('image') ||
        url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.webp');
  }

  bool _isVisualChoiceQuestion(Question question) {
    final content = '${question.passageText ?? ''}\n${question.prompt}';
    return content.contains('그림 또는 그래프') ||
        content.contains('그림') ||
        content.contains('그래프');
  }
}

String _formatExamDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class _QuestionExplanationVideoButton extends ConsumerWidget {
  const _QuestionExplanationVideoButton({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(
      explanationVideosForQueryProvider(
        ExplanationVideoQuery(
          section: question.section,
          questionId: question.id,
          setId: question.setId,
          limit: 1,
        ),
      ),
    );

    return videos.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final video = items.first;
        return Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: video.videoUrl.trim().isEmpty
                ? null
                : () => context.push(
                      Uri(
                        path: '/video-player',
                        queryParameters: {
                          'url': video.videoUrl,
                          'title': video.title,
                        },
                      ).toString(),
                    ),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('해설 영상 보기'),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _QuestionNumberLabel extends StatelessWidget {
  const _QuestionNumberLabel({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final sec = question.section.toLowerCase();
    final section = sec == 'listening'
        ? '듣기'
        : (sec == 'writing' ? '쓰기' : '읽기');
    final numberText = question.questionNumber > 0
        ? '${question.questionNumber}'
        : '';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1D8F86).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            section,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D8F86),
            ),
          ),
        ),
        if (numberText.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            '문제 $numberText번',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ],
    );
  }
}

class _PassageBox extends StatelessWidget {
  const _PassageBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? AppColors.mint.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.mintDark : AppColors.border,
              ),
            ),
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

class _MockAudioCard extends StatefulWidget {
  const _MockAudioCard({super.key, required this.media});

  final QuestionMedia media;

  @override
  State<_MockAudioCard> createState() => _MockAudioCardState();
}

class _MockAudioCardState extends State<_MockAudioCard> {
  late final AudioPlayer _player;
  bool _playing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    final url = resolveApiMediaUrl(widget.media.url);
    if (url.isNotEmpty) {
      _player.setUrl(url).catchError((error) {
        debugPrint('Mock exam audio load failed: $error');
        return null;
      });
    }
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _playing = state.playing);
    });
    _player.durationStream.listen((duration) {
      if (mounted) setState(() => _duration = duration ?? Duration.zero);
    });
    _player.positionStream.listen((position) {
      if (mounted) setState(() => _position = position);
    });
  }

  @override
  void didUpdateWidget(covariant _MockAudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.url != widget.media.url) {
      _player.setUrl(resolveApiMediaUrl(widget.media.url)).catchError((error) {
        debugPrint('Mock exam audio reload failed: $error');
        return null;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _toggle,
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF2E6BD9),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '듣기 오디오',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2E6BD9)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggle() {
    if (_playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _DocumentPreview extends StatefulWidget {
  const _DocumentPreview({super.key, required this.media, required this.questionNumber});

  final QuestionMedia media;
  final int questionNumber;

  @override
  State<_DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<_DocumentPreview> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadCroppedImage();
  }

  @override
  void didUpdateWidget(covariant _DocumentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.url != widget.media.url ||
        oldWidget.questionNumber != widget.questionNumber) {
      _imageFuture = _loadCroppedImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _InfoCard(
            title: '자료를 불러오지 못했습니다',
            message: '문제에 연결된 그림 자료를 표시할 수 없습니다.',
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            snapshot.data!,
            width: double.infinity,
            height: 260,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  Future<Uint8List> _loadCroppedImage() async {
    final response = await Dio().get<List<int>>(
      resolveApiMediaUrl(widget.media.url),
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    final document = await PdfDocument.openData(
      bytes,
      sourceName: 'mock-exam-${widget.questionNumber}-${widget.media.id}',
    );

    try {
      final pageCount = document.pages.length;
      final crop = _listeningCrop(widget.questionNumber, pageCount);
      final page = document
          .pages[_listeningPdfPage(widget.questionNumber, pageCount) - 1];
      final rendered = await page.render(
        x: crop.$1,
        y: crop.$2,
        width: crop.$3,
        height: crop.$4,
        fullWidth: 1190,
        fullHeight: 1684,
      );
      if (rendered == null) throw StateError('PDF crop rendering failed');

      try {
        final raster = image.Image.fromBytes(
          width: rendered.width,
          height: rendered.height,
          bytes: rendered.pixels.buffer,
          numChannels: 4,
          order: image.ChannelOrder.bgra,
        );
        return Uint8List.fromList(image.encodePng(raster));
      } finally {
        rendered.dispose();
      }
    } finally {
      await document.dispose();
    }
  }

  int _listeningPdfPage(int questionNumber, int pageCount) {
    // 102회 PDF(3페이지: 듣기 통합)는 1번=1p, 2번=2p, 3번=3p.
    if (pageCount <= 3 && questionNumber >= 1 && questionNumber <= 3) {
      return questionNumber;
    }
    // 83회 PDF(듣기+쓰기 통합)는 1~2번이 5페이지, 3번이 6페이지에 있음.
    if (pageCount >= 6 && questionNumber >= 1 && questionNumber <= 3) {
      return questionNumber <= 2 ? 5 : 6;
    }
    if (questionNumber <= 3) return questionNumber;
    if (questionNumber <= 6) return 4;
    return ((questionNumber - 7) ~/ 2) + 5;
  }

  (int, int, int, int) _listeningCrop(int questionNumber, int pageCount) {
    if (pageCount <= 3) {
      switch (questionNumber) {
        case 1:
          return (150, 505, 880, 495);
        case 2:
          return (150, 355, 880, 495);
        case 3:
          return (150, 450, 880, 635);
      }
    }
    if (pageCount >= 6) {
      switch (questionNumber) {
        case 1:
          return (185, 315, 850, 490);
        case 2:
          return (185, 890, 850, 495);
        case 3:
          return (180, 240, 855, 620);
      }
    }
    switch (questionNumber) {
      case 1:
        return (230, 500, 760, 520);
      case 2:
        return (230, 300, 760, 620);
      case 3:
        return (230, 400, 760, 700);
      default:
        return (180, 240, 830, 760);
    }
  }
}

class _QuestionImage extends StatelessWidget {
  const _QuestionImage({super.key, required this.media});

  final QuestionMedia media;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        resolveApiMediaUrl(media.url),
        width: double.infinity,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const _InfoCard(
          title: '이미지 로드 실패',
          message: '문항 이미지를 불러올 수 없습니다.',
        ),
      ),
    );
  }
}

enum _ReviewFilter { all, correct, incorrect, unanswered }

class _ResultCard extends StatefulWidget {
  const _ResultCard({super.key, required this.result, required this.onRestart});

  final MockExamResult result;
  final VoidCallback onRestart;

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  _ReviewFilter _filter = _ReviewFilter.all;

  @override
  Widget build(BuildContext context) {
    final summary = widget.result.summary;
    final reviewItems = _buildReviewItems(widget.result);
    final filteredItems = reviewItems.where((item) {
      return switch (_filter) {
        _ReviewFilter.all => true,
        _ReviewFilter.correct => item.isCorrect,
        _ReviewFilter.incorrect => item.isAnswered && !item.isCorrect,
        _ReviewFilter.unanswered => !item.isAnswered,
      };
    }).toList();
    final unansweredCount = (summary.totalQuestions - summary.answeredCount)
        .clamp(0, summary.totalQuestions);
    final scoreValue = summary.totalQuestions > 0
        ? (summary.scorePercent / 100).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.fact_check_outlined,
                        color: AppColors.mintDark,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '모의고사 결과',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.totalQuestions}문항 중 ${summary.answeredCount}문항 응답',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${summary.scorePercent}%',
                      style: const TextStyle(
                        color: AppColors.mintDark,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: scoreValue,
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.mintDark,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.55,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _SummaryPill(
                      icon: Icons.check_circle_outline,
                      label: '정답',
                      value:
                          '${summary.correctCount}/${summary.totalQuestions}',
                      color: const Color(0xFF198754),
                    ),
                    _SummaryPill(
                      icon: Icons.cancel_outlined,
                      label: '오답',
                      value: '${summary.incorrectCount}',
                      color: const Color(0xFFE14D4D),
                    ),
                    _SummaryPill(
                      icon: Icons.edit_outlined,
                      label: '응답',
                      value: '${summary.answeredCount}',
                      color: const Color(0xFF2E6BD9),
                    ),
                    _SummaryPill(
                      icon: Icons.radio_button_unchecked,
                      label: '미응답',
                      value: '$unansweredCount',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: widget.onRestart,
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('돌아가기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4AC4B2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: AppColors.mintDark),
            const SizedBox(width: 8),
            Text(
              '문제별 리뷰',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChipButton(
                label: '전체 ${reviewItems.length}',
                selected: _filter == _ReviewFilter.all,
                onTap: () => setState(() => _filter = _ReviewFilter.all),
              ),
              _FilterChipButton(
                label: '정답 ${summary.correctCount}',
                selected: _filter == _ReviewFilter.correct,
                onTap: () => setState(() => _filter = _ReviewFilter.correct),
              ),
              _FilterChipButton(
                label: '오답 ${summary.incorrectCount}',
                selected: _filter == _ReviewFilter.incorrect,
                onTap: () => setState(() => _filter = _ReviewFilter.incorrect),
              ),
              _FilterChipButton(
                label: '미응답 $unansweredCount',
                selected: _filter == _ReviewFilter.unanswered,
                onTap: () => setState(() => _filter = _ReviewFilter.unanswered),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filteredItems.isEmpty)
          const _InfoCard(
            title: '리뷰할 문제가 없습니다',
            message: '선택한 필터에 해당하는 문제가 없습니다.',
          )
        else
          for (final item in filteredItems) ...[
            _ReviewQuestionCard(item: item),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  List<_ReviewItem> _buildReviewItems(MockExamResult result) {
    final answerMap = {
      for (final a in result.answers) a.questionId: a,
    };
    return result.questions.map((q) {
      return _ReviewItem(
        question: q,
        answer: answerMap[q.id],
      );
    }).toList();
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.mint.withValues(alpha: 0.18),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        side: BorderSide(
          color: selected
              ? AppColors.mint.withValues(alpha: 0.45)
              : Colors.white,
        ),
        labelStyle: TextStyle(
          color: selected ? AppColors.mintDark : AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem({required this.question, required this.answer});

  final Question? question;
  final MockExamAnswer? answer;

  bool get isAnswered {
    return (answer?.selectedAnswer?.trim().isNotEmpty ?? false) ||
        (answer?.textAnswer?.trim().isNotEmpty ?? false);
  }

  bool get isCorrect {
    if (!isAnswered) return false;
    if (answer?.isCorrect != null) return answer!.isCorrect == 1;
    final selected = answer?.selectedAnswer?.trim();
    final correct = question?.correctAnswer?.trim();
    return selected != null &&
        selected.isNotEmpty &&
        correct != null &&
        correct.isNotEmpty &&
        selected == correct;
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  const _ReviewQuestionCard({super.key, required this.item});

  final _ReviewItem item;

  @override
  Widget build(BuildContext context) {
    final question = item.question;
    final selectedAnswer = item.answer?.selectedAnswer?.trim();
    final correctAnswer = question?.correctAnswer?.trim();
    final selectedOption = _optionText(question, selectedAnswer);
    final correctOption = _optionText(question, correctAnswer);
    final statusColor = item.isCorrect
        ? const Color(0xFF198754)
        : item.isAnswered
            ? const Color(0xFFE14D4D)
            : AppColors.textSecondary;
    final statusIcon = item.isCorrect
        ? Icons.check_circle_outline
        : item.isAnswered
            ? Icons.cancel_outlined
            : Icons.radio_button_unchecked;
    final statusLabel = item.isCorrect
        ? '정답'
        : item.isAnswered
            ? '오답'
            : '미응답';
    final sec = question?.section.toLowerCase() ?? '';
    final secLabel = sec == 'listening'
        ? '듣기'
        : (sec == 'writing' ? '쓰기' : '읽기');
    final title = question == null
        ? '문제'
        : '$secLabel ${question.questionNumber}번';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (question?.passageText?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              _PassageBox(text: question!.passageText!),
            ],
            if (question?.prompt.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                question!.prompt,
                style: const TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _AnswerLine(
              label: '내 답',
              value: selectedOption ?? selectedAnswer ?? '미응답',
              color: item.isAnswered
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            _AnswerLine(
              label: '정답',
              value: correctOption ?? correctAnswer ?? '정답 정보 없음',
              color: const Color(0xFF198754),
            ),
            if (question?.explanation?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '해설',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question!.explanation!,
                      style: const TextStyle(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
            if (question != null) ...[
              const SizedBox(height: 10),
              _QuestionExplanationVideoButton(question: question),
            ],
          ],
        ),
      ),
    );
  }

  String? _optionText(Question? question, String? answer) {
    if (question == null || answer == null || answer.isEmpty) return null;
    for (final option in question.options) {
      if (option.label == answer) {
        return '${option.label}. ${option.text}';
      }
    }
    return null;
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({super.key, required this.title, required this.message});

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
