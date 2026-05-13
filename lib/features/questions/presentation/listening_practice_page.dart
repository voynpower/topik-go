import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/data/listening_practice_set.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';

class ListeningPracticePage extends ConsumerStatefulWidget {
  const ListeningPracticePage({super.key});

  @override
  ConsumerState<ListeningPracticePage> createState() =>
      _ListeningPracticePageState();
}

class _ListeningPracticePageState extends ConsumerState<ListeningPracticePage> {
  static const _query = QuestionQuery(
    section: ListeningPracticeSet.section,
    setId: ListeningPracticeSet.id,
    page: 1,
    limit: ListeningPracticeSet.total,
  );

  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  _PracticeSummary? _summary;

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(questionsProvider(_query));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(title: const Text('TOPIK II 듣기')),
      body: questions.when(
        data: (page) {
          if (page.items.isEmpty) {
            return const Center(child: Text('듣기 문제가 없습니다.'));
          }

          final safeIndex = _currentIndex.clamp(0, page.items.length - 1);
          final question = page.items[safeIndex];
          final selectedAnswer = _selectedAnswers[question.id];
          final showAnswer = _summary != null;
          final audio = _audioMedia(question);

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
                          if (audio == null)
                            const Text('이 문제에는 오디오가 없습니다.')
                          else
                            _AudioPlayerCard(
                              key: ValueKey(audio.url),
                              url: _resolveMediaUrl(audio.url),
                            ),
                          const SizedBox(height: 18),
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
                                onTap: showAnswer
                                    ? null
                                    : () => setState(() {
                                        _selectedAnswers[question.id] =
                                            option.label;
                                        _summary = null;
                                      }),
                              ),
                            ),
                          if (showAnswer) ...[
                            const SizedBox(height: 16),
                            _AnswerResultCard(
                              selectedAnswer: selectedAnswer,
                              correctAnswer: question.correctAnswer,
                              explanation: question.explanation,
                            ),
                            if (audio?.transcript?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 12),
                              _TranscriptCard(text: audio!.transcript!),
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
          onRetry: () => ref.invalidate(questionsProvider(_query)),
        ),
      ),
    );
  }

  QuestionMedia? _audioMedia(Question question) {
    for (final media in question.media) {
      if (media.mediaType.toLowerCase() == 'audio' && media.url.isNotEmpty) {
        return media;
      }
    }
    return null;
  }

  String _resolveMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = resolvedApiBaseUrl.endsWith('/')
        ? resolvedApiBaseUrl.substring(0, resolvedApiBaseUrl.length - 1)
        : resolvedApiBaseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
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

    setState(() => _summary = summary);

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
    final levelLabel = question.level == null ? '' : '${question.level}급';

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
                    'TOPIK II 듣기',
                    style: TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
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
            '잘 듣고 알맞은 답을 고르십시오.',
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
  const _AudioPlayerCard({super.key, required this.url});

  final String url;

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  late final AudioPlayer _player;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _load();
  }

  @override
  void didUpdateWidget(covariant _AudioPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(widget.url),
          headers: const {'Accept': 'audio/wav,audio/*;q=0.9,*/*;q=0.8'},
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _AudioShell(
        child: Text(
          '오디오를 불러오지 못했습니다.\n$_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return _AudioShell(
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final playing = state?.playing ?? false;
          final processing = state?.processingState;
          final loading =
              processing == ProcessingState.loading ||
              processing == ProcessingState.buffering;

          return Column(
            children: [
              Row(
                children: [
                  IconButton.filled(
                    onPressed: loading ? null : _togglePlay,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(playing ? Icons.pause : Icons.play_arrow),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '듣기 오디오',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = _player.duration ?? Duration.zero;
                  final max = duration.inMilliseconds.toDouble();
                  final value = position.inMilliseconds
                      .clamp(0, duration.inMilliseconds)
                      .toDouble();

                  return Column(
                    children: [
                      Slider(
                        value: max == 0 ? 0 : value,
                        max: max == 0 ? 1 : max,
                        onChanged: max == 0
                            ? null
                            : (value) => _player.seek(
                                Duration(milliseconds: value.round()),
                              ),
                      ),
                      Row(
                        children: [
                          Text(_formatDuration(position)),
                          const Spacer(),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _togglePlay() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }

    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AudioShell extends StatelessWidget {
  const _AudioShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
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
      borderColor = Colors.black12;
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
  });

  final String? selectedAnswer;
  final String? correctAnswer;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedAnswer == correctAnswer;

    return Card(
      color: isCorrect
          ? Colors.green.withValues(alpha: 0.08)
          : Colors.red.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCorrect ? '정답입니다.' : '오답입니다.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('정답: ${correctAnswer ?? '-'}'),
            if (explanation?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(explanation!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.text});

  final String text;

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
            const Text('듣기 대본', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(height: 1.5)),
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
