import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_media_url.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';
import 'package:topik_go/features/questions/data/reading_practice_set.dart';
import 'package:topik_go/features/vocabulary/presentation/word_lookup_sheet.dart';

/// Question group representing either a single question (Q1~18, 25~41) or a set
/// of questions sharing the same reading passage (19~20, 21~22, 23~24, 42~43, 44~45, 46~47, 48~50).
class ReadingQuestionGroup {
  ReadingQuestionGroup({
    required this.id,
    required this.questions,
    this.sharedPassage,
    this.instruction,
    this.media = const [],
  });

  final String id;
  final List<Question> questions;
  final String? sharedPassage;
  final String? instruction;
  final List<QuestionMedia> media;

  int get startNumber => questions.first.questionNumber;
  int get endNumber => questions.last.questionNumber;
  String get rangeLabel =>
      startNumber == endNumber ? '$startNumber번' : '$startNumber~$endNumber번';
}

class ReadingPracticePage extends ConsumerStatefulWidget {
  const ReadingPracticePage({super.key, this.level});

  /// Optional level parameter (kept for backwards compatibility).
  final int? level;

  @override
  ConsumerState<ReadingPracticePage> createState() =>
      _ReadingPracticePageState();
}

class _ReadingPracticePageState extends ConsumerState<ReadingPracticePage> {
  int _currentGroupIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  _PracticeSummary? _summary;
  String _selectedRoundId = 'topik2-102-reading';
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
            _roundChip('topik2-102-reading', '제102회 기출 읽기 (50문항)'),
            const SizedBox(width: 8),
            _roundChip('topik2-83-reading', '제83회 기출 읽기 (50문항)'),
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

