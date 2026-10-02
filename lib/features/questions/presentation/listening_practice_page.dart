import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_media_url.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/data/listening_practice_set.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';
import 'package:topik_go/features/questions/presentation/question_media_view.dart';
import 'package:topik_go/features/vocabulary/presentation/word_lookup_sheet.dart';

/// Question group representing either a single question (Q1~20) or a pair of
/// questions sharing the same audio dialogue (Q21~50).
class ListeningQuestionGroup {
  ListeningQuestionGroup({
    required this.id,
    required this.questions,
    this.audioUrl,
    this.transcript,
    this.instruction,
  });

  final String id;
  final List<Question> questions;
  final String? audioUrl;
  final String? transcript;
  final String? instruction;

  int get startNumber => questions.first.questionNumber;
  int get endNumber => questions.last.questionNumber;
  String get rangeLabel =>
      startNumber == endNumber ? '$startNumber번' : '$startNumber~$endNumber번';
}

class ListeningPracticePage extends ConsumerStatefulWidget {
  const ListeningPracticePage({super.key, this.level});

  /// Optional level parameter (kept for backwards compatibility; practice displays full 50 questions).
  final int? level;

  @override
  ConsumerState<ListeningPracticePage> createState() =>
      _ListeningPracticePageState();
}

class _ListeningPracticePageState extends ConsumerState<ListeningPracticePage> {
  int _currentGroupIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  _PracticeSummary? _summary;
  String _selectedRoundId = 'topik2-102-listening';
  String _selectedText = '';

