import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_media_url.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';
import 'package:topik_go/features/questions/data/listening_practice_set.dart';
import 'package:topik_go/features/questions/data/practice_set_resolution.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';
import 'package:topik_go/features/questions/presentation/question_media_view.dart';

class ListeningPracticePage extends ConsumerStatefulWidget {
  const ListeningPracticePage({super.key, required this.level});

  /// TOPIK II 듣기 급수 (3–6).
  final int? level;

  @override
  ConsumerState<ListeningPracticePage> createState() =>
      _ListeningPracticePageState();
}

class _ListeningPracticePageState extends ConsumerState<ListeningPracticePage> {
  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  _PracticeSummary? _summary;

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final setId = ref
        .watch(questionSetsProvider)
        .maybeWhen(
          data: (sets) => resolvedPracticeSetId(
            sets: sets,
            section: ListeningPracticeSet.section,
            fallbackId: ListeningPracticeSet.id,
            level: level,
          ),
          orElse: () => level == ListeningPracticeSet.level
              ? ListeningPracticeSet.id
              : null,
        );
    final questions = ref.watch(
      practiceQuestionsProvider(
        PracticeSetQuestionsKey(
          section: ListeningPracticeSet.section,
          setId: setId,
          level: level,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text(level == null ? 'TOPIK II 듣기' : '듣기 연습 · $level급'),
      ),
      body: questions.when(
        data: (page) {
          if (page.items.isEmpty) {
            return const Center(child: Text('듣기 문제가 없습니다.'));
          }

          final safeIndex = _currentIndex.clamp(0, page.items.length - 1);
          final question = page.items[safeIndex];
          final selectedAnswer = _selectedAnswers[question.id];
          final showAnswer = _summary != null || selectedAnswer != null;
          final audio = _audioMedia(question);
          final audioUrl = audio == null ? '' : resolveApiMediaUrl(audio.url);
          final rawTranscript = audio?.transcript?.trim();
          final rawPassage = question.passageText?.trim();
          final audioTranscript = (rawTranscript != null && rawTranscript.isNotEmpty)
              ? rawTranscript
              : ((rawPassage != null && rawPassage.isNotEmpty) ? rawPassage : '');
          final imageMedia = question.media.where(isImageMedia).toList();
          final documentMedia = question.media.where(isDocumentMedia).toList();
          // Some listening sets attach the exam paper PDF to a single question,
          // so fall back to the first document available in the loaded set.
          final examPaperDocument = documentMedia.isNotEmpty
              ? documentMedia.first
              : _firstExamPaperDocument(page.items);

          return Column(
            children: [
              _ProgressHeader(
                current: safeIndex + 1,
                total: page.items.length,
                question: question,
                practiceLevel: level,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_summary != null) ...[
                      _SummaryCard(summary: _summary!),
                      const SizedBox(height: 16),
                    ],
                    _ExamPaper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ExamInstruction(question: question),
                          const SizedBox(height: 14),
                          _AudioPlayerCard(
                            key: ValueKey('${question.id}|$audioUrl|$audioTranscript'),
                            url: audioUrl,
                            transcript: audioTranscript,
                          ),
                          const SizedBox(height: 18),
                          if (imageMedia.isNotEmpty) ...[
                            for (final media in imageMedia)
                              QuestionImage(media: media),
                          ],
                          if (examPaperDocument != null &&
                              (isVisualChoiceQuestion(question) ||
                                  isListeningPictureQuestion(question))) ...[
                            ExamPaperDocumentPreview(
                              key: ValueKey(
                                'doc|${question.id}|'
                                '${examPaperDocument.id}|'
                                '${question.questionNumber}',
                              ),
                              media: examPaperDocument,
                              questionNumber: question.questionNumber,
                            ),
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
                          const SizedBox(height: 18),
                          if (question.options.isEmpty)
                            const Text('이 문제에는 선택지가 없습니다.')
                          else
                            ...question.options.map(
                              (option) => _AnswerOptionTile(
                                option: option,
                                selected: option.label == selectedAnswer,
                                showAnswer: showAnswer,
                                correct: option.label == question.correctAnswer,
                                onTap: selectedAnswer != null
                                    ? null
                                    : () => setState(() {
                                        _selectedAnswers[question.id] = option.label;
                                      }),
                              ),
                            ),
                          if (showAnswer) ...[
                            const SizedBox(height: 16),
                            _AnswerResultCard(
                              selectedAnswer: selectedAnswer,
                              correctAnswer: question.correctAnswer,
                              explanation: question.explanation,
                              options: question.options,
                            ),
                            if (audioTranscript.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _TranscriptCard(
                                text: audioTranscript,
                                initiallyExpanded: true,
                              ),
                            ],
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
                onPrevious: () => setState(() => _currentIndex = safeIndex - 1),
                onNext: () => setState(() => _currentIndex = safeIndex + 1),
                onSubmit: () => _submitTest(page.items),
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
                section: ListeningPracticeSet.section,
                setId: readResolvedPracticeSetId(
                  ref,
                  section: ListeningPracticeSet.section,
                  fallbackId: ListeningPracticeSet.id,
                  level: level,
                ),
                level: level,
              ),
            ),
          ),
        ),
      ),
    );
  }

  QuestionMedia? _audioMedia(Question question) {
    if (question.media.isEmpty) return null;
    return question.media.firstWhere(
      (m) => m.mediaType.toLowerCase().contains('audio'),
      orElse: () => question.media.first,
    );
  }

  /// Returns the first exam paper (PDF) media found in the loaded practice set.
  QuestionMedia? _firstExamPaperDocument(List<Question> questions) {
    for (final question in questions) {
      for (final media in question.media) {
        if (isDocumentMedia(media)) return media;
      }
    }
    return null;
  }

  void _submitTest(List<Question> questions) {
    if (_selectedAnswers.isEmpty) {
      _showMessage('먼저 답을 선택해주세요.');
      return;
    }

    final total = questions.length;
    var correct = 0;
    var unanswered = 0;

    for (final question in questions) {
      final selected = _selectedAnswers[question.id];
      if (selected == null) {
        unanswered++;
      }
      if (selected != null &&
          question.correctAnswer != null &&
          selected == question.correctAnswer) {
        correct++;
      }
    }

    final summary = _PracticeSummary(
      total: total,
      correct: correct,
      incorrect: total - correct,
      unanswered: unanswered,
    );

    setState(() {
      _summary = summary;
    });

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시험 결과'),
        content: _SummaryContent(summary: summary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PracticeSummary {
  const _PracticeSummary({
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.unanswered,
  });

  final int total;
  final int correct;
  final int incorrect;
  final int unanswered;
}

class _ProgressHeader extends ConsumerWidget {
  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.question,
    required this.practiceLevel,
  });

  final int current;
  final int total;
  final Question question;
  final int? practiceLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelLabel = question.level == null ? '' : '${question.level}급';
    final bookmarkedIds = ref.watch(bookmarkedQuestionIdsProvider).value ?? {};
    final isBookmarked = bookmarkedIds.contains(question.id);

    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    practiceLevel == null
                      ? 'TOPIK II 듣기'
                      : 'TOPIK II 듣기 · $practiceLevel급',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('$current / $total'),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () async {
                    try {
                      await ref
                          .read(bookmarkRepositoryProvider)
                          .setQuestionBookmark(
                            questionId: question.id,
                            bookmarked: !isBookmarked,
                          );
                      ref.invalidate(bookmarkSummaryProvider);
                      ref.invalidate(bookmarkedQuestionsProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('북마크 저장 실패: $e')),
                        );
                      }
                    }
                  },
                ),
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
              '문항 ${question.questionNumber}${levelLabel.isEmpty ? '' : ' / $levelLabel'}',
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
            '다음을 듣고 알맞은 것을 고르십시오.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _AudioPlayerCard extends StatefulWidget {
  const _AudioPlayerCard({super.key, required this.url, this.transcript});

  final String url;
  final String? transcript;

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  late AudioPlayer _player;
  late FlutterTts _tts;
  bool _isPlaying = false;
  bool _ttsPlaying = false;
  bool _fallbackToTts = false;
  double _playbackSpeed = 1.0;
  bool _isLooping = false;
  bool _isDragging = false;
  double _dragValue = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _tts = FlutterTts();
    _tts.setLanguage('ko-KR');
    _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _ttsPlaying = false);
    });

    final url = widget.url.trim();
    if (url.isEmpty || url.contains('example.com')) {
      _fallbackToTts = true;
    } else {
      _player.setUrl(url).catchError((e) {
        debugPrint('Audio loading error: $e');
        if (mounted) {
          setState(() {
            _fallbackToTts = true;
          });
        }
        return null;
      });
    }

    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
        if (state.processingState == ProcessingState.completed) {
          if (!_isLooping) {
            _player.seek(Duration.zero);
            _player.pause();
          }
        }
      }
    });

    _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });

    _player.positionStream.listen((p) {
      if (mounted && !_isDragging) {
        setState(() => _position = p);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  void _seekRelative(int seconds) {
    if (_fallbackToTts) return;
    final totalMs = _duration.inMilliseconds;
    if (totalMs <= 0) return;
    final targetMs = (_position.inMilliseconds + seconds * 1000).clamp(0, totalMs);
    _player.seek(Duration(milliseconds: targetMs));
  }

  void _toggleLoop() {
    final nextLoop = !_isLooping;
    setState(() => _isLooping = nextLoop);
    _player.setLoopMode(nextLoop ? LoopMode.one : LoopMode.off);
  }

  void _setSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    _player.setSpeed(speed);
    final ttsRate = speed == 0.8 ? 0.35 : (speed == 1.2 ? 0.55 : 0.45);
    _tts.setSpeechRate(ttsRate);
  }

  @override
  Widget build(BuildContext context) {
    final useTts = _fallbackToTts || widget.url.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Title & Mode Chips
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  useTts ? Icons.record_voice_over : Icons.headphones_rounded,
                  color: AppColors.mintDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  useTts ? '음성 지원 (TTS 독해)' : 'TOPIK 듣기 오디오',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Speed selector
              PopupMenuButton<double>(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, size: 14, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text(
                        '${_playbackSpeed}x',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                tooltip: '배속 설정',
                onSelected: _setSpeed,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 0.8, child: Text('0.8x (느리게)')),
                  PopupMenuItem(value: 1.0, child: Text('1.0x (표준)')),
                  PopupMenuItem(value: 1.2, child: Text('1.2x (빠르게)')),
                ],
              ),
              const SizedBox(width: 4),
              // Repeat button
              if (!useTts)
                IconButton(
                  tooltip: _isLooping ? '한 문항 반복 켜짐' : '반복 끄기',
                  icon: Icon(
                    _isLooping ? Icons.repeat_one_on_rounded : Icons.repeat_rounded,
                    size: 20,
                    color: _isLooping ? AppColors.mintDark : Colors.grey,
                  ),
                  onPressed: _toggleLoop,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Center Scrubber (Slider)
          if (!useTts) ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.mint,
                inactiveTrackColor: Colors.black12,
                thumbColor: AppColors.mintDark,
                overlayColor: AppColors.mint.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: (_isDragging ? _dragValue : _position.inMilliseconds.toDouble())
                    .clamp(0.0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                min: 0.0,
                max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                onChanged: (val) {
                  setState(() {
                    _isDragging = true;
                    _dragValue = val;
                  });
                },
                onChangeEnd: (val) {
                  _player.seek(Duration(milliseconds: val.toInt()));
                  setState(() {
                    _isDragging = false;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(_formatDuration(_duration), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          // Playback Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!useTts) ...[
                IconButton(
                  tooltip: '5초 뒤로',
                  onPressed: () => _seekRelative(-5),
                  icon: const Icon(Icons.replay_5_rounded, size: 24, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
              ],
              IconButton.filled(
                onPressed: useTts ? _toggleTts : _togglePlay,
                iconSize: 28,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                icon: Icon(
                  useTts
                      ? (_ttsPlaying ? Icons.stop_rounded : Icons.record_voice_over_rounded)
                      : (_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
              ),
              if (!useTts) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '5초 앞으로',
                  onPressed: () => _seekRelative(5),
                  icon: const Icon(Icons.forward_5_rounded, size: 24, color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> _toggleTts() async {
    if (_ttsPlaying) {
      await _tts.stop();
      setState(() => _ttsPlaying = false);
      return;
    }

    final transcript = widget.transcript;
    if (transcript == null || transcript.isEmpty) return;

    setState(() => _ttsPlaying = true);
    await _tts.speak(_spokenTranscript(transcript));
  }

  String _spokenTranscript(String transcript) {
    return transcript.replaceAll(
      RegExp(r'[\[\(\s]*(여자|남자)[\]\)\s]*[:：]?\s*'),
      '',
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AnswerOptionTile extends StatelessWidget {
  const _AnswerOptionTile({
    required this.option,
    required this.selected,
    required this.showAnswer,
    required this.correct,
    required this.onTap,
  });

  final QuestionOption option;
  final bool selected;
  final bool showAnswer;
  final bool correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color backgroundColor;

    if (showAnswer && correct) {
      borderColor = Colors.green.shade600;
      backgroundColor = Colors.green.withValues(alpha: 0.08);
    } else if (showAnswer && selected) {
      borderColor = Colors.red.shade600;
      backgroundColor = Colors.red.withValues(alpha: 0.08);
    } else if (selected) {
      borderColor = Colors.blue.shade600;
      backgroundColor = Colors.blue.withValues(alpha: 0.08);
    } else {
      borderColor = AppColors.border;
      backgroundColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: borderColor),
        ),
        child: ListTile(
          minLeadingWidth: 28,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: Text(
            _optionMarker(option.label),
            style: TextStyle(
              color: selected && !showAnswer
                  ? Colors.blue.shade700
                  : Colors.black87,
              fontSize: 20,
              fontWeight: selected && !showAnswer
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          title: Text(option.text, style: const TextStyle(height: 1.35)),
          onTap: onTap,
        ),
      ),
    );
  }

  String _optionMarker(String label) {
    switch (int.tryParse(label)) {
      case 1:
        return '①';
      case 2:
        return '②';
      case 3:
        return '③';
      case 4:
        return '④';
      default:
        return label.isEmpty ? '-' : label;
    }
  }
}

class _AnswerResultCard extends StatelessWidget {
  const _AnswerResultCard({
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.explanation,
    this.options = const [],
  });

  final String? selectedAnswer;
  final String? correctAnswer;
  final String? explanation;
  final List<QuestionOption> options;

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedAnswer == correctAnswer;
    String correctText = '';
    if (correctAnswer != null && options.isNotEmpty) {
      final opt = options.where((o) => o.label == correctAnswer).firstOrNull;
      if (opt != null) {
        correctText = opt.text;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? '정답입니다!' : '오답입니다.',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '정답: ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Expanded(
                child: Text(
                  _markerFor(correctAnswer ?? '-') + (correctText.isNotEmpty ? '  $correctText' : ''),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          if (explanation?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 6),
                      Text('해설', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFD97706))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    explanation!,
                    style: const TextStyle(height: 1.5, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _markerFor(String label) {
    switch (int.tryParse(label)) {
      case 1:
        return '①';
      case 2:
        return '②';
      case 3:
        return '③';
      case 4:
        return '④';
      default:
        return label;
    }
  }
}

class _TranscriptCard extends StatefulWidget {
  const _TranscriptCard({
    required this.text,
    this.initiallyExpanded = true,
  });

  final String text;
  final bool initiallyExpanded;

  @override
  State<_TranscriptCard> createState() => _TranscriptCardState();
}

class _TranscriptCardState extends State<_TranscriptCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _TranscriptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 18, color: Color(0xFF2E6BD9)),
                  const SizedBox(width: 8),
                  const Text(
                    '듣기 대본',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF2E6BD9),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _expanded ? '대본 닫기' : '대본 펼치기',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildDialogueLines(widget.text),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDialogueLines(String raw) {
    final lines = raw.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      final maleMatch = RegExp(r'^(?:\[남자\]|남자\s*[:：]|\[남\]|남\s*[:：]|\(남자\))\s*(.*)$').firstMatch(line);
      final femaleMatch = RegExp(r'^(?:\[여자\]|여자\s*[:：]|\[여\]|여\s*[:：]|\(여자\))\s*(.*)$').firstMatch(line);

      if (maleMatch != null) {
        final content = maleMatch.group(1) ?? '';
        widgets.add(_speakerRow(speaker: '남자', color: const Color(0xFF2E6BD9), content: content));
      } else if (femaleMatch != null) {
        final content = femaleMatch.group(1) ?? '';
        widgets.add(_speakerRow(speaker: '여자', color: const Color(0xFFE05268), content: content));
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: const TextStyle(fontSize: 14, height: 1.55, color: Colors.black87),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _speakerRow({required String speaker, required Color color, required String content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              speaker,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

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
                child: OutlinedButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('시험 제출'),
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
  const _SummaryCard({required this.summary});

  final _PracticeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _SummaryContent(summary: summary),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.summary});

  final _PracticeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${summary.correct}/${summary.total} 정답',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _SummaryRow(label: '정답', value: summary.correct),
        _SummaryRow(label: '오답', value: summary.incorrect),
        if (summary.unanswered > 0)
          _SummaryRow(label: '미응답', value: summary.unanswered),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value문항', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
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