  void _showQuestionGridSheet(
    BuildContext context,
    List<Question> questions,
    List<ReadingQuestionGroup> groups,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final safeGroupIdx = _currentGroupIndex.clamp(
          0,
          groups.isNotEmpty ? groups.length - 1 : 0,
        );
        final currentGroup = groups.isNotEmpty ? groups[safeGroupIdx] : null;

        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      '전체 문항 목록 (1~50번)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '완료: ${_selectedAnswers.length}/${questions.length}',
                      style: const TextStyle(
                        color: AppColors.mintDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    final isCurrent = currentGroup != null &&
                        currentGroup.questions.any((item) => item.id == q.id);
                    final isAnswered = _selectedAnswers.containsKey(q.id);

                    Color bgColor = Colors.white;
                    Color textColor = Colors.black87;
                    Color borderColor = const Color(0xFFE5E7EB);

                    if (isCurrent) {
                      bgColor = AppColors.mint.withValues(alpha: 0.18);
                      borderColor = AppColors.mintDark;
                      textColor = AppColors.mintDark;
                    } else if (isAnswered) {
                      bgColor = const Color(0xFFF0FDF4);
                      borderColor = const Color(0xFF86EFAC);
                      textColor = const Color(0xFF16A34A);
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        final targetGroupIndex = groups.indexWhere(
                          (g) => g.questions.any((item) => item.id == q.id),
                        );
                        if (targetGroupIndex != -1) {
                          setState(() {
                            _currentGroupIndex = targetGroupIndex;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: borderColor,
                            width: isCurrent ? 1.8 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${q.questionNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent || isAnswered
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int? _getGroupEndForReading(int qNum) {
    if (qNum == 19) return 20;
    if (qNum == 21) return 22;
    if (qNum == 23) return 24;
    if (qNum == 42) return 43;
    if (qNum == 44) return 45;
    if (qNum == 46) return 47;
    if (qNum == 48) return 50;
    return null;
  }

  List<ReadingQuestionGroup> _buildGroups(List<Question> questions) {
    final sorted = List<Question>.from(questions)
      ..sort((a, b) => a.questionNumber.compareTo(b.questionNumber));

    final groups = <ReadingQuestionGroup>[];
    final handled = <String>{};

    for (int i = 0; i < sorted.length; i++) {
      final q = sorted[i];
      if (handled.contains(q.id)) continue;

      final qNum = q.questionNumber;
      final groupEnd = _getGroupEndForReading(qNum);

      if (groupEnd != null) {
        final subList = sorted
            .where((x) =>
                x.questionNumber >= qNum && x.questionNumber <= groupEnd)
            .toList();

        if (subList.isNotEmpty) {
          for (final item in subList) {
            handled.add(item.id);
          }
          final firstQ = subList.first;
          final sharedPassage = _resolveGroupPassage(subList, qNum);
          final instruction = _resolveGroupInstruction(firstQ);
          final mediaList = subList
              .expand((item) => item.media)
              .where((m) =>
                  m.mediaType.toLowerCase() == 'image' &&
                  m.url.trim().isNotEmpty)
              .toList();

          groups.add(
            ReadingQuestionGroup(
              id: 'group-reading-$qNum-$groupEnd',
              questions: subList,
              sharedPassage: sharedPassage,
              instruction: instruction,
              media: mediaList,
            ),
          );
          continue;
        }
      }

      // Single question
      handled.add(q.id);
      final passage = _resolveSinglePassage(q);
      final instruction = _resolveGroupInstruction(q);
      final mediaList = q.media
          .where((m) =>
              m.mediaType.toLowerCase() == 'image' && m.url.trim().isNotEmpty)
          .toList();

      groups.add(
        ReadingQuestionGroup(
          id: q.id,
          questions: [q],
          sharedPassage: passage,
          instruction: instruction,
          media: mediaList,
        ),
      );
    }

    return groups;
  }

  String? _resolveGroupPassage(List<Question> questions, int startNumber) {
    for (final q in questions) {
      final p = q.passageText?.trim();
      if (p != null &&
          p.isNotEmpty &&
          !_isQuestionPromptText(p) &&
          !p.contains('저작권 관련 법령') &&
          p.length > 25) {
        return p;
      }
    }

    final canonical = _canonicalPassageForRound(_selectedRoundId, startNumber);
    if (canonical != null) return canonical;

    for (final q in questions) {
      final p = q.passageText?.trim();
      if (p != null &&
          p.isNotEmpty &&
          !_isQuestionPromptText(p) &&
          !p.contains('저작권 관련 법령')) {
        return p;
      }
    }

    return null;
  }

  String? _resolveSinglePassage(Question q) {
    final p = q.passageText?.trim();
    if (q.questionNumber == 41 &&
        (p == null || p.length < 10 || p == '4' || p.trim() == '4.')) {
      return _canonicalPassageForRound(_selectedRoundId, 41);
    }
    if (p != null && p.isNotEmpty && !_isQuestionPromptText(p)) {
      return p;
    }
    return null;
  }

  String? _resolveGroupInstruction(Question firstQ) {
    final extracted = _extractInstructionHeader(firstQ.prompt);
    if (extracted != null && extracted.isNotEmpty) {
      return extracted;
    }
    return _standardInstructionForQuestionNumber(firstQ.questionNumber);
  }

  String _resolveQuestionPrompt(Question q) {
    final rawPrompt = q.prompt.trim();
    final rawPassage = q.passageText?.trim();

    // If passageText is actually question prompt text (e.g. "윗글의 주제로...")
    if (_isQuestionPromptText(rawPassage) &&
        rawPassage != null &&
        rawPassage.isNotEmpty &&
        (rawPrompt.endsWith('번 문항') || rawPrompt.endsWith('번'))) {
      return _cleanPromptText(rawPassage, q.questionNumber);
    }

    final cleaned = _cleanPromptText(rawPrompt, q.questionNumber);
    if (cleaned == '${q.questionNumber}번' ||
        cleaned == '${q.questionNumber}번 문항' ||
        cleaned == '${q.questionNumber}.') {
      final canonical = _canonicalPromptForRound(
        _selectedRoundId,
        q.questionNumber,
      );
      if (canonical != null) return canonical;
    }

    return cleaned;
  }

  List<QuestionOption> _resolveQuestionOptions(Question q) {
    // Problem 5: If Q46 options in data are ['㉠', '㉡', '㉢', '㉣'], replace with actual 4 text choices!
    if (q.questionNumber == 46 &&
        q.options.isNotEmpty &&
        q.options.first.text == '㉠') {
      final canonicalList = _canonicalOptionsForQ46(_selectedRoundId);
      return List<QuestionOption>.generate(
        4,
        (i) => QuestionOption(
          id: '${q.id}-opt-${i + 1}',
          label: '${i + 1}',
          text: canonicalList[i],
        ),
      );
    }
    return q.options;
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      practiceQuestionsProvider(
        PracticeSetQuestionsKey(
          section: ReadingPracticeSet.section,
          setId: _selectedRoundId,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('TOPIK II 읽기 연습'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: '단어/문법 검색',
            onPressed: () => showWordLookupSheet(context),
          ),
        ],
      ),
      body: questionsAsync.when(
        data: (page) {
          if (page.items.isEmpty) {
            return Column(
              children: [
                _buildRoundSelector(),
                const Expanded(
                  child: Center(child: Text('읽기 문제를 불러올 수 없습니다.')),
                ),
              ],
            );
          }

          final questions = page.items;
          final groups = _buildGroups(questions);
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
                totalQuestions: questions.length,
                answeredCount: _selectedAnswers.length,
                groupQuestions: currentGroup.questions,
                onOpenGrid: () =>
                    _showQuestionGridSheet(context, questions, groups),
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
                          _selectedText =
                              content?.plainText.trim() ?? '';
                        },
                        contextMenuBuilder: (context, selectableRegionState) {
                          final buttonItems = [
                            if (_selectedText.isNotEmpty)
                              ContextMenuButtonItem(
                                onPressed: () {
                                  final term = _selectedText;
                                  selectableRegionState.hideToolbar();
                                  showWordLookupSheet(
                                    context,
                                    initialWord: term,
                                  );
                                },
                                label: '단어장 추가 (+)',
                              ),
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
                              const SizedBox(height: 14),
                            ],
                            // Problem 2: When an image exists (e.g. Q9 poster, Q10 graph),
                            // display ONLY the photo/image without duplicate text passage.
                            if (currentGroup.media.isNotEmpty) ...[
                              for (final img in currentGroup.media) ...[
                                _QuestionImage(media: img),
                                const SizedBox(height: 14),
                              ],
                            ] else if (currentGroup.sharedPassage != null &&
                                currentGroup.sharedPassage!.isNotEmpty) ...[
                              _PassageCard(text: currentGroup.sharedPassage!),
                              const SizedBox(height: 16),
                            ],
                            for (int i = 0;
                                i < currentGroup.questions.length;
                                i++) ...[
                              if (i > 0) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                              ],
                              _buildQuestionItem(
                                question: currentGroup.questions[i],
                                prompt: _resolveQuestionPrompt(
                                  currentGroup.questions[i],
                                ),
                                options: _resolveQuestionOptions(
                                  currentGroup.questions[i],
                                ),
                                selectedAnswer:
                                    _selectedAnswers[currentGroup.questions[i].id],
                                showAnswer: _summary != null ||
                                    _selectedAnswers[
                                            currentGroup.questions[i].id] !=
                                        null,
                                isMulti: currentGroup.questions.length > 1,
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
                onOpenGrid: () =>
                    _showQuestionGridSheet(context, questions, groups),
                onSubmit: () => _submitTest(questions),
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
                section: ReadingPracticeSet.section,
                setId: _selectedRoundId,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionItem({
    required Question question,
    required String prompt,
    required List<QuestionOption> options,
    required String? selectedAnswer,
    required bool showAnswer,
    required bool isMulti,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.mintDark,
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
              // Problem 1: Render styled prompt with underline for <u> tags instead of exposing raw HTML!
              child: _buildFormattedText(
                prompt,
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
        if (options.isEmpty)
          const Text('이 문제에는 선택지가 없습니다.')
        else
          ...options.map(
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
            options: options,
          ),
        ],
      ],
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

/// Helper function that renders text containing `<u>...</u>`, `<b>...</b>`, and `<br>`
/// as properly styled text without leaking raw HTML tags.
Widget _buildFormattedText(
  String text, {
  required TextStyle style,
  TextAlign textAlign = TextAlign.start,
}) {
  final tagRegex = RegExp(r'<u>(.*?)</u>|<b>(.*?)</b>|<br\s*/?>');
  final matches = tagRegex.allMatches(text);

  if (matches.isEmpty) {
    return Text(text, style: style, textAlign: textAlign);
  }

  final spans = <InlineSpan>[];
  int lastEnd = 0;

  for (final match in matches) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }

    final raw = match.group(0)!;
    if (match.group(1) != null) {
      final inner = match.group(1)!;
      spans.add(
        TextSpan(
          text: inner,
          style: style.copyWith(
            decoration: TextDecoration.underline,
            decorationThickness: 1.8,
            decorationColor: style.color ?? AppColors.textPrimary,
          ),
        ),
      );
    } else if (match.group(2) != null) {
      final inner = match.group(2)!;
      spans.add(
        TextSpan(
          text: inner,
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
      );
    } else if (raw.startsWith('<br')) {
      spans.add(const TextSpan(text: '\n'));
    }

    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd)));
  }

  return Text.rich(
    TextSpan(children: spans, style: style),
    textAlign: textAlign,
  );
}

bool _isQuestionPromptText(String? text) {
  if (text == null || text.trim().isEmpty) return false;
  final t = text.trim();
  if (t.endsWith('고르십시오.') || t.endsWith('고르십시오')) return true;
  if (t.endsWith('것은?') || t.endsWith('문항')) return true;
  return false;
}

String? _extractInstructionHeader(String prompt) {
  final match = RegExp(
    r'^(※\s*\[\s*\d+\s*[~～-]\s*\d+\s*\].*?)(?:\n|$)',
  ).firstMatch(prompt.trim());
  if (match != null) {
    return match.group(1)?.trim();
  }
  return null;
}

String? _standardInstructionForQuestionNumber(int qNum) {
  if (qNum >= 1 && qNum <= 2) {
    return '※ [1～2] (    )에 들어갈 말로 가장 알맞은 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 3 && qNum <= 4) {
    return '※ [3～4] 밑줄 친 부분과 의미가 가장 비슷한 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 5 && qNum <= 8) {
    return '※ [5～8] 다음은 무엇에 대한 글인지 고르십시오. (각 2점)';
  }
  if (qNum >= 9 && qNum <= 12) {
    return '※ [9～12] 다음 글 또는 그래프의 내용과 같은 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 13 && qNum <= 15) {
    return '※ [13～15] 다음을 순서에 맞게 배열한 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 16 && qNum <= 18) {
    return '※ [16～18] (    )에 들어갈 말로 가장 알맞은 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 19 && qNum <= 20) {
    return '※ [19～20] 다음을 읽고 물음에 답하십시오. (각 2점)';
  }
  if (qNum >= 21 && qNum <= 22) {
    return '※ [21～22] 다음을 읽고 물음에 답하십시오. (각 2점)';
  }
  if (qNum >= 23 && qNum <= 24) {
    return '※ [23～24] 다음을 읽고 물음에 답하십시오. (각 2점)';
  }
  if (qNum >= 25 && qNum <= 27) {
    return '※ [25～27] 다음 신문 기사의 제목을 가장 잘 설명한 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 28 && qNum <= 31) {
    return '※ [28～31] (    )에 들어갈 말로 가장 알맞은 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 32 && qNum <= 34) {
    return '※ [32～34] 다음을 읽고 내용과 같은 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 35 && qNum <= 38) {
    return '※ [35～38] 다음 글의 주제로 가장 알맞은 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 39 && qNum <= 41) {
    return '※ [39～41] 주어진 문장이 들어갈 곳으로 가장 알맞은 것을 고르십시오. (각 2점)';
  }
  if (qNum >= 42 && qNum <= 43) {
    return '※ [42～43] 다음을 읽고 물음에 답하십시오. (각 2점)';
  }
  if (qNum >= 44 && qNum <= 45) {
    return '※ [44～45] 다음을 읽고 물음에 답하십시오. (각 2점)';
  }
  if (qNum >= 46 && qNum <= 47) {
    return '※ [46～47] 다음을 읽고 물음에 답하십시오. (각 2점)';
  }
  if (qNum >= 48 && qNum <= 50) {
    return '※ [48～50] 다음을 읽고 물음에 답하십시오. (각 2점)';
  }
  return null;
}

String _cleanPromptText(String prompt, int qNum) {
  final lines = prompt
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  String cleaned;
  if (lines.length > 1 && lines.first.startsWith('※')) {
    cleaned = lines.sublist(1).join('\n');
  } else {
    cleaned = lines.join('\n');
  }

  // Remove leading numbers like "20. " if already tagged
  cleaned = cleaned.replaceAll(RegExp(r'^\d+\s*[\.\)]\s*'), '');

  if (RegExp(r'^\d+\s*번\s*문항$').hasMatch(cleaned) ||
      RegExp(r'^\d+[.번]?$').hasMatch(cleaned)) {
    return '$qNum번';
  }

  return cleaned;
}

List<String> _canonicalOptionsForQ46(String roundId) {
  if (roundId.contains('83')) {
    return const [
      '과학 정책에 대한 정부의 지나친 개입을 경계하고 있다.',
      '과학 기술 발전을 위해서는 연구가 중요함을 강조하고 있다.',
      '과학 기술 발전이 경제 성장에 미치는 영향력에 감탄하고 있다.',
      '과학 정책 수립 시 우주 과학이 소홀히 다루어질 것을 우려하고 있다.',
    ];
  }
  return const [
    '해저 전선의 구축으로 생길 부작용을 우려하고 있다.',
    '해저 전선의 문제점과 위험성에 대해 역설하고 있다.',
    '해저 전선에 대한 국가적 차원의 대응을 촉구하고 있다.',
    '해저 전선이 세계정세에 미치는 영향을 부정하고 있다.',
  ];
}

String? _canonicalPassageForRound(String roundId, int startNumber) {
  if (roundId.contains('83')) {
    switch (startNumber) {
      case 19:
        return '흥미와 재미 요소를 내세워 홍보하는 마케팅 전략이 주목받고 있다. 이런 마케팅은 소비자의 호기심을 자극해 구매로 이어지게 만든다. 예를 들어 최근 한 화장품 회사에서는 빵 모양의 비누를 출시하여 젊은 층 사이에서 큰 인기를 끌었다. 이처럼 상품 본래의 기능 외에 색다른 즐거움을 주는 마케팅은 브랜드에 대한 친밀감을 높여 준다. (    ) 유행에 민감한 청년 세대를 겨냥한 이색 마케팅 사례는 앞으로도 더욱 늘어날 것으로 보인다.';
      case 21:
        return '소방관은 재난 현장에서 끔찍한 상황을 자주 접하기 때문에 정신 건강에 위험이 따른다. 최근 이러한 문제가 심각해지자 한 소방서에서는 소방관들의 심신 안정을 돕는 치유 프로그램을 운영하기 시작했다. 이 프로그램은 전문가 상담, 명상, 숲 체험 등으로 구성되어 있어 참가자들로부터 큰 호응을 얻고 있다. 실제로 프로그램에 참여한 소방관들은 스트레스 수치가 크게 줄어들었다며 (    ) 미소를 지었다. 소방관들의 건강이 곧 국민의 안전과 직결되는 만큼 이러한 지원 사업이 전국적으로 확대될 필요가 있다.';
      case 23:
        return "며칠 전 창고 선반 위에 올려 둔 가방을 꺼내는데 공책 한 권이 툭 하고 떨어졌다. 나는 '뭐지?' 하고 별 생각 없이 안을 펼쳐 보고는 눈물이 왈칵 나올 뻔했다. 그것은 바로 어렸을 때 돌아가신 아버지의 일기장이었다. 아버지 물건이 아직도 집에 남아 있을 줄은 전혀 생각하지 못했다. 두근거리는 마음으로 거실로 나와 일기장을 펼쳤다. 30년 전 날짜가 적힌 일기장의 누렇게 변한 페이지마다 아버지의 하루하루가 적혀 있었다. 내가 초등학교에 입학한 날, 여행한 날, 혼났던 날•••••. 그때의 추억들이 펼쳐졌다. 아버지는 언제 어디서 무엇을 하셨는지 빼곡히 적어 두셨다. 일기장에 적혀 있는 곳을 인터넷으로 찾아보니 자주 가시던 빵집과 국숫집이 아직도 그대로 있었다. 그곳에 가면 아버지의 흔적을 느낄 수 있을까? 나는 이번 주말에 일기장에 적혀 있는 곳에 한번 찾아가 보려고 한다.";
      case 41:
        return '[보기]\n이처럼 정밀하면서도 실제와 같은 그림은 외부인이 궁궐에 침입할 목적으로 사용할 수 있다.\n\n동궐도는 창덕궁과 창경궁 전체를 그린 조선 시대의 그림이다. ( ㉠ ) 세로 2m, 가로 5m가 넘는 대작으로 건축물은 물론 주변의 산과 궁궐 안 연못, 나무까지 그대로 그려 넣었다. ( ㉡ ) 건물 배치와 건물 사이의 거리도 완벽하게 재현했다. ( ㉢ ) 이러한 이유로 제작자와 제작 연도를 포함하여 그림에 관련된 정보 일체가 왕실 기밀이었을 것으로 추정된다. ( ㉣ )';
      case 42:
        return '어릴 때부터 준은 남다른 감각을 지니고 있었다. 어느 낯선 곳에 가더라도 본능적으로 동서남북의 방위를 정확히 짚어 냈다. 중학생 시절, 준은 가족과 함께 해돋이를 보기 위해 포항으로 여행을 떠났다. 새벽녘 호텔을 나선 부모님은 안내원에게 들은 선착장의 위치가 헷갈려 어두운 길목에서 갈팡질팡하고 계셨다. 이때 준이 한쪽 방향을 가리키며 "저쪽이 동쪽이에요. 해는 저기서 떠요."라고 확신에 차서 말했다. 부모님은 지도나 나침반도 없이 어두운 바닷가에서 방향을 단번에 지목하는 아들의 모습을 보며 <u>고개를 갸웃거리며 어리둥절해하셨다</u>. 그러나 잠시 후 준이 가리킨 수평선 너머로 붉은 태양이 솟아오르기 시작했다.';
      case 44:
        return "서양 역사에서는 15·16세기를 '위대한 발견의 시대'라고 부른다. 콜럼버스처럼 유럽의 많은 탐험가들이 금이나 향신료 등을 얻고자 (    ) 때문이다. 그러나 이 시대에 이루어진 발견의 진정한 의미는 대륙의 발견이 아니라 바다의 발견이었다. 탐험을 통해 지구상의 모든 바다가 하나로 이어져 있다는 인식이 생겼다는 것, 또 이러한 인식을 바탕으로 다양한 해상 항로를 발견한 것이 이 시대의 진정한 소산이라는 것이다. 실제로 탐험가들은 아프리카를 돌아 인도양, 더 나아가 극동까지 가는 바닷길을 열었고 콜럼버스도 대서양을 왕복할 수 있는 경로를 만들었다. 바닷길이 열리자 전 세계가 하나의 지구가 되었고 이로 인해 경제, 기술, 문화뿐만 아니라 생태계의 교환까지 이루어지는 계기가 마련되었다.";
      case 46:
        return '세계는 신에너지, 자동화, 우주여행 등이 주도하는 시대로 급속히 접어들고 있다. 세계 각국은 풍력, 태양광 등 재생 가능한 에너지를 개발하는 회사에 대한 정부 보조금을 늘리고 있고 그에 따라 대체 에너지의 사용 비율도 점차 증가하고 있다. 민간 우주 산업 육성을 위해 인공위성 주파수 사용과 우주선 발사 등에 대한 대대적인 규제 완화를 한 국가도 있다. 그 덕분에 한 민간 기업은 화성 여행이 가능한 호텔급 우주여행선을 제작할 수 있었다. 민간 기업이 과학 기술 개발을 주도하며 성장할 수 있게 된 것은 정부가 지원을 확대하면서도 간섭을 최소화했기 때문이다. 이처럼 과학 기술이 유의미하게 발전하기 위해서는 과학 전문가들이 정책 수립을 주도하고 전문 기업이 그 정책의 수행을 담당할 수 있게 해야 한다. 이때 정부는 모든 과정에 지원은 하되 과도하게 관여하는 일은 없어야 할 것이다.';
      case 48:
        return '많은 사람들은 결혼, 수입 등의 객관적 조건이 행복을 결정하는 요인이라고 생각한다. 그러나 이런 요인들로는 행복의 이유를 10% 정도밖에 설명할 수 없다고 한다. 그렇다면 행복을 결정하는 요인은 무엇일까? 그것은 행복에 대해 가지는 믿음과 태도이다. 행복에 대한 태도는 행복의 유한성과 무한성 중 어느 한쪽을 선택함으로써 결정된다. 이 세상에 존재하는 행복의 (    ) 믿는 사람들은 항상 타인이 행복한 정도를 예의 주시하는 특징이 관찰되었다. 남이 행복하면 내 행복이 줄어든다고 생각하는 사람에게는 타인의 행복이 자신의 행복에 위협적인 요소가 되기 때문이다. 반면 행복의 무한성을 믿는 사람들은 타인의 행복에 그다지 관심을 가지지 않는다. 따라서 행복하려면 행복이 무한한 것이라는 믿음을 가질 필요가 있다. 이러한 생각만으로도 행복감은 증대될 수 있으며 자신이 어떻게 할 때 행복해지는지에 집중할 수 있게 되기 때문이다.';
      default:
        return null;
    }
  }

  // Round 102
  switch (startNumber) {
    case 19:
      return '도시의 도로는 대부분 물이 스며들지 않는 아스팔트로 뒤덮여 있다. 그래서 비가 오면 빗물이 지하로 잘 흘러 들어가지 못해 지하수가 부족해지고 도로가 물에 잠기는 일도 자주 발생한다. 그런데 최근 물이 잘 스며드는 도로 포장재가 개발되었다. 이 포장재에는 미세한 구멍이 많다. 그래서 빗물이 쉽게 통과해 지하수 자원이 보충된다. (    ) 하수구로 몰리는 빗물의 양이 줄어 도로 침수의 위험도 줄어들게 된다.';
    case 21:
      return '인주시의 한 거리가 식당과 카페가 모인 먹거리 골목으로 특화되면서 최근 이곳을 찾는 사람들이 늘고 있다. 그런데 차량 통행을 막고 길 한가운데에서 사진을 찍거나 횡단보도 위에서 삼각대를 세우고 촬영하는 등 일부 방문객의 행동이 (    ) 한다. 차량이 오는 것을 보지 못하고 촬영을 하다 사고가 날 뻔한 위험한 상황이 자주 발생하면서 운전자와 방문객 간에 다투는 일도 잦아지고 있다.';
    case 23:
      return '어릴 적부터 운동과는 거리가 멀었던 나는 서른이 넘어서야 체력을 기르고자 운동을 시작하기로 결심했다. 동네 체육관들을 둘러보다가 성인들을 위한 태권도 반이 있다는 안내문을 보게 되었다. 남들보다 늦은 나이에 흰 띠를 매고 도장에 들어서는 것이 조금 쑥스러웠지만 용기를 내어 등록했다. 시작이 늦은 만큼 더 열심히 하겠다는 각오로 지난 6개월 동안 나는 태권도 수업에 한 번도 빠지지 않았다. 마침내 돌아온 첫 승급 심사 날, 관장님께서 나의 이름을 부르며 파란 띠를 건네주셨다. 허리에 새 띠를 매는 순간 <u>가슴이 벅차오르고 심장이 쿵쾅거리기 시작했다</u>. 내 손으로 무언가를 해냈다는 성취감에 앞으로의 도전이 기대되었다.';
    case 41:
      return '[보기]\n오히려 사대부가 조선의 변화를 주도한 능력주의 원칙의 신봉자들이었음을 역사적 자료를 통해 증명한다.\n\n역사학자 이승원이 『사대부의 시대』라는 책을 출간했다. ( ㉠ ) 사대부는 국가 운영에 중요한 역할을 했던 조선 시대의 양반 계층을 말한다. ( ㉡ ) 이 책은 사대부 계층이 조선의 정치·경제·문화에 미친 영향을 깊이 있게 분석하고 있다. ( ㉢ ) 무엇보다도 저자는 사대부가 폐쇄적인 신분제 사회에서 특권만을 누리려 했다는 통념을 비판한다. ( ㉣ ) 이 책을 통해 독자들은 사대부의 다양한 면모를 볼 수 있다.';
    case 42:
      return '그는 오랫동안 만나 온 여자친구에게 청혼하기 위해 주말여행을 계획했다. 그리고 그녀 몰래 준비한 반지를 가방 안쪽 깊숙한 주머니에 숨겨 두었다. 숙소에 도착해 짐을 풀던 중, 그녀가 휴대폰 충전기를 찾겠다며 그의 가방을 뒤지기 시작했다. 잠시 후, 그녀의 손에 벨벳으로 된 작은 상자 하나가 들려 있었다. "어, 이게 뭐야?" 그녀가 상자를 열어 보려는 순간, 그는 머릿속이 하얘지며 <u>그대로 굳어 버렸다</u>. 근사한 저녁 식사 자리에서 완벽한 타이밍에 멋지게 건네려던 계획이 한순간에 엉망이 될 위기에 처한 것이었다.';
    case 44:
      return '르네상스 시대에 꽃을 피운 해부학은 인체의 내부를 파악할 수 있게 해 의학 분야에 획기적인 발전을 가져왔다. 동시에 미술가들에게 인물의 움직임을 좀 더 자연스럽게 표현할 수 있는 길을 열어 주었다. 당시 연구 열기가 뜨거웠던 해부학 교실에서는 인체의 근육, 뼈, 장기 등의 세세한 구조를 기록할 누군가가 필요했고, 그 역할은 자연스레 미술가가 수행하게 되었다. 이후 미술가들은 근육의 구조나 그 움직임과 관련된 해부학적 지식을 작품에 적용하여 그림 속 인물들을 한층 더 자연스럽게 그려 냈다. 예를 들어 이전의 그림에서는 (    ) 알지 못해 사람의 발이 떠 있는 것처럼 어색하게 그렸다. 그러나 해부학적 지식이 더해진 이후에는 두 발이 땅을 딛고 서 있는 모습을 현실감 있게 그릴 수 있게 되었다.';
    case 46:
      return '전 세계 바다 밑에는 400개가 넘는 해저 전선이 대양과 연안을 따라 설치돼 있다. 나라 간 정보 통신의 99%가 이 해저 전선을 통해 이루어진다. 하지만 한국은 급증하는 정보 전송량에 비해 해저 전선이 턱없이 부족하다. 여기에는 여러 원인이 있다. 우선 서해안의 경우 수심이 얕아 설치가 까다롭고 어업 피해를 우려한 어민들의 반대도 극심하다. 게다가 해서 전선 설치는 첨단 기술과 막대한 자본이 요구되며 주변국과의 협력이 필수이다. 이는 정부의 개입 없이 민간 기업의 힘만으로는 해결하기 어렵다. 따라서 정부는 해저 전선 설치를 위한 법적 • 경제적•외교적 제도를 정비하는 등 해저 전선의 수를 늘리는 적극적인 방안을 마련해야 한다. 디지털 전환이 가속화 되고 데이터 수요가 급증하는 오늘날, 해저 전선을 얼마나 보유하느냐에 따라 세계 통신망의 주역이 결정된다는 것을 명심해야 한다.';
    case 48:
      return '퇴직 급여 제도 도입 후 20년 만에 개편안이 마련되고 있다. 그 배경에는 퇴직금 체불 문제가 있다. 회사가 퇴직금을 은행 같은 사외 기관에 맡기지 않고 자체 관리하다 보니 회사 사정에 따라 퇴직금 체불이 빈번히 발생해 왔다. 한편 퇴직 즉시 퇴직금 수령이 가능한 현행 제도는 근로자의 노후 소득 보장을 어렵게 한다는 문제의식도 개편안 마련의 배경이다. 이번 개편안은 퇴직금을 매달 외부 기관에 맡기는 것을 의무화해 (    ) 줄이고 퇴직금 수령 시기를 55세로 정해 고질적인 노인 빈곤 문제의 해결을 꾀하고 있다. 그러나 이 개편안이 시행될 경우 퇴직금 명목으로 일정 금액을 의무적으로 매달 납입하게 한 조항은 영세 사업장에 부담이 된다. 또 퇴직금을 조기 수령할 수 없게 한 조항은 근로자의 선택권을 침해한다는 반론이 있다. 따라서 이번 개편안의 성공 여부는 기업의 현실적인 부담과 개인의 선택권 침해라는 변수를 두고 어떻게 균형을 잡을 것인지에 달려 있다.';
    default:
      return null;
  }
}

String? _canonicalPromptForRound(String roundId, int qNum) {
  if (qNum == 20) return '윗글의 주제로 가장 알맞은 것을 고르십시오.';
  if (qNum == 22) return '윗글의 내용과 같은 것을 고르십시오.';
  if (qNum == 23) {
    return "밑줄 친 부분에 나타난 '나'의 심정으로 가장 알맞은 것을 고르십시오.";
  }
  if (qNum == 24) return '윗글의 내용과 같은 것을 고르십시오.';
  if (qNum >= 25 && qNum <= 27) {
    return '다음 신문 기사의 제목을 가장 잘 설명한 것을 고르십시오.';
  }
  if (qNum >= 28 && qNum <= 31) {
    return '(    )에 들어갈 말로 가장 알맞은 것을 고르십시오.';
  }
  if (qNum >= 32 && qNum <= 34) {
    return '다음을 읽고 내용과 같은 것을 고르십시오.';
  }
  if (qNum >= 35 && qNum <= 38) {
    return '다음 글의 주제로 가장 알맞은 것을 고르십시오.';
  }
  if (qNum >= 39 && qNum <= 41) {
    return '주어진 문장이 들어갈 곳으로 가장 알맞은 것을 고르십시오.';
  }
  if (qNum == 42) {
    if (roundId.contains('83')) {
      return "밑줄 친 부분에 나타난 '부모님'의 심정으로 가장 알맞은 것을 고르십시오.";
    }
    return "밑줄 친 부분에 나타난 '그'의 심정으로 가장 알맞은 것을 고르십시오.";
  }
  if (qNum == 43) return '윗글의 내용으로 알 수 있는 것을 고르십시오.';
  if (qNum == 44) return '(    )에 들어갈 말로 가장 알맞은 것을 고르십시오.';
  if (qNum == 45) return '윗글의 주제로 가장 알맞은 것을 고르십시오.';
  if (qNum == 46) return '윗글에 나타난 필자의 태도로 가장 알맞은 것을 고르십시오.';
  if (qNum == 47) return '윗글의 내용과 같은 것을 고르십시오.';
  if (qNum == 48) return '윗글을 쓴 목적으로 가장 알맞은 것을 고르십시오.';
  if (qNum == 49) return '(    )에 들어갈 말로 가장 알맞은 것을 고르십시오.';
  if (qNum == 50) return '윗글의 내용과 같은 것을 고르십시오.';
  return null;
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
    required this.onOpenGrid,
  });

  final String rangeLabel;
  final int currentGroupIndex;
  final int totalGroups;
  final int totalQuestions;
  final int answeredCount;
  final List<Question> groupQuestions;
  final VoidCallback onOpenGrid;

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
                    color: AppColors.mint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rangeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.mintDark,
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
                  icon: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.mintDark,
                    size: 21,
                  ),
                  tooltip: '전체 문항 목록',
                  onPressed: onOpenGrid,
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.orange : Colors.grey,
                    size: 22,
                  ),
                  tooltip: '문항 북마크',
                  onPressed: () async {
                    try {
                      final targetBookmark = !isBookmarked;
                      for (final q in groupQuestions) {
                        await ref
                            .read(bookmarkRepositoryProvider)
                            .setQuestionBookmark(
                              questionId: q.id,
                              bookmarked: targetBookmark,
                            );
                      }
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
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: totalGroups == 0
                    ? 0
                    : (currentGroupIndex / totalGroups).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.mintDark),
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
        color: const Color(0xFFF0FDF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.mintDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionImage extends StatelessWidget {
  const _QuestionImage({required this.media});

  final QuestionMedia media;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        resolveApiMediaUrl(media.url),
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: const Text('문항 이미지를 불러올 수 없습니다.'),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 160,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.mintDark,
            ),
          );
        },
      ),
    );
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
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: _highlightedPassage(text),
    );
  }

  Widget _highlightedPassage(String content) {
    // Problem 3 & Q39-41: Render [보기] box cleanly above passage if present
    if (content.startsWith('[보기]')) {
      final parts = content.split('\n\n');
      if (parts.length > 1) {
        final bogi = parts[0]
            .replaceFirst('[보기]\n', '')
            .replaceFirst('[보기]', '')
            .trim();
        final rest = parts.sublist(1).join('\n\n');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.mintDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '<보기>',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _renderSpans(
                    bogi,
                    const TextStyle(
                      height: 1.65,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _renderSpans(
              rest,
              const TextStyle(
                height: 1.7,
                fontSize: 15,
                letterSpacing: -0.2,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        );
      }
    }

    return _renderSpans(
      content,
      const TextStyle(
        height: 1.7,
        fontSize: 15,
        letterSpacing: -0.2,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _renderSpans(String text, TextStyle baseStyle) {
    // Problem 1: Match blanks ( ), ( ㉠ ), or HTML <u>...</u>, <b>...</b>, <br>
    final regex = RegExp(
      r'(\(\s*[㉠㉡㉢㉣]?\s*\)|\(\s{2,}\)|\[\s{2,}\])|<u>(.*?)</u>|<b>(.*?)</b>|<br\s*/?>',
    );
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      final fullMatch = match.group(0)!;
      if (match.group(1) != null) {
        // Blank item
        final matchedBlank = match.group(1)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Text(
                matchedBlank,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // <u>...</u>
        spans.add(
          TextSpan(
            text: match.group(2)!,
            style: baseStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationThickness: 1.8,
              decorationColor: baseStyle.color ?? const Color(0xFF1F2937),
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // <b>...</b>
        spans.add(
          TextSpan(
            text: match.group(3)!,
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else if (fullMatch.startsWith('<br')) {
        spans.add(const TextSpan(text: '\n'));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return Text.rich(
      TextSpan(children: spans, style: baseStyle),
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
                        ? Colors.blue.shade700
                        : (showAnswer && correct
                            ? Colors.green.shade700
                            : Colors.black87),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFormattedText(
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
          if (correctText.isNotEmpty) ...[
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
          if (explanation != null && explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation!.trim(),
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
}

// Problem 6: Do not display question numbers on "이전" and "다음" buttons!
class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenGrid,
    required this.onSubmit,
  });

  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onOpenGrid;
  final VoidCallback onSubmit;

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
                      label: const Text('이전'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: onOpenGrid,
                    icon: const Icon(Icons.grid_view_rounded, size: 18),
                    tooltip: '전체 문항 목록',
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canGoNext ? onNext : null,
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('다음'),
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
                    backgroundColor: AppColors.mintDark,
                  ),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('시험 제출 및 채점'),
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