  Widget _buildRoundSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _roundChip('topik2-102-listening', '제102회 기출 듣기 (50문항)'),
            const SizedBox(width: 8),
            _roundChip('topik2-83-listening', '제83회 기출 듣기 (50문항)'),
          ],
        ),
      ),
    );
  }

  Widget _roundChip(String id, String label) {
    final isSelected = _selectedRoundId == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.mint.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.mintDark : Colors.black87,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.mintDark : Colors.black12,
      ),
      onSelected: (_) {
        if (_selectedRoundId != id) {
          setState(() {
            _selectedRoundId = id;
            _currentGroupIndex = 0;
            _selectedAnswers.clear();
            _summary = null;
          });
        }
      },
    );
  }

  QuestionMedia? _audioMedia(Question question) {
    final audio = question.media
        .where((m) => m.mediaType.toLowerCase().contains('audio'))
        .firstOrNull;
    if (audio != null && audio.url.isNotEmpty) {
      return audio;
    }
    // Fallback CDN audio
    final round = _selectedRoundId.contains('83') ? 'topik2-83' : 'topik2-102';
    final pad = question.questionNumber.toString().padLeft(2, '0');
    final cdnUrl =
        'https://d361q8q8o0g3r7.cloudfront.net/topik/$round/listening-q$pad.mp3';
    return QuestionMedia(
      id: 'cdn-$round-q$pad',
      mediaType: 'audio',
      url: cdnUrl,
      transcript: question.explanation,
    );
  }

  List<ListeningQuestionGroup> _buildGroups(List<Question> questions) {
    final sorted = List<Question>.from(questions)
      ..sort((a, b) => a.questionNumber.compareTo(b.questionNumber));

    final groups = <ListeningQuestionGroup>[];
    final handled = <String>{};

    for (int i = 0; i < sorted.length; i++) {
      final q = sorted[i];
      if (handled.contains(q.id)) continue;

      final qNum = q.questionNumber;
      int? groupEnd;

      // Official TOPIK II listening pairs: 21-22, 23-24, ... up to 49-50
      if (qNum >= 21 && qNum <= 49 && qNum.isOdd) {
        groupEnd = qNum + 1;
      }

      if (groupEnd != null) {
        final subList = sorted
            .where((x) => x.questionNumber >= qNum && x.questionNumber <= groupEnd!)
            .toList();

        if (subList.isNotEmpty) {
          for (final item in subList) {
            handled.add(item.id);
          }
          final firstQ = subList.first;
          final audio = _audioMedia(firstQ);
          final audioUrl =
              audio == null ? '' : resolveApiMediaUrl(audio.url);
          final transcript = _resolveGroupTranscript(firstQ, audio);

          final instruction = _extractInstruction(firstQ.prompt);
          groups.add(
            ListeningQuestionGroup(
              id: 'group-$qNum-$groupEnd',
              questions: subList,
              audioUrl: audioUrl,
              transcript: transcript,
              instruction: instruction,
            ),
          );
          continue;
        }
      }

      // Single question (Q1 ~ Q20)
      handled.add(q.id);
      final audio = _audioMedia(q);
      final audioUrl = audio == null ? '' : resolveApiMediaUrl(audio.url);
      final transcript = _resolveGroupTranscript(q, audio);

      groups.add(
        ListeningQuestionGroup(
          id: q.id,
          questions: [q],
          audioUrl: audioUrl,
          transcript: transcript,
          instruction: _extractInstruction(q.prompt),
        ),
      );
    }

    return groups;
  }

  String _cleanListeningScript(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    var text = raw.trim();

    if (text.contains('[듣기 대본]')) {
      final parts = text.split('[듣기 대본]');
      if (parts.length > 1) {
        text = parts[1];
      }
    }
    if (text.contains('[정답 해설]')) {
      text = text.split('[정답 해설]')[0];
    }
    if (text.contains('[해설]')) {
      text = text.split('[해설]')[0];
    }

    if (text.trim().startsWith('정답은') || text.trim().startsWith('[정답')) {
      return '';
    }

    text = text
        .replaceAll(RegExp(r'---PAGE \d+---', caseSensitive: false), '')
        .replaceAll(RegExp(r'TOPIK\s*제?\d*회?.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'제\d+회\s*한국어능력시험.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'Test\s+.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'홀수형.*'), '')
        .replaceAll(RegExp(r'짝수형.*'), '')
        .replaceAll(RegExp(r'듣기\s*통합.*'), '')
        .replaceAll(RegExp(r'※\s*\[\s*\d+.*'), '')
        .replaceAll(RegExp(r'^\s*[①②③④\d\s\.\)]+$', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return text;
  }

  String _resolveGroupTranscript(Question firstQ, QuestionMedia? audio) {
    final audioScript = _cleanListeningScript(audio?.transcript);
    if (audioScript.isNotEmpty) return audioScript;

    final passageScript = _cleanListeningScript(firstQ.passageText);
    if (passageScript.isNotEmpty) return passageScript;

    final explanationScript = _cleanListeningScript(firstQ.explanation);
    if (explanationScript.isNotEmpty) return explanationScript;

    return '';
  }

  String? _extractInstruction(String prompt) {
    final match = RegExp(
      r'^(※\s*\[\s*\d+\s*[~～-]\s*\d+\s*\].*?)(?:\n|$)',
    ).firstMatch(prompt.trim());
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }

  String _specificQuestionPrompt(Question q) {
    final lines = q.prompt
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length > 1 && lines.first.startsWith('※')) {
      return lines.sublist(1).join('\n');
    }
    return q.prompt.trim();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final questions = ref.watch(
      practiceQuestionsProvider(
        PracticeSetQuestionsKey(
          section: ListeningPracticeSet.section,
          setId: _selectedRoundId,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text(strings.listeningPractice),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: strings.searchWordOrGrammar,
            onPressed: () => showWordLookupSheet(context),
          ),
        ],
      ),
      body: questions.when(
        data: (page) {
          if (page.items.isEmpty) {
            return Column(
              children: [
                _buildRoundSelector(),
                const Expanded(
                  child: Center(child: Text('듣기 문제를 불러올 수 없습니다.')),
                ),
              ],
            );
          }

          final groups = _buildGroups(page.items);
          final safeGroupIndex =
              _currentGroupIndex.clamp(0, groups.length - 1);
          final currentGroup = groups[safeGroupIndex];

          return Column(
            children: [
              _buildRoundSelector(),
              _ProgressHeader(
                rangeLabel: currentGroup.rangeLabel,
                currentGroupIndex: safeGroupIndex + 1,
                totalGroups: groups.length,
                totalQuestions: page.items.length,
                answeredCount: _selectedAnswers.length,
                groupQuestions: currentGroup.questions,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_summary != null) ...[
                      _SummaryCard(summary: _summary!),
                      const SizedBox(height: 16),
                    ],
                    _ExamPaper(
                      child: SelectionArea(
                        onSelectionChanged: (content) {
                          _selectedText = content?.plainText.trim() ?? '';
                        },
                        contextMenuBuilder: (context, selectableRegionState) {
                          final buttonItems = [
                            if (_selectedText.isNotEmpty) ...[
                              ContextMenuButtonItem(
                                onPressed: () {
                                  final term = _selectedText;
                                  selectableRegionState.hideToolbar();
                                  showWordLookupSheet(
                                    context,
                                    initialWord: term,
                                  );
                                },
                                label: '단어 검색 (+)',
                              ),
                            ],
                            ...selectableRegionState.contextMenuButtonItems,
                          ];
                          return AdaptiveTextSelectionToolbar.buttonItems(
                            anchors: selectableRegionState.contextMenuAnchors,
                            buttonItems: buttonItems,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentGroup.instruction != null &&
                                currentGroup.instruction!.isNotEmpty) ...[
                              _GroupInstructionBanner(
                                text: currentGroup.instruction!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Shared audio player for the group
                            if (currentGroup.audioUrl != null &&
                                currentGroup.audioUrl!.isNotEmpty) ...[
                              _AudioPlayerCard(
                                key: ValueKey(
                                  '${currentGroup.id}|${currentGroup.audioUrl}',
                                ),
                                url: currentGroup.audioUrl!,
                                transcript: currentGroup.transcript,
                              ),
                              const SizedBox(height: 18),
                            ],
                            for (int i = 0;
                                i < currentGroup.questions.length;
                                i++) ...[
                              if (i > 0) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                              ],
                              _buildQuestionItem(
                                currentGroup.questions[i],
                                isMulti: currentGroup.questions.length > 1,
                              ),
                            ],
                            // Shared transcript expandable card
                            if (currentGroup.transcript != null &&
                                currentGroup.transcript!.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _TranscriptCard(
                                text: currentGroup.transcript!.trim(),
                                initiallyExpanded: _summary != null,
                                label: strings.viewScript,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _BottomControls(
                canGoPrevious: safeGroupIndex > 0,
                canGoNext: safeGroupIndex < groups.length - 1,
                onPrevious: () =>
                    setState(() => _currentGroupIndex = safeGroupIndex - 1),
                onNext: () =>
                    setState(() => _currentGroupIndex = safeGroupIndex + 1),
                onSubmit: () => _submitTest(page.items),
                strings: strings,
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
                setId: _selectedRoundId,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionItem(Question question, {required bool isMulti}) {
    final selectedAnswer = _selectedAnswers[question.id];
    final showAnswer = _summary != null || selectedAnswer != null;
    final specificPrompt = _specificQuestionPrompt(question);
    final isPictureQ = isListeningPictureQuestion(question);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2E6BD9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${question.questionNumber}번',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                specificPrompt,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (question.options.isEmpty)
          const Text('이 문제에는 선택지가 없습니다.')
        else if (isPictureQ)
          _buildPictureOptionsGrid(
            question: question,
            selectedAnswer: selectedAnswer,
            showAnswer: showAnswer,
            onSelect: (label) {
              setState(() {
                _selectedAnswers[question.id] = label;
              });
            },
          )
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
          const SizedBox(height: 12),
          _AnswerResultCard(
            selectedAnswer: selectedAnswer,
            correctAnswer: question.correctAnswer,
            explanation: question.explanation,
            options: question.options,
          ),
        ],
      ],
    );
  }

  Widget _buildPictureOptionsGrid({
    required Question question,
    required String? selectedAnswer,
    required bool showAnswer,
    required ValueChanged<String> onSelect,
  }) {
    final markers = ['①', '②', '③', '④'];
    final round = _selectedRoundId.contains('83') ? 'topik2-83' : 'topik2-102';
    final qNum = question.questionNumber;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final opt = question.options[index];
        final isSelected = opt.label == selectedAnswer;
        final isCorrect = opt.label == question.correctAnswer;
        final marker = markers[index.clamp(0, 3)];

        Color borderColor = const Color(0xFFD1D5DB);
        Color bgColor = Colors.white;
        Color badgeBg = const Color(0xFF374151);

        if (showAnswer && isCorrect) {
          borderColor = Colors.green.shade600;
          bgColor = Colors.green.withValues(alpha: 0.08);
          badgeBg = Colors.green.shade700;
        } else if (showAnswer && isSelected) {
          borderColor = Colors.red.shade600;
          bgColor = Colors.red.withValues(alpha: 0.08);
          badgeBg = Colors.red.shade700;
        } else if (isSelected) {
          borderColor = const Color(0xFF2E6BD9);
          bgColor = const Color(0xFFEFF6FF);
          badgeBg = const Color(0xFF2E6BD9);
        }

        // Resolves cropped option image URL
        String rawUrl = opt.text;
        if (!rawUrl.contains('.png')) {
          rawUrl =
              '/test/photos/mock-exams/$round/q0${qNum}_opt${index + 1}.png';
        }
        final imgUrl = resolveApiMediaUrl(rawUrl);

        return Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: selectedAnswer != null ? null : () => onSelect(opt.label),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (showAnswer && isCorrect) ? 2.0 : 1.0,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => Center(
                            child: Text(
                              '$marker 그림',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        marker,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

    final strings = ref.read(appStringsProvider);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.examResult),
        content: _SummaryContent(summary: summary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.confirm),
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
    required this.rangeLabel,
    required this.currentGroupIndex,
    required this.totalGroups,
    required this.totalQuestions,
    required this.answeredCount,
    required this.groupQuestions,
  });

  final String rangeLabel;
  final int currentGroupIndex;
  final int totalGroups;
  final int totalQuestions;
  final int answeredCount;
  final List<Question> groupQuestions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds =
        ref.watch(bookmarkedQuestionIdsProvider).value ?? {};
    final firstQ = groupQuestions.first;
    final isBookmarked = bookmarkedIds.contains(firstQ.id);

    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E6BD9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rangeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E6BD9),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '총 $totalQuestions문항 중 $answeredCount문항 완료',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.orange : Colors.grey,
                    size: 22,
                  ),
                  tooltip: isBookmarked ? '다시 풀 문제에서 해제' : '다시 풀 문제로 저장',
                  onPressed: () async {
                    try {
                      final targetBookmark = !isBookmarked;
                      await ref
                          .read(bookmarkRepositoryProvider)
                          .setQuestionBookmark(
                            questionId: firstQ.id,
                            bookmarked: targetBookmark,
                          );
                      ref.invalidate(bookmarkSummaryProvider);
                      ref.invalidate(bookmarkedQuestionsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              targetBookmark
                                  ? '다시 풀 문제에 저장되었습니다.'
                                  : '다시 풀 문제에서 제외되었습니다.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('다시 풀 문제 저장 실패: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: totalQuestions == 0
                    ? 0
                    : (answeredCount / totalQuestions).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2E6BD9),
                ),
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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

class _GroupInstructionBanner extends StatelessWidget {
  const _GroupInstructionBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.headphones_rounded,
              size: 16, color: Color(0xFF2E6BD9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioPlayerCard extends StatefulWidget {
  const _AudioPlayerCard({
    super.key,
    required this.url,
    this.transcript,
  });

  final String url;
  final String? transcript;

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.url.isEmpty) return;
    try {
      final resolvedUrl = resolveApiMediaUrl(widget.url);
      final duration = await _player.setUrl(resolvedUrl);
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }

      _player.positionStream.listen((pos) {
        if (mounted && !_isDragging) {
          setState(() => _position = pos);
        }
      });

      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing &&
                state.processingState != ProcessingState.completed;
          });
          if (state.processingState == ProcessingState.completed) {
            if (_isLooping) {
              _player.seek(Duration.zero);
              _player.play();
            } else {
              _player.seek(Duration.zero);
              _player.pause();
            }
          }
        }
      });
    } catch (_) {
      // Audio load error handled gracefully
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _seekRelative(int seconds) {
    final target = _position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    _player.seek(clamped);
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E6BD9).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headphones_rounded,
                        size: 14, color: Color(0xFF2E6BD9)),
                    SizedBox(width: 4),
                    Text(
                      '실제 기출 음원',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Color(0xFF2E6BD9),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Speed selector
              PopupMenuButton<double>(
                initialValue: _speed,
                tooltip: '재생 속도',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_speed}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                onSelected: (val) {
                  setState(() => _speed = val);
                  _player.setSpeed(val);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0.8, child: Text('0.8x (느리게)')),
                  const PopupMenuItem(value: 1.0, child: Text('1.0x (보통)')),
                  const PopupMenuItem(value: 1.2, child: Text('1.2x (빠르게)')),
                ],
              ),
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _isLooping ? '반복 재생 켜짐' : '반복 끄기',
                icon: Icon(
                  _isLooping
                      ? Icons.repeat_one_on_rounded
                      : Icons.repeat_rounded,
                  size: 20,
                  color: _isLooping ? const Color(0xFF2E6BD9) : Colors.grey,
                ),
                onPressed: _toggleLoop,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Audio slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: const Color(0xFF2E6BD9),
              inactiveTrackColor: Colors.black12,
              thumbColor: const Color(0xFF1E40AF),
            ),
            child: Slider(
              value: (_isDragging
                      ? _dragValue
                      : _position.inMilliseconds.toDouble())
                  .clamp(
                0.0,
                _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0,
              ),
              min: 0.0,
              max: _duration.inMilliseconds > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1.0,
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
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: '5초 뒤로',
                onPressed: () => _seekRelative(-5),
                icon: const Icon(Icons.replay_5_rounded,
                    size: 22, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  if (_isPlaying) {
                    _player.pause();
                  } else {
                    _player.play();
                  }
                },
                iconSize: 26,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6BD9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '5초 앞으로',
                onPressed: () => _seekRelative(5),
                icon: const Icon(Icons.forward_5_rounded,
                    size: 22, color: Color(0xFF334155)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _TranscriptCard extends StatefulWidget {
  const _TranscriptCard({
    required this.text,
    this.initiallyExpanded = false,
    this.label,
  });

  final String text;
  final bool initiallyExpanded;
  final String? label;

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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined,
                      size: 16, color: Color(0xFF2E6BD9)),
                  const SizedBox(width: 6),
                  Text(
                    widget.label ?? '듣기 대본 보기',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF2E6BD9),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(
                height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(12),
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
      if (line.isEmpty) continue;

      final maleMatch = RegExp(
        r'^(?:\[남자\]|남자\s*[:：]|\[남\]|남\s*[:：]|\(남자\))\s*(.*)$',
      ).firstMatch(line);
      final femaleMatch = RegExp(
        r'^(?:\[여자\]|여자\s*[:：]|\[여\]|여\s*[:：]|\(여자\))\s*(.*)$',
      ).firstMatch(line);

      if (maleMatch != null) {
        widgets.add(_speakerRow(
          speaker: '남자',
          color: const Color(0xFF2E6BD9),
          content: maleMatch.group(1) ?? '',
        ));
      } else if (femaleMatch != null) {
        widgets.add(_speakerRow(
          speaker: '여자',
          color: const Color(0xFFE05268),
          content: femaleMatch.group(1) ?? '',
        ));
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: const TextStyle(
                height: 1.5,
                fontSize: 13.5,
                color: Color(0xFF374151),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _speakerRow({
    required String speaker,
    required Color color,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              speaker,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                height: 1.5,
                fontSize: 13.5,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
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
      borderColor = const Color(0xFF2E6BD9);
      backgroundColor = const Color(0xFFEFF6FF);
    } else {
      borderColor = const Color(0xFFE5E7EB);
      backgroundColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor,
            width: selected || (showAnswer && correct) ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _optionMarker(option.label),
                  style: TextStyle(
                    color: selected && !showAnswer
                        ? const Color(0xFF2E6BD9)
                        : (showAnswer && correct
                            ? Colors.green.shade700
                            : Colors.black87),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      final opt =
          options.where((o) => o.label == correctAnswer).firstOrNull;
      if (opt != null) {
        correctText = opt.text;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? '정답입니다!' : '오답입니다.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: isCorrect
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
              ),
              const Spacer(),
              if (correctAnswer != null)
                Text(
                  '정답: $correctAnswer번',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
            ],
          ),
          if (correctText.isNotEmpty && !correctText.contains('.png')) ...[
            const SizedBox(height: 6),
            Text(
              '정답 선택지: $correctText',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
          if (_cleanExplanation(explanation).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _cleanExplanation(explanation),
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _cleanExplanation(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    var text = raw.trim();
    text = text
        .replaceAll(RegExp(r'---PAGE \d+---', caseSensitive: false), '')
        .replaceAll(RegExp(r'TOPIK\s*제?\d*회?.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'제\d+회\s*한국어능력시험.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'Test\s+.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'홀수형.*'), '')
        .replaceAll(RegExp(r'짝수형.*'), '')
        .replaceAll(RegExp(r'듣기\s*통합.*'), '')
        .replaceAll(RegExp(r'※\s*\[\s*\d+.*'), '')
        .replaceAll(RegExp(r'^\s*[①②③④\d\s\.\)]+$', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return text;
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.strings,
  });

  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canGoPrevious ? onPrevious : null,
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: Text(strings.prev),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canGoNext ? onNext : null,
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: Text(strings.next),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6BD9),
                  ),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: Text(strings.submitExam),
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
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
