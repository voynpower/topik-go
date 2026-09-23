import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
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

  // Single shared audio player for all listening questions
  AudioPlayer? _audioPlayer;
  String? _playingQuestionId;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _isAudioPlaying = false;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _currentIndexSub;
  List<String> _playlistQuestionIds = [];

  final Map<String, GlobalKey> _questionKeys = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, Timer> _answerDebounceTimers = {};

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
    for (final debounce in _answerDebounceTimers.values) {
      debounce.cancel();
    }
    _scrollController.dispose();
    _stopAndDisposeAudio();
    super.dispose();
  }

  void _initAudioPlayer() {
    if (_audioPlayer != null) return;
    final player = AudioPlayer();
    _audioPlayer = player;

    _playerStateSub = player.playerStateStream.listen((state) {
      if (!mounted) return;
      final isPlaying =
          state.playing && state.processingState != ProcessingState.completed;
      setState(() {
        _isAudioPlaying = isPlaying;
      });
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isAudioPlaying = false;
          _playingQuestionId = null;
          _audioPosition = Duration.zero;
          _audioDuration = Duration.zero;
        });
      }
    });

    _currentIndexSub = player.currentIndexStream.listen((index) {
      if (!mounted || index == null) return;
      if (index >= 0 && index < _playlistQuestionIds.length) {
        final currentId = _playlistQuestionIds[index];
        if (_playingQuestionId != currentId) {
          setState(() {
            _playingQuestionId = currentId;
            _audioPosition = Duration.zero;
            _audioDuration = Duration.zero;
          });
          _scrollToQuestion(currentId);
        }
      }
    });

    _positionSub = player.positionStream.listen((pos) {
      if (mounted) setState(() => _audioPosition = pos);
    });

    _durationSub = player.durationStream.listen((dur) {
      if (mounted) setState(() => _audioDuration = dur ?? Duration.zero);
    });
  }

  Future<void> _setupAndStartListeningPlaylist(
    List<Question> questions, {
    int initialIndex = 0,
  }) async {
    _initAudioPlayer();
    final player = _audioPlayer;
    if (player == null) return;

    final listeningQuestions = questions.where((q) {
      if (q.section.toLowerCase() != 'listening') return false;
      final audio = _firstMedia(q.media, 'audio');
      return audio != null && audio.url.trim().isNotEmpty;
    }).toList();

    if (listeningQuestions.isEmpty) return;

    _playlistQuestionIds = listeningQuestions.map((q) => q.id).toList();

    final audioSources = listeningQuestions.map((q) {
      final audio = _firstMedia(q.media, 'audio')!;
      final resolvedUrl = resolveApiMediaUrl(audio.url.trim());
      return AudioSource.uri(
        Uri.parse(resolvedUrl),
        tag: q.id,
      );
    }).toList();

    try {
      final safeIndex = initialIndex.clamp(0, audioSources.length - 1);
      setState(() {
        _playingQuestionId = _playlistQuestionIds[safeIndex];
        _isAudioPlaying = true;
        _audioPosition = Duration.zero;
        _audioDuration = Duration.zero;
      });

      await player.setAudioSources(
        audioSources,
        initialIndex: safeIndex,
        preload: true,
      );
      await player.play();
    } catch (e) {
      debugPrint('Continuous listening playlist playback error: $e');
    }
  }

  Future<void> _toggleAudioForQuestion(String questionId, String url) async {
    _initAudioPlayer();
    final player = _audioPlayer;
    if (player == null) return;

    if (_playlistQuestionIds.isEmpty && _detail != null) {
      await _setupAndStartListeningPlaylist(_detail!.questions, initialIndex: 0);
    }

    final targetIndex = _playlistQuestionIds.indexOf(questionId);

    if (_playingQuestionId == questionId) {
      if (_isAudioPlaying) {
        await player.pause();
      } else {
        await player.play();
      }
    } else if (targetIndex != -1) {
      try {
        setState(() {
          _playingQuestionId = questionId;
          _isAudioPlaying = true;
          _audioPosition = Duration.zero;
          _audioDuration = Duration.zero;
        });
        await player.seek(Duration.zero, index: targetIndex);
        await player.play();
      } catch (e) {
        debugPrint('Seek error for question $questionId: $e');
      }
    } else {
      try {
        setState(() {
          _playingQuestionId = questionId;
          _isAudioPlaying = true;
          _audioPosition = Duration.zero;
          _audioDuration = Duration.zero;
        });
        await player.stop();
        await player.setUrl(resolveApiMediaUrl(url));
        await player.play();
      } catch (e) {
        debugPrint('Fallback audio error for $questionId: $e');
      }
    }
  }

  void _stopAndDisposeAudio() {
    _playerStateSub?.cancel();
    _playerStateSub = null;
    _currentIndexSub?.cancel();
    _currentIndexSub = null;
    _positionSub?.cancel();
    _positionSub = null;
    _durationSub?.cancel();
    _durationSub = null;
    _playlistQuestionIds = [];
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _playingQuestionId = null;
    _isAudioPlaying = false;
    _audioPosition = Duration.zero;
    _audioDuration = Duration.zero;
  }

  void _scrollToQuestion(String questionId) {
    final key = _questionKeys[questionId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
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
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('시험 중단'),
                  content: const Text(
                    '시험을 중단하고 나가시겠습니까?\n진행 상황은 저장되지 않습니다.',
                  ),
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
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    _formatExamDuration(_remainingSeconds),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D8F86),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _ExamPanel(
          detail: _detail!,
          scrollController: _scrollController,
          questionKeys: _questionKeys,
          selectedAnswers: _selectedAnswers,
          loading: _loading,
          playingQuestionId: _playingQuestionId,
          isAudioPlaying: _isAudioPlaying,
          audioPosition: _audioPosition,
          audioDuration: _audioDuration,
          onToggleAudio: _toggleAudioForQuestion,
          onAnswer: _saveAnswer,
          onSubmit: () => _confirmSubmit(context),
          onScrollToQuestion: _scrollToQuestion,
        ),
        bottomNavigationBar: _ExamBottomBar(
          detail: _detail!,
          selectedAnswers: _selectedAnswers,
          remainingSeconds: _remainingSeconds,
          onOpenQuestionGrid: () => _showQuestionGridSheet(context),
          onSubmit: () => _confirmSubmit(context),
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
      _stopAndDisposeAudio();
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

      // Auto-play the continuous listening playlist immediately on exam start
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _detail != null) {
          _setupAndStartListeningPlaylist(detail.questions, initialIndex: 0);
        }
      });
    });
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

    _answerDebounceTimers[questionId]?.cancel();
    _answerDebounceTimers[questionId] =
        Timer(const Duration(milliseconds: 500), () async {
      try {
        await ref.read(mockExamRepositoryProvider).saveAnswer(
              sessionId: detail.session.id,
              questionId: questionId,
              selectedAnswer: answer,
            );
      } catch (e) {
        debugPrint('saveAnswer sync error: $e');
      }
    });
  }

  Future<void> _submit({bool isAutoSubmit = false}) async {
    final detail = _detail;
    if (detail == null) return;

    _stopAndDisposeAudio();

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
        int objectiveTotal = 0;
        for (final q in questions) {
          if (q.section.toLowerCase() != 'writing') {
            objectiveTotal++;
            final sel = _selectedAnswers[q.id];
            if (sel != null &&
                sel.isNotEmpty &&
                q.correctAnswer != null &&
                sel == q.correctAnswer) {
              correctCount++;
            }
          }
        }
        final total = questions.length;
        final answered = _selectedAnswers.length;
        final percent =
            objectiveTotal > 0 ? (correctCount * 100 ~/ objectiveTotal) : 0;
        result = MockExamResult(
          session: detail.session,
          summary: MockExamSummary(
            totalQuestions: total,
            answeredCount: answered,
            correctCount: correctCount,
            incorrectCount: (objectiveTotal - correctCount).clamp(0, total),
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
    _stopAndDisposeAudio();
    setState(() {
      _detail = null;
      _result = null;
      _currentIndex = 0;
      _remainingSeconds = 0;
    });
  }

  void _showQuestionGridSheet(BuildContext context) {
    final detail = _detail;
    if (detail == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            final listeningQuestions = detail.questions
                .where((q) => q.section.toLowerCase() == 'listening')
                .toList();
            final writingQuestions = detail.questions
                .where((q) => q.section.toLowerCase() == 'writing')
                .toList();
            final readingQuestions = detail.questions
                .where((q) => q.section.toLowerCase() == 'reading')
                .toList();

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
                        '완료: ${_selectedAnswers.length}/${detail.questions.length}',
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
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (listeningQuestions.isNotEmpty) ...[
                        _buildSectionGrid(
                          title: '🎧 듣기 (1~50번)',
                          questions: listeningQuestions,
                          onTapQuestion: (q) {
                            Navigator.of(ctx).pop();
                            _scrollToQuestion(q.id);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (writingQuestions.isNotEmpty) ...[
                        _buildSectionGrid(
                          title: '✍️ 쓰기 (51~54번)',
                          questions: writingQuestions,
                          onTapQuestion: (q) {
                            Navigator.of(ctx).pop();
                            _scrollToQuestion(q.id);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (readingQuestions.isNotEmpty) ...[
                        _buildSectionGrid(
                          title: '📖 읽기 (1~50번)',
                          questions: readingQuestions,
                          onTapQuestion: (q) {
                            Navigator.of(ctx).pop();
                            _scrollToQuestion(q.id);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionGrid({
    required String title,
    required List<Question> questions,
    required void Function(Question question) onTapQuestion,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.25,
          ),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            final ans = _selectedAnswers[q.id];
            final isAnswered = ans != null && ans.trim().isNotEmpty;

            return InkWell(
              onTap: () => onTapQuestion(q),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isAnswered
                      ? const Color(0xFFE8F8F5)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAnswered
                        ? const Color(0xFF4AC4B2)
                        : const Color(0xFFE5E7EB),
                    width: isAnswered ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${q.questionNumber}',
                  style: TextStyle(
                    color: isAnswered
                        ? const Color(0xFF1D8F86)
                        : const Color(0xFF4B5563),
                    fontWeight:
                        isAnswered ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
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

class _SectionHeaderBanner extends StatelessWidget {
  const _SectionHeaderBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
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

class _WritingShortAnswerInput extends StatefulWidget {
  const _WritingShortAnswerInput({
    super.key,
    required this.questionId,
    this.initialAnswer,
    required this.onAnswer,
  });

  final String questionId;
  final String? initialAnswer;
  final void Function(String questionId, String answer) onAnswer;

  @override
  State<_WritingShortAnswerInput> createState() =>
      _WritingShortAnswerInputState();
}

class _WritingShortAnswerInputState extends State<_WritingShortAnswerInput> {
  late TextEditingController _controllerA;
  late TextEditingController _controllerB;

  @override
  void initState() {
    super.initState();
    String a = '';
    String b = '';
    if (widget.initialAnswer != null) {
      final parts = widget.initialAnswer!.split('/');
      for (final p in parts) {
        final trimmed = p.trim();
        if (trimmed.startsWith('㉠')) {
          a = trimmed.replaceFirst('㉠', '').trim();
        } else if (trimmed.startsWith('㉡')) {
          b = trimmed.replaceFirst('㉡', '').trim();
        } else if (a.isEmpty) {
          a = trimmed;
        } else {
          b = trimmed;
        }
      }
    }
    _controllerA = TextEditingController(text: a);
    _controllerB = TextEditingController(text: b);
  }

  @override
  void didUpdateWidget(covariant _WritingShortAnswerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAnswer != widget.initialAnswer &&
        widget.initialAnswer == null) {
      _controllerA.clear();
      _controllerB.clear();
    }
  }

  @override
  void dispose() {
    _controllerA.dispose();
    _controllerB.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final a = _controllerA.text.trim();
    final b = _controllerB.text.trim();
    if (a.isEmpty && b.isEmpty) {
      widget.onAnswer(widget.questionId, '');
    } else {
      widget.onAnswer(widget.questionId, '㉠ $a / ㉡ $b');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '답안 작성',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4AC4B2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '㉠',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D8F86),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controllerA,
                  onChanged: (_) => _notifyChange(),
                  decoration: const InputDecoration(
                    hintText: '㉠에 들어갈 알맞은 말을 쓰시오',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4AC4B2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '㉡',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D8F86),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controllerB,
                  onChanged: (_) => _notifyChange(),
                  decoration: const InputDecoration(
                    hintText: '㉡에 들어갈 알맞은 말을 쓰시오',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WritingEssayInput extends StatefulWidget {
  const _WritingEssayInput({
    super.key,
    required this.questionId,
    required this.targetMin,
    required this.targetMax,
    required this.hintText,
    this.initialAnswer,
    required this.onAnswer,
  });

  final String questionId;
  final int targetMin;
  final int targetMax;
  final String hintText;
  final String? initialAnswer;
  final void Function(String questionId, String answer) onAnswer;

  @override
  State<_WritingEssayInput> createState() => _WritingEssayInputState();
}

class _WritingEssayInputState extends State<_WritingEssayInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAnswer ?? '');
  }

  @override
  void didUpdateWidget(covariant _WritingEssayInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAnswer != widget.initialAnswer &&
        widget.initialAnswer == null) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _controller.text.length;
    Color countColor = const Color(0xFF6B7280);
    if (count > 0 && count < widget.targetMin) {
      countColor = Colors.orange;
    } else if (count >= widget.targetMin && count <= widget.targetMax) {
      countColor = const Color(0xFF198754);
    } else if (count > widget.targetMax) {
      countColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '원고지 서술 작성',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: countColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count / ${widget.targetMax}자 (기준: ${widget.targetMin}~${widget.targetMax}자)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: countColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          onChanged: (text) {
            setState(() {});
            widget.onAnswer(widget.questionId, text);
          },
          maxLines: widget.targetMax > 400 ? 12 : 7,
          minLines: widget.targetMax > 400 ? 8 : 5,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle:
                const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF4AC4B2), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          style: const TextStyle(height: 1.5, fontSize: 14),
        ),
      ],
    );
  }
}

class _ExamBottomBar extends StatelessWidget {
  const _ExamBottomBar({
    required this.detail,
    required this.selectedAnswers,
    required this.remainingSeconds,
    required this.onOpenQuestionGrid,
    required this.onSubmit,
  });

  final MockExamDetail detail;
  final Map<String, String> selectedAnswers;
  final int remainingSeconds;
  final VoidCallback onOpenQuestionGrid;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final total = detail.questions.length;
    final answered = selectedAnswers.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onOpenQuestionGrid,
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: Text('$answered / $total 문항'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                '시험 제출하기',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4AC4B2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamPanel extends StatelessWidget {
  const _ExamPanel({
    super.key,
    required this.detail,
    required this.scrollController,
    required this.questionKeys,
    required this.selectedAnswers,
    required this.loading,
    required this.playingQuestionId,
    required this.isAudioPlaying,
    required this.audioPosition,
    required this.audioDuration,
    required this.onToggleAudio,
    required this.onAnswer,
    required this.onSubmit,
    required this.onScrollToQuestion,
  });

  final MockExamDetail detail;
  final ScrollController scrollController;
  final Map<String, GlobalKey> questionKeys;
  final Map<String, String> selectedAnswers;
  final bool loading;
  final String? playingQuestionId;
  final bool isAudioPlaying;
  final Duration audioPosition;
  final Duration audioDuration;
  final void Function(String questionId, String audioUrl) onToggleAudio;
  final void Function(String questionId, String answer) onAnswer;
  final VoidCallback onSubmit;
  final void Function(String questionId) onScrollToQuestion;

  @override
  Widget build(BuildContext context) {
    final questions = detail.questions;
    if (questions.isEmpty) {
      return const _InfoCard(title: '문제가 없습니다', message: '이 세트에 문제가 없습니다.');
    }

    final listening = questions
        .where((q) => q.section.toLowerCase() == 'listening')
        .toList();
    final writing = questions
        .where((q) => q.section.toLowerCase() == 'writing')
        .toList();
    final reading = questions
        .where((q) => q.section.toLowerCase() == 'reading')
        .toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        if (listening.isNotEmpty) ...[
          const _SectionHeaderBanner(
            title: '제1교시 · 듣기 영역 (1~50번)',
            subtitle: '문제를 잘 듣고 질문에 맞는 답을 고르십시오. (각 2점)',
            icon: Icons.headphones_rounded,
            badgeColor: Color(0xFF2E6BD9),
          ),
          for (final q in listening) ...[
            _buildListeningQuestionCard(context, q),
            const SizedBox(height: 14),
          ],
        ],
        if (writing.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionHeaderBanner(
            title: '제1교시 · 쓰기 영역 (51~54번)',
            subtitle: '문제를 읽고 질문에 맞는 글을 작성하십시오. (총 100점)',
            icon: Icons.edit_note_rounded,
            badgeColor: Color(0xFF6366F1),
          ),
          for (final q in writing) ...[
            _buildWritingQuestionCard(context, q),
            const SizedBox(height: 14),
          ],
        ],
        if (reading.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionHeaderBanner(
            title: '제2교시 · 읽기 영역 (1~50번)',
            subtitle: '다음 글을 읽고 알맞은 것을 고르십시오. (각 2점)',
            icon: Icons.menu_book_rounded,
            badgeColor: Color(0xFF0D9488),
          ),
          for (final q in reading) ...[
            _buildReadingQuestionCard(context, q),
            const SizedBox(height: 14),
          ],
        ],
        const SizedBox(height: 24),
        _buildCompletionSummaryCard(context),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildListeningQuestionCard(BuildContext context, Question question) {
    final key = questionKeys.putIfAbsent(question.id, () => GlobalKey());
    final audio = _firstMedia(question.media, 'audio');
    final images = question.media.where(_isImageMedia).toList();
    final selectedAnswer = selectedAnswers[question.id];

    return Card(
      key: key,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selectedAnswer != null
              ? const Color(0xFF4AC4B2).withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuestionNumberLabel(question: question),
            const SizedBox(height: 12),
            if (audio != null && audio.url.isNotEmpty) ...[
              _MockSharedAudioBar(
                questionId: question.id,
                audioUrl: audio.url,
                questionNumber: question.questionNumber,
                isPlaying:
                    isAudioPlaying && playingQuestionId == question.id,
                position: playingQuestionId == question.id
                    ? audioPosition
                    : Duration.zero,
                duration: playingQuestionId == question.id
                    ? audioDuration
                    : Duration.zero,
                onToggle: onToggleAudio,
              ),
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
              const SizedBox(height: 14),
            ],
            if (images.isNotEmpty) ...[
              for (final image in images) ...[
                _QuestionImage(media: image),
                const SizedBox(height: 14),
              ],
            ],
            for (final option in question.options)
              _OptionTile(
                option: option,
                selected: selectedAnswer == option.label,
                enabled: !loading && option.label.isNotEmpty,
                onTap: () => onAnswer(question.id, option.label),
              ),
            const SizedBox(height: 4),
            _QuestionExplanationVideoButton(question: question),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingQuestionCard(BuildContext context, Question question) {
    final key = questionKeys.putIfAbsent(question.id, () => GlobalKey());
    final images = question.media.where(_isImageMedia).toList();
    final currentAnswer = selectedAnswers[question.id];
    final isAnswered =
        currentAnswer != null && currentAnswer.trim().isNotEmpty;

    return Card(
      key: key,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAnswered
              ? const Color(0xFF6366F1).withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuestionNumberLabel(question: question),
            const SizedBox(height: 12),
            if (question.prompt.trim().isNotEmpty) ...[
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
            ],
            if (images.isNotEmpty) ...[
              for (final image in images) ...[
                _QuestionImage(media: image),
                const SizedBox(height: 14),
              ],
            ],
            if (question.passageText?.trim().isNotEmpty ?? false) ...[
              _PassageBox(text: question.passageText!.trim()),
              const SizedBox(height: 16),
            ],
            if (question.questionNumber <= 52)
              _WritingShortAnswerInput(
                questionId: question.id,
                initialAnswer: currentAnswer,
                onAnswer: onAnswer,
              )
            else if (question.questionNumber == 53)
              _WritingEssayInput(
                questionId: question.id,
                targetMin: 200,
                targetMax: 300,
                hintText: '200~300자로 작성하십시오. (단, 글의 제목은 쓰지 마시오)',
                initialAnswer: currentAnswer,
                onAnswer: onAnswer,
              )
            else
              _WritingEssayInput(
                questionId: question.id,
                targetMin: 600,
                targetMax: 700,
                hintText: '600~700자로 글을 쓰십시오.',
                initialAnswer: currentAnswer,
                onAnswer: onAnswer,
              ),
            const SizedBox(height: 4),
            _QuestionExplanationVideoButton(question: question),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingQuestionCard(BuildContext context, Question question) {
    final key = questionKeys.putIfAbsent(question.id, () => GlobalKey());
    final images = question.media.where(_isImageMedia).toList();
    final selectedAnswer = selectedAnswers[question.id];

    return Card(
      key: key,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selectedAnswer != null
              ? const Color(0xFF0D9488).withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuestionNumberLabel(question: question),
            const SizedBox(height: 12),
            if (question.prompt.trim().isNotEmpty) ...[
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
            ],
            if (images.isNotEmpty) ...[
              for (final image in images) ...[
                _QuestionImage(media: image),
                const SizedBox(height: 14),
              ],
            ],
            if (question.passageText?.trim().isNotEmpty ?? false) ...[
              _PassageBox(text: question.passageText!.trim()),
              const SizedBox(height: 14),
            ],
            for (final option in question.options)
              _OptionTile(
                option: option,
                selected: selectedAnswer == option.label,
                enabled: !loading && option.label.isNotEmpty,
                onTap: () => onAnswer(question.id, option.label),
              ),
            const SizedBox(height: 4),
            _QuestionExplanationVideoButton(question: question),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionSummaryCard(BuildContext context) {
    final total = detail.questions.length;
    final answered = selectedAnswers.length;
    final remaining = total - answered;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_turned_in_rounded,
            size: 40,
            color: Color(0xFF4AC4B2),
          ),
          const SizedBox(height: 12),
          const Text(
            '시험을 모두 확인하셨습니까?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining > 0
                ? '총 $total문항 중 $answered문항 완료 ($remaining문항 미응답)'
                : '총 $total문항 모두 완료되었습니다!',
            style: TextStyle(
              fontSize: 14,
              color: remaining > 0
                  ? Colors.orange[800]
                  : const Color(0xFF198754),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: const Icon(Icons.check),
              label: const Text('시험 제출하기'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4AC4B2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

class _MockSharedAudioBar extends StatelessWidget {
  const _MockSharedAudioBar({
    required this.questionId,
    required this.audioUrl,
    required this.questionNumber,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
  });

  final String questionId;
  final String audioUrl;
  final int questionNumber;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final void Function(String questionId, String audioUrl) onToggle;

  @override
  Widget build(BuildContext context) {
    final hasDuration = duration.inMilliseconds > 0;
    final progress = hasDuration
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPlaying ? const Color(0xFFE8F2FF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying
              ? const Color(0xFF2E6BD9).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: () => onToggle(questionId, audioUrl),
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isPlaying
                  ? const Color(0xFF2E6BD9)
                  : const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '문제 $questionNumber번 듣기 음원',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isPlaying
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF374151),
                      ),
                    ),
                    if (isPlaying && hasDuration)
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E6BD9),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isPlaying ? progress : 0.0,
                    minHeight: 5,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation(
                      isPlaying
                          ? const Color(0xFF2E6BD9)
                          : const Color(0xFFD1D5DB),
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
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _QuestionImage extends StatelessWidget {
  const _QuestionImage({super.key, required this.media});

  final QuestionMedia media;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        resolveApiMediaUrl(media.url),
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const _InfoCard(
          title: '이미지 로드 실패',
          message: '문항 이미지를 불러올 수 없습니다.',
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF4AC4B2),
            ),
          );
        },
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
    if (question?.section.toLowerCase() == 'writing') {
      return isAnswered;
    }
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
    final isWriting = question?.section.toLowerCase() == 'writing';
    final selectedAnswer = item.answer?.selectedAnswer?.trim();
    final correctAnswer = question?.correctAnswer?.trim();
    final selectedOption = _optionText(question, selectedAnswer);
    final correctOption = _optionText(question, correctAnswer);
    final statusColor = isWriting
        ? const Color(0xFF6366F1)
        : (item.isCorrect
            ? const Color(0xFF198754)
            : item.isAnswered
                ? const Color(0xFFE14D4D)
                : AppColors.textSecondary);
    final statusIcon = isWriting
        ? Icons.edit_note_rounded
        : (item.isCorrect
            ? Icons.check_circle_outline
            : item.isAnswered
                ? Icons.cancel_outlined
                : Icons.radio_button_unchecked);
    final statusLabel = isWriting
        ? (item.isAnswered ? '서술형 작성' : '서술형 미응답')
        : (item.isCorrect
            ? '정답'
            : item.isAnswered
                ? '오답'
                : '미응답');
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
            for (final img in (question?.media ?? const <QuestionMedia>[]).where((m) {
              final type = m.mediaType.toLowerCase();
              final url = m.url.toLowerCase();
              return type.contains('image') ||
                  url.endsWith('.png') ||
                  url.endsWith('.jpg') ||
                  url.endsWith('.jpeg') ||
                  url.endsWith('.webp');
            })) ...[
              const SizedBox(height: 10),
              _QuestionImage(media: img),
            ],
            if (question?.section.toLowerCase() != 'listening' &&
                (question?.passageText?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              _PassageBox(text: question!.passageText!.trim()),
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
              label: isWriting ? '모범답안' : '정답',
              value: correctOption ??
                  correctAnswer ??
                  (isWriting ? '모범답안 정보' : '정답 정보 없음'),
              color: isWriting
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF198754),
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
