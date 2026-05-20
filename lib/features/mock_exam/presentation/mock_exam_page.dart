import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/core/network/api_media_url.dart';
import 'package:topik_go/features/explanation_video/data/explanation_video_repository.dart';
import 'package:topik_go/features/mock_exam/data/mock_exam_repository.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('모의고사 풀기'),
        backgroundColor: Colors.transparent,
      ),
      body: _GradientBackground(
        child: SafeArea(
          child: catalog.when(
            data: (catalog) {
              if (_result != null) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [_ResultCard(result: _result!, onRestart: _reset)],
                );
              }

              if (_detail != null) {
                return ListView(
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
                      onSubmit: _submit,
                    ),
                  ],
                );
              }

              final tabs = catalog.tabs;
              final currentItems = tabs[_selectedTab] ?? [];

              return RefreshIndicator(
                onRefresh: () => ref.refresh(mockExamCatalogProvider.future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    const _MockHero(),
                    const SizedBox(height: 22),
                    _ActiveSessionBanner(
                      session: catalog.activeSession,
                      loading: _loading,
                      onStart: (setId) => _start(setId),
                      onContinue: () => _loadActive(),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      icon: Icons.tune_outlined,
                      title: '문제 유형',
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
                              selectedColor: AppColors.mint.withValues(
                                alpha: 0.18,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.mintDark
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.mint.withValues(alpha: 0.45)
                                    : Colors.white,
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.03,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: currentItems.length,
                      itemBuilder: (context, index) {
                        return _ExamItemCard(
                          item: currentItems[index],
                          onTap: () => _start(
                            currentItems[index].setId,
                            remainingSeconds:
                                currentItems[index].durationSeconds,
                          ),
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
                child: Text(
                  apiErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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
      case 'reading_actual':
      case 'reading_past':
        return '읽기 기출문제';
      case 'listening_mock':
        return '듣기 모의고사';
      case 'listening_type':
        return '듣기 유형별';
      case 'listening_actual':
      case 'listening_past':
        return '듣기 기출문제';
      default:
        return key
            .split('_')
            .map((s) {
              if (s.isEmpty) return s;
              return s[0].toUpperCase() + s.substring(1);
            })
            .join(' ');
    }
  }

  Future<void> _start(String setId, {int remainingSeconds = 4200}) async {
    await _run(() async {
      final repository = ref.read(mockExamRepositoryProvider);
      MockExamDetail? detail;

      try {
        detail = await repository.createSession(
          setId: setId,
          remainingSeconds: remainingSeconds,
        );
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

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({required this.child});

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

class _MockHero extends StatelessWidget {
  const _MockHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintDark.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.edit_note_outlined,
              color: AppColors.mintDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOPIK II 모의고사',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '실제 시험 흐름에 맞춰 시간을 재고 답안을 저장하며 풀어보세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mintDark),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF2E6BD9),
                ),
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
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (session != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
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
    final isListening = item.section.toLowerCase() == 'listening';
    final icon = isListening
        ? Icons.headphones_outlined
        : Icons.menu_book_outlined;
    final iconColor = isListening
        ? const Color(0xFF2E6BD9)
        : const Color(0xFF1D8F86);
    final iconBg = isListening
        ? const Color(0xFFEAF1FF)
        : const Color(0xFFE8F8F3);

    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const Spacer(),
                  _PriceBadge(
                    label: item.priceLabel ?? 'free',
                    isFree: item.isFree,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              _ExamMeta(
                icon: Icons.assignment_outlined,
                label: '총 ${item.totalQuestions}문항',
              ),
              const SizedBox(height: 5),
              _ExamMeta(
                icon: Icons.timer_outlined,
                label: item.durationLabel ?? '70:00',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamMeta extends StatelessWidget {
  const _ExamMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
                if (audio != null) ...[
                  _MockAudioCard(media: audio),
                  const SizedBox(height: 14),
                ],
                if (images.isNotEmpty) ...[
                  for (final image in images) _QuestionImage(media: image),
                  const SizedBox(height: 14),
                ],
                if (documents.isNotEmpty) ...[
                  for (final document in documents)
                    _DocumentLink(media: document),
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
        FilledButton.icon(
          onPressed: loading ? null : onSubmit,
          icon: const Icon(Icons.check),
          label: const Text('제출하기'),
        ),
      ],
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
}

class _QuestionExplanationVideoButton extends ConsumerWidget {
  const _QuestionExplanationVideoButton({required this.question});

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
  const _QuestionNumberLabel({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final number = question.questionNumber > 0
        ? '${question.questionNumber}'
        : '';
    final section = question.section.toLowerCase() == 'listening' ? '듣기' : '읽기';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            number.isEmpty ? section : '$section $number번',
            style: const TextStyle(
              color: AppColors.mintDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockAudioCard extends StatefulWidget {
  const _MockAudioCard({required this.media});

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

class _DocumentLink extends StatelessWidget {
  const _DocumentLink({required this.media});

  final QuestionMedia media;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () => launchUrl(Uri.parse(resolveApiMediaUrl(media.url))),
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('PDF 원문 열기'),
      ),
    );
  }
}

class _QuestionImage extends StatelessWidget {
  const _QuestionImage({required this.media});

  final QuestionMedia media;

  @override
  Widget build(BuildContext context) {
    final url = resolveApiMediaUrl(media.url);
    if (url.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('이미지를 불러오지 못했습니다.'),
          );
        },
      ),
    );
  }
}

class _PassageBox extends StatelessWidget {
  const _PassageBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(height: 1.5)),
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
