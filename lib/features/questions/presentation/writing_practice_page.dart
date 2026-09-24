import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_media_url.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/practice/data/practice_session_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';
import 'package:topik_go/features/questions/data/writing_practice_set.dart';
import 'package:topik_go/features/questions/presentation/question_media_view.dart';

class WritingPracticePage extends ConsumerStatefulWidget {
  const WritingPracticePage({super.key});

  @override
  ConsumerState<WritingPracticePage> createState() =>
      _WritingPracticePageState();
}

class _WritingPracticePageState extends ConsumerState<WritingPracticePage> {
  int _currentIndex = 0;
  String _selectedRoundId = 'topik2-102-writing';
  bool _submitted = false;
  bool _saving = false;
  String? _sessionId;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, TextEditingController> _controllersA = {};
  final Map<String, TextEditingController> _controllersB = {};
  final Map<String, Set<int>> _checkedConditions = {};
  final DateTime _startedAt = DateTime.now();

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final c in _controllersA.values) {
      c.dispose();
    }
    for (final c in _controllersB.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch backend questions for the selected writing round
    final questionsAsync = ref.watch(
      practiceQuestionsProvider(
        PracticeSetQuestionsKey(
          section: WritingPracticeSet.section,
          setId: _selectedRoundId,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('TOPIK II 쓰기 집중 훈련'),
        elevation: 0,
      ),
      body: questionsAsync.when(
        data: (page) {
          final items = page.items.isNotEmpty
              ? page.items
              : _fallbackQuestionsForRound(_selectedRoundId);
          return _buildContent(items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          final fallbackItems = _fallbackQuestionsForRound(_selectedRoundId);
          return _buildContent(fallbackItems);
        },
      ),
    );
  }

  Widget _buildContent(List<Question> items) {
    final safeIndex = _currentIndex.clamp(0, items.length - 1);
    final question = items[safeIndex];
    final controller = _controllerFor(question);

    return Column(
      children: [
        _RoundAndTypeSelector(
          selectedRoundId: _selectedRoundId,
          onRoundChanged: (roundId) {
            setState(() {
              _selectedRoundId = roundId;
              _currentIndex = 0;
              _submitted = false;
            });
          },
          currentIndex: safeIndex,
          items: items,
          onSelectQuestion: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        _ProgressHeader(
          current: safeIndex + 1,
          total: items.length,
          question: question,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              if (_submitted) ...[
                _SummaryCard(
                  answered: _answeredCount(items),
                  total: items.length,
                ),
                const SizedBox(height: 14),
              ],
              _ExamPaper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExamInstruction(question: question),
                    const SizedBox(height: 12),
                    if (question.passageText?.isNotEmpty ?? false) ...[
                      _PassageCard(
                        text: question.passageText!,
                        isShortCompletion: question.questionNumber <= 52,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Show graph image for Q53 if present
                    if (question.questionNumber == 53) ...[
                      _GraphImagePreview(question: question),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      question.prompt,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildDedicatedEditor(question, controller),
                    if (_submitted) ...[
                      const SizedBox(height: 20),
                      _ReviewCard(
                        question: question,
                        textAnswer: controller.text,
                        controllerA: _controllersA[question.id],
                        controllerB: _controllersB[question.id],
                        explanation: question.explanation,
                        sampleAnswer: question.correctAnswer,
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
          canGoNext: safeIndex < items.length - 1,
          saving: _saving,
          submitted: _submitted,
          onPrevious: () => setState(() => _currentIndex = safeIndex - 1),
          onNext: () => setState(() => _currentIndex = safeIndex + 1),
          onSubmit: () => _submitWriting(items),
          onEditAgain: () => setState(() => _submitted = false),
        ),
      ],
    );
  }

  Widget _buildDedicatedEditor(
    Question question,
    TextEditingController controller,
  ) {
    if (question.questionNumber <= 52 ||
        question.questionType == 'writing_short_completion') {
      final ctrlA = _controllerAFor(question);
      final ctrlB = _controllerBFor(question);
      return _ShortCompletionEditor(
        questionNumber: question.questionNumber,
        controllerA: ctrlA,
        controllerB: ctrlB,
        onChanged: () {
          final valA = ctrlA.text.trim();
          final valB = ctrlB.text.trim();
          controller.text = '㉠ $valA / ㉡ $valB';
          setState(() {});
        },
        enabled: !_saving,
      );
    } else if (question.questionNumber == 53 ||
        question.questionType == 'writing_graph_description') {
      return _GraphDescriptionEditor(
        controller: controller,
        enabled: !_saving,
      );
    } else {
      // 54번 논술문
      final checkedSet =
          _checkedConditions.putIfAbsent(question.id, () => <int>{});
      return _EssayEditor(
        controller: controller,
        checkedConditions: checkedSet,
        onConditionToggled: (index) {
          setState(() {
            if (checkedSet.contains(index)) {
              checkedSet.remove(index);
            } else {
              checkedSet.add(index);
            }
          });
        },
        enabled: !_saving,
      );
    }
  }

  TextEditingController _controllerFor(Question question) {
    return _controllers.putIfAbsent(question.id, TextEditingController.new);
  }

  TextEditingController _controllerAFor(Question question) {
    return _controllersA.putIfAbsent(question.id, TextEditingController.new);
  }

  TextEditingController _controllerBFor(Question question) {
    return _controllersB.putIfAbsent(question.id, TextEditingController.new);
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
      _showMessage('쓰기 답안이 저장되었습니다. 모범 답안과 비교해보세요!');
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
      questionSetId: _selectedRoundId,
      section: WritingPracticeSet.section,
      level: 4,
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

  List<Question> _fallbackQuestionsForRound(String roundId) {
    if (roundId.contains('102')) {
      return _round102WritingQuestions;
    } else if (roundId.contains('83')) {
      return _round83WritingQuestions;
    } else {
      return _fallbackWritingQuestions;
    }
  }
}

/// Selector for TOPIK round and Question tabs (51, 52, 53, 54)
class _RoundAndTypeSelector extends StatelessWidget {
  const _RoundAndTypeSelector({
    required this.selectedRoundId,
    required this.onRoundChanged,
    required this.currentIndex,
    required this.items,
    required this.onSelectQuestion,
  });

  final String selectedRoundId;
  final ValueChanged<String> onRoundChanged;
  final int currentIndex;
  final List<Question> items;
  final ValueChanged<int> onSelectQuestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        children: [
          // Round Choice Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _roundChip(
                  id: 'topik2-102-writing',
                  label: '제102회 기출 쓰기',
                  isSelected: selectedRoundId == 'topik2-102-writing',
                ),
                const SizedBox(width: 8),
                _roundChip(
                  id: 'topik2-83-writing',
                  label: '제83회 기출 쓰기',
                  isSelected: selectedRoundId == 'topik2-83-writing',
                ),
                const SizedBox(width: 8),
                _roundChip(
                  id: 'writing-fallback-set',
                  label: '표준 실전 연습',
                  isSelected: selectedRoundId == 'writing-fallback-set',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Question Tabs (51, 52, 53, 54)
          Row(
            children: List.generate(items.length, (index) {
              final q = items[index];
              final isCurrent = index == currentIndex;
              final num = q.questionNumber > 0 ? '${q.questionNumber}번' : '${index + 1}번';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => onSelectQuestion(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.mint.withValues(alpha: 0.15)
                            : const Color(0xFFF1F4F8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent ? AppColors.mintDark : Colors.black12,
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          num,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: isCurrent ? AppColors.mintDark : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _roundChip({
    required String id,
    required String label,
    required bool isSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onRoundChanged(id);
      },
      selectedColor: AppColors.mint.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.mintDark : Colors.black87,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.mintDark : Colors.black12,
      ),
    );
  }
}

/// 51번 & 52번 Short Completion Dedicated Editor (Dual ㉠ & ㉡ inputs + Style Tips)
class _ShortCompletionEditor extends StatelessWidget {
  const _ShortCompletionEditor({
    required this.questionNumber,
    required this.controllerA,
    required this.controllerB,
    required this.onChanged,
    required this.enabled,
  });

  final int questionNumber;
  final TextEditingController controllerA;
  final TextEditingController controllerB;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isQ51 = questionNumber == 51;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Style guidance banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isQ51
                      ? '51번 작성 꿀팁: 이메일·공고문 등 실용문이므로 문맥에 맞는 내용과 함께 격식체 존댓말(-ㅂ니다/습니다, -기 바랍니다, -으려고 합니다)로 완성하세요.'
                      : '52번 작성 꿀팁: 설명문·학술문이므로 논리적 인과관계를 완성하며, 객관적 서술을 위해 평서체 종결어미(-ㄴ다/는다, -(이)라고 한다, -기 때문이다)를 사용하세요.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ㉠ Input Field
        _inputField(
          marker: '㉠',
          controller: controllerA,
          hint: '㉠에 들어갈 알맞은 말을 쓰세요.',
        ),
        const SizedBox(height: 14),
        // ㉡ Input Field
        _inputField(
          marker: '㉡',
          controller: controllerB,
          hint: '㉡에 들어갈 알맞은 말을 쓰세요.',
        ),
      ],
    );
  }

  Widget _inputField({
    required String marker,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              marker,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 53번 Graph Description Dedicated Editor (Image + 200~300 char gauge + 3-step templates)
class _GraphDescriptionEditor extends StatefulWidget {
  const _GraphDescriptionEditor({
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  State<_GraphDescriptionEditor> createState() =>
      _GraphDescriptionEditorState();
}

class _GraphDescriptionEditorState extends State<_GraphDescriptionEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant _GraphDescriptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    setState(() {});
  }

  void _insertTemplate(String template) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, template);
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: selection.start + template.length,
      );
    } else {
      widget.controller.text = text.isEmpty ? template : '$text $template';
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = widget.controller.text.characters.length;
    final Color gaugeColor;
    final String gaugeLabel;

    if (charCount < 200) {
      gaugeColor = const Color(0xFFD97706);
      gaugeLabel = '권장 200~300자 (200자 이상 작성해야 합니다)';
    } else if (charCount <= 300) {
      gaugeColor = const Color(0xFF16A34A);
      gaugeLabel = '권장 분량 달성! (200~300자)';
    } else {
      gaugeColor = const Color(0xFFDC2626);
      gaugeLabel = '300자 초과 주의 (감점 요인)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real-time character gauge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: gaugeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: gaugeColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    gaugeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: gaugeColor,
                    ),
                  ),
                  Text(
                    '$charCount자 / 200~300자',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: gaugeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (charCount / 300).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation(gaugeColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 3-step template helper chips
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
                  Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF0F8C63)),
                  SizedBox(width: 6),
                  Text(
                    '53번 필수 서술 템플릿 (탭하여 본문에 삽입):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F8C63),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _templateChip(
                    label: '[도입] ...에 따르면',
                    text: '...에 따르면 ...에 대한 조사를 실시하였다. 조사 결과 ',
                  ),
                  _templateChip(
                    label: '[비교] ...증가한 반면',
                    text: '...은/는 N%에서 N%로 크게 증가한 반면, ...은/는 ',
                  ),
                  _templateChip(
                    label: '[원인] ...때문인 것으로 보인다',
                    text: '이러한 변화의 원인은 ... 때문인 것으로 보인다. ',
                  ),
                  _templateChip(
                    label: '[전망] ...할 것으로 전망된다',
                    text: '앞으로 ...할 것으로 전망된다.',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Text field
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          minLines: 8,
          maxLines: 12,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: '자료를 분석하여 200~300자로 작성하세요. (글의 제목은 쓰지 마십시오)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black26),
            ),
          ),
        ),
      ],
    );
  }

  Widget _templateChip({required String label, required String text}) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      backgroundColor: const Color(0xFFF1F4F8),
      side: const BorderSide(color: Colors.black12),
      onPressed: () => _insertTemplate(text),
    );
  }
}

/// 54번 Essay Dedicated Editor (600~700 char gauge + 3-condition checklist)
class _EssayEditor extends StatefulWidget {
  const _EssayEditor({
    required this.controller,
    required this.checkedConditions,
    required this.onConditionToggled,
    required this.enabled,
  });

  final TextEditingController controller;
  final Set<int> checkedConditions;
  final ValueChanged<int> onConditionToggled;
  final bool enabled;

  @override
  State<_EssayEditor> createState() => _EssayEditorState();
}

class _EssayEditorState extends State<_EssayEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant _EssayEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final charCount = widget.controller.text.characters.length;
    final Color gaugeColor;
    final String gaugeLabel;

    if (charCount < 600) {
      gaugeColor = const Color(0xFFD97706);
      gaugeLabel = '권장 600~700자 (서론-본론-결론 3단 구성)';
    } else if (charCount <= 700) {
      gaugeColor = const Color(0xFF16A34A);
      gaugeLabel = '권장 분량 달성! (600~700자)';
    } else {
      gaugeColor = const Color(0xFFDC2626);
      gaugeLabel = '700자 초과 주의 (감점 요인)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3-condition checklist
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
                  Icon(Icons.checklist_rounded, size: 18, color: Color(0xFF6E5BD8)),
                  SizedBox(width: 6),
                  Text(
                    '54번 3대 필수 조건 체크리스트 (작성 시 확인):',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6E5BD8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _conditionCheckTile(0, '1. 첫 번째 질문 조건 서술 (서론 및 현상/필요성)'),
              _conditionCheckTile(1, '2. 두 번째 질문 조건 서술 (본론: 성과/장점/문제점)'),
              _conditionCheckTile(2, '3. 세 번째 질문 조건 서술 (결론: 해결방안/노력)'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Real-time character gauge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: gaugeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: gaugeColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    gaugeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: gaugeColor,
                    ),
                  ),
                  Text(
                    '$charCount자 / 600~700자',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: gaugeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (charCount / 700).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation(gaugeColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Text field
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          minLines: 12,
          maxLines: 18,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: '주제와 조건에 맞게 600~700자로 글을 쓰세요. (문제를 그대로 옮겨 쓰지 마십시오)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black26),
            ),
          ),
        ),
      ],
    );
  }

  Widget _conditionCheckTile(int index, String title) {
    final checked = widget.checkedConditions.contains(index);
    return InkWell(
      onTap: () => widget.onConditionToggled(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: checked ? const Color(0xFF6E5BD8) : Colors.black38,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? Colors.black45 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Image preview for Question 53 graph
class _GraphImagePreview extends StatelessWidget {
  const _GraphImagePreview({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    String? imageUrl;

    for (final m in question.media) {
      if (isImageMedia(m) && m.url.isNotEmpty) {
        imageUrl = m.url;
        break;
      }
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      if ((question.setId?.contains('102') ?? false) ||
          question.id.contains('102')) {
        imageUrl =
            'https://damqug77a9y1r.cloudfront.net/test/photos/mock-exams/topik2-102/writing-q53.png';
      } else if ((question.setId?.contains('83') ?? false) ||
          question.id.contains('83')) {
        imageUrl =
            'https://damqug77a9y1r.cloudfront.net/test/photos/mock-exams/topik2-83/writing-q53.png';
      }
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final resolvedUrl = resolveApiMediaUrl(imageUrl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insert_chart_outlined, size: 16, color: Color(0xFF0F8C63)),
              SizedBox(width: 6),
              Text(
                '도표 / 그래프 자료',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F8C63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                resolvedUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side or stacked review card comparing user answer with model answer
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.question,
    required this.textAnswer,
    this.controllerA,
    this.controllerB,
    required this.explanation,
    this.sampleAnswer,
  });

  final Question question;
  final String textAnswer;
  final TextEditingController? controllerA;
  final TextEditingController? controllerB;
  final String? explanation;
  final String? sampleAnswer;

  @override
  Widget build(BuildContext context) {
    final isShort = question.questionNumber <= 52 ||
        question.questionType == 'writing_short_completion';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
              SizedBox(width: 8),
              Text(
                '작성 답안 & 공식 모범 답안 비교',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // User Answer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '내가 작성한 답안',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    if (!isShort)
                      Text(
                        '${textAnswer.characters.length}자',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isShort && controllerA != null && controllerB != null) ...[
                  Text(
                    '㉠: ${controllerA!.text.trim().isEmpty ? "(미작성)" : controllerA!.text.trim()}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '㉡: ${controllerB!.text.trim().isEmpty ? "(미작성)" : controllerB!.text.trim()}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ] else ...[
                  Text(
                    textAnswer.trim().isEmpty ? '(작성된 답안이 없습니다)' : textAnswer.trim(),
                    style: const TextStyle(height: 1.5, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Official Model Answer
          if (sampleAnswer != null && sampleAnswer!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '공식 모범 답안',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sampleAnswer!,
                    style: const TextStyle(
                      height: 1.55,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Explanation / Scoring Points
          if (explanation?.isNotEmpty ?? false) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
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
                      Icon(Icons.assignment_turned_in_outlined,
                          size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 6),
                      Text(
                        '채점 기준 및 해설',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    explanation!,
                    style: const TextStyle(
                      height: 1.55,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressHeader extends ConsumerWidget {
  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.question,
  });

  final int current;
  final int total;
  final Question question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarkedQuestionIdsProvider).value ?? {};
    final isBookmarked = bookmarkedIds.contains(question.id);

    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '문항 ${question.questionNumber > 0 ? question.questionNumber : current}번 (${question.questionType})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$current / $total',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            _instructionFor(question.questionNumber),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  String _instructionFor(int number) {
    if (number == 51 || number == 52) {
      return '다음을 읽고 ㉠과 ㉡에 알맞은 말을 각각 쓰시오. (각 10점)';
    } else if (number == 53) {
      return '다음 자료를 보고 200~300자의 글로 쓰시오. (30점)';
    } else if (number == 54) {
      return '다음을 참고하여 600~700자로 글을 쓰시오. (50점)';
    }
    return '다음을 읽고 알맞은 답안을 작성하십시오.';
  }
}

class _PassageCard extends StatelessWidget {
  const _PassageCard({
    required this.text,
    this.isShortCompletion = false,
  });

  final String text;
  final bool isShortCompletion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: isShortCompletion ? _highlightedShortPassage(text) : Text(
        text,
        style: const TextStyle(
          height: 1.6,
          fontSize: 14.5,
          color: Color(0xFF222222),
        ),
      ),
    );
  }

  Widget _highlightedShortPassage(String content) {
    final blankRegex = RegExp(r'(\(\s*[㉠㉡㉢㉣]\s*\)|\(\s{2,}\)|\[\s{2,}\])');
    final matches = blankRegex.allMatches(content);

    if (matches.isEmpty) {
      return Text(
        content,
        style: const TextStyle(height: 1.6, fontSize: 14.5, color: Color(0xFF222222)),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: content.substring(lastEnd, match.start)));
      }
      final matchedText = match.group(0)!;
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
              matchedText,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd)));
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(height: 1.6, fontSize: 14.5, color: Color(0xFF222222)),
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                      : Icon(submitted ? Icons.edit_outlined : Icons.upload_rounded),
                  label: Text(
                    saving ? '저장 중...' : (submitted ? '다시 수정하기' : '답안 제출 및 모범 답안 확인'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '쓰기 답안 제출 완료',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  '전체 $total문항 중 $answered문항 작성 · 아래 모범 답안을 확인하세요.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 102회 기출 쓰기 (4문항)
// ==========================================
final _round102WritingQuestions = [
  const Question(
    id: 'topik2-102-writing-q51',
    setId: 'topik2-102-writing',
    section: 'writing',
    questionType: 'writing_short_completion',
    questionNumber: 51,
    level: 3,
    prompt: '다음 글의 ㉠과 ㉡에 알맞은 말을 각각 쓰시오. (각 10점)',
    passageText: '제목 : 개인 물건 정리 요청\n\n안녕하세요. 동아리 회장 흐엉입니다.\n학생회관 공사 때문에 동아리 방을 옮기게 되었습니다.\n그런데 현재 개인 물건들이 너무 많습니다.\n동아리 방을 옮기려면 이 물건들부터 먼저 ( ㉠ ).\n방학을 하자마자 공사가 시작됩니다.\n방학이 ( ㉡ ) 개인 물건을 모두 가져가 주십시오.',
    correctAnswer: '㉠ 정리해야 합니다 / ㉡ 시작되기 전에',
    explanation: '[모범답안]\n㉠ 정리해야 합니다 / 치워야 합니다\n㉡ 시작되기 전에 / 시작하기 전에\n\n[채점 기준]\n- ㉠: 동아리 방을 옮기기 위해 물건을 먼저 치우거나 정리해야 한다는 의미 (10점)\n- ㉡: 공사가 방학 직후 시작되므로 방학이 시작되기 전에 물건을 가져가라는 의미 (10점)',
    difficulty: 3,
    timeLimitSeconds: 300,
    options: [],
    media: [],
  ),
  const Question(
    id: 'topik2-102-writing-q52',
    setId: 'topik2-102-writing',
    section: 'writing',
    questionType: 'writing_short_completion',
    questionNumber: 52,
    level: 4,
    prompt: '다음 글의 ㉠과 ㉡에 알맞은 말을 각각 쓰시오. (각 10점)',
    passageText: '큰 항공기는 주로 고도가 높은 하늘에서 비행을 한다. 높이 올라가면 날씨의 영향을 별로 ( ㉠ ) 흔들림이 적다. 반면 작은 항공기는 날씨의 영향을 받더라도 낮은 고도에서 비행을 해야 한다. 왜냐하면 높은 고도에서 ( ㉡ ) 항공기의 엔진이 크고 좋아야 하며 연료도 많이 필요하기 때문이다.',
    correctAnswer: '㉠ 받지 않아서 / ㉡ 비행을 하기 위해서는',
    explanation: '[모범답안]\n㉠ 받지 않아서 / 받지 않기 때문에\n㉡ 비행을 하기 위해서는 / 날기 위해서는 / 운항하려면\n\n[채점 기준]\n- ㉠: 높은 고도에서는 날씨의 영향을 받지 않아 흔들림이 적다는 맥락의 표현 (10점)\n- ㉡: 높은 고도에서 비행하기 위한 조건(엔진, 연료)을 나타내는 목적/조건 표현 (10점)',
    difficulty: 4,
    timeLimitSeconds: 300,
    options: [],
    media: [],
  ),
  const Question(
    id: 'topik2-102-writing-q53',
    setId: 'topik2-102-writing',
    section: 'writing',
    questionType: 'writing_graph_description',
    questionNumber: 53,
    level: 4,
    prompt: '다음은 "한국 캠핑 인구의 변화"에 대한 자료이다. 이 내용을 200~300자의 글로 쓰시오. 단, 글의 제목은 쓰지 마시오. (30점)',
    passageText: '[조사 기관: 한국관광공사]\n\n• 캠핑 인구 변화: 2019년 340만 명 → 2024년 650만 명 (약 2배 증가)\n• 연령별 순위 변화:\n  - 2019년: 1위 20대~30대, 2위 40대~50대\n  - 2024년: 1위 40대~50대, 2위 20대~30대\n• 원인:\n  - 장비의 고급화와 캠핑장 대여료 증가 → 경제력이 요구됨\n  - 자녀와의 여가 활동을 위한 가족 단위 캠핑 증가',
    correctAnswer: '한국관광공사에서 한국 캠핑 인구의 변화에 대해 조사한 자료에 따르면 캠핑 인구는 2019년에 340만 명이었던 것이 2024년에 650만 명으로 약 2배나 증가하였다. 이를 연령별 순위 변화로 보면 2019년에는 20대~30대가 1위를 차지하였고 2위는 40대~50대로 나타났다. 이와 달리 2024년에는 40대~50대가 1위로 가장 많았고 2위는 20대~30대로 나타났다. 이렇게 변화한 것은 캠핑 장비의 고급화와 캠핑장 대여료 증가로 인해 경제력이 요구되었고 자녀와의 여가 활동을 위한 가족 단위 캠핑이 증가하였기 때문으로 나타났다. (300자)',
    explanation: '[모범답안]\n한국관광공사에서 한국 캠핑 인구의 변화에 대해 조사한 자료에 따르면 캠핑 인구는 2019년에 340만 명이었던 것이 2024년에 650만 명으로 약 2배나 증가하였다. 이를 연령별 순위 변화로 보면 2019년에는 20대~30대가 1위를 차지하였고 2위는 40대~50대로 나타났다. 이와 달리 2024년에는 40대~50대가 1위로 가장 많았고 2위는 20대~30대로 나타났다. 이렇게 변화한 것은 캠핑 장비의 고급화와 캠핑장 대여료 증가로 인해 경제력이 요구되었고 자녀와의 여가 활동을 위한 가족 단위 캠핑이 증가하였기 때문으로 나타났다. (300자)\n\n[채점 포인트]\n- 조사 기관과 주제 소개\n- 전체 캠핑 인구 수치 비교(340만->650만, 2배)\n- 연령별 순위 역전(2030->4050) 서술\n- 원인 2가지(경제력, 가족 단위 여가) 정확히 반영',
    difficulty: 4,
    timeLimitSeconds: 900,
    options: [],
    media: [
      QuestionMedia(
        id: 'topik2-102-writing-q53-img',
        mediaType: 'image',
        url: 'https://damqug77a9y1r.cloudfront.net/test/photos/mock-exams/topik2-102/writing-q53.png',
        transcript: null,
      ),
    ],
  ),
  const Question(
    id: 'topik2-102-writing-q54',
    setId: 'topik2-102-writing',
    section: 'writing',
    questionType: 'writing_essay',
    questionNumber: 54,
    level: 5,
    prompt: '다음을 참고하여 600~700자로 글을 쓰시오. 단, 문제를 그대로 옮겨 쓰지 마시오. (50점)',
    passageText: '최근에는 식당에서부터 은행, 병원에 이르기까지 많은 곳에서 다양한 디지털 기기를 사용하고 있다. 하지만 디지털 기기를 활용하지 못해서 소외되는 사람들도 있다. 아래의 내용을 중심으로 "디지털 소외 문제와 해결 방안"에 대한 자신의 생각을 쓰라.\n\n• 디지털 기술은 우리 생활에서 어떻게 활용되고 있는가?\n• 디지털 사회에서 소외되는 사람들은 누구이며, 어떤 문제를 겪을 수 있는가?\n• 디지털 소외 문제를 해결하기 위해 개인과 사회는 어떻게 해야 하는가?',
    correctAnswer: '과학 기술이 빠르게 발달하면서 과거와는 달리 일상생활에서 디지털 기술의 활용이 일반화되고 있다. 식당에서는 대면을 하지 않아도 키오스크로 음식을 주문할 수 있게 되었고 관공서나 금융 기관을 직접 방문하지 않아도 컴퓨터나 스마트폰으로 서비스를 이용할 수 있게 되었다. 또한 병원의 진료 예약이나 공연, 기차표 등의 예매도 인터넷으로 손쉽게 할 수 있다.\n\n그러나 이러한 편의를 모든 사람들이 동일하게 누리는 것은 아니다. 고령층의 경우 디지털 기기가 익숙하지 않아서 금융 의료 서비스를 이용하는 데에 어려움이 따른다. 그리고 경제적인 여건이 되지 않아 디지털 기기를 구입하거나 사용하는 것이 부담이 되는 사람들도 있을 것이다. 또한 디지털 인프라가 부족한 지역에서 거주하는 사람들은 온라인으로 제공 받을 수 있는 서비스가 제한적이다.\n\n이러한 문제를 해결하기 위해서는 개인과 사회 모두가 노력해야 한다. 개인의 경우 처음에는 익숙하지 않더라도 변화하는 시대에 뒤처지지 않게 디지털 기기의 사용법을 익히도록 해야 한다. 이를 위해서 정부에서는 디지털 소외 계층을 위한 지원 정책을 마련해서 모든 국민들이 일상에서 디지털 기술을 활용할 수 있게 하여 소외되는 사람들이 없도록 해야 한다. 그리고 디지털 인프라를 확충하여 지역과 계층에 무관하게 많은 사람들이 디지털 기술 발달의 혜택을 고르게 누릴 수 있도록 해야 한다. (675자)',
    explanation: '[모범답안 구조]\n- 서론: 디지털 기술 활용의 보편화(키오스크, 모바일 뱅킹, 인터넷 예매)\n- 본론: 소외 계층(고령층, 경제적 취약층, 지역 격차)과 겪는 문제\n- 결론: 개인의 적응 노력 + 사회/정부의 교육 지원 및 인프라 확충\n\n[글자 수: 675자 (권장 600~700자 충족)]',
    difficulty: 5,
    timeLimitSeconds: 1800,
    options: [],
    media: [],
  ),
];

// ==========================================
// 83회 기출 쓰기 (4문항)
// ==========================================
final _round83WritingQuestions = [
  const Question(
    id: 'topik2-83-writing-q51',
    setId: 'topik2-83-writing',
    section: 'writing',
    questionType: 'writing_short_completion',
    questionNumber: 51,
    level: 3,
    prompt: '다음 글의 ㉠과 ㉡에 알맞은 말을 각각 쓰시오. (각 10점)',
    passageText: '[자유게시판: 축제 관련 문의]\n\n지난 주말 \'인주시 별빛 축제\'에 갔던 외국인입니다.\n지금까지 살면서 이렇게 많은 별을 ( ㉠ ) 한 번도 없었습니다.\n이번 축제에서 별도 보고 공연도 볼 수 있어서 정말 좋았습니다.\n혹시 축제가 언제 또 있습니까?\n있다면 이런 멋진 경험을 다시 ( ㉡ ).',
    correctAnswer: '㉠ 본 적이 / ㉡ 하고 싶습니다',
    explanation: '[모범답안]\n㉠ 본 적이 / 본 경험이\n㉡ 하고 싶습니다 / 할 수 있으면 좋겠습니다\n\n[채점 기준]\n- ㉠: 별을 본 경험이 없다는 의미로 \'-ㄴ 적이 없다/경험이 없다\' 표현 사용 (10점)\n- ㉡: 축제 경험을 다시 하고 싶다는 희망/소망을 나타내는 \'-고 싶다/바라다\' 표현 사용 (10점)',
    difficulty: 3,
    timeLimitSeconds: 300,
    options: [],
    media: [],
  ),
  const Question(
    id: 'topik2-83-writing-q52',
    setId: 'topik2-83-writing',
    section: 'writing',
    questionType: 'writing_short_completion',
    questionNumber: 52,
    level: 4,
    prompt: '다음 글의 ㉠과 ㉡에 알맞은 말을 각각 쓰시오. (각 10점)',
    passageText: '식물은 다양한 방법으로 자신을 보호한다. 덩굴성 야자나무는 빈 줄기를 개미에게 집으로 제공한다. 이 나무에 다른 동물이 다가오면 줄기 속에 있던 개미들은 밖으로 나온다. 이때 개미들의 움직임으로 소리가 생긴다. 이 소리는 동물을 깜짝 ( ㉠ ). 결국 놀란 동물은 나뭇잎을 먹지 못하고 달아나 버린다. 식물학자들은 이것이 바로 이 나무가 자신을 보호하는 ( ㉡ ).',
    correctAnswer: '㉠ 놀라게 한다 / ㉡ 방법이라고 한다',
    explanation: '[모범답안]\n㉠ 놀라게 한다 / 놀라게 만든다\n㉡ 방법이라고 한다 / 방법이라고 설명한다\n\n[채점 기준]\n- ㉠: 소리가 동물을 놀라게 한다는 사동 표현(\'-게 하다/-게 만들다\') 사용 (10점)\n- ㉡: 식물학자들의 주장을 인용하여 자신을 보호하는 방법임을 나타내는 간접화법(\'-(이)라고 한다\') 사용 (10점)',
    difficulty: 4,
    timeLimitSeconds: 300,
    options: [],
    media: [],
  ),
  const Question(
    id: 'topik2-83-writing-q53',
    setId: 'topik2-83-writing',
    section: 'writing',
    questionType: 'writing_graph_description',
    questionNumber: 53,
    level: 4,
    prompt: '다음은 "인주시의 가구 수 변화"에 대한 자료이다. 이 내용을 200~300자의 글로 쓰시오. 단, 글의 제목은 쓰지 마시오. (30점)',
    passageText: '• 조사 기관 : 인주시 사회연구소\n\n• 인주시의 가구 수:\n  - 2001년 15만 가구 → 2021년 21만 가구 (1.4배 증가)\n• 인원수별 가구의 비율:\n  - 1인 가구: 2001년 15% → 2021년 30% (대폭 증가)\n  - 2~3인 가구: 2001년 45% → 2021년 50% (증가)\n  - 4인 이상 가구: 2001년 40% → 2021년 20% (대폭 감소)\n• 원인: 20대 독립 가구 수, 노인 가구 수 증가\n• 전망: 2040년 1인 가구 43% 이상',
    correctAnswer: '인주시 사회연구소에서는 인주시의 가구 수 변화를 조사하였다. 조사 결과 인주시의 가구 수는 2001년에 15만 가구에서 2021년에는 21만 가구로 1.4배 증가하였다. 이는 인원수별 가구의 비율이 1인 가구는 2001년에 15%에서 2021년에는 30%로 크게 증가하였고 2~3인 가구는 45%에서 50%로 증가한 반면, 4인 이상 가구는 40%에서 20%로 큰 폭으로 감소하였기 때문이다. 이러한 변화는 독립한 20대와 노인 가구 증가의 결과로 보인다. 2040년에는 1인 가구가 43% 이상이 될 전망이다. (287자)',
    explanation: '[모범답안]\n인주시 사회연구소에서는 인주시의 가구 수 변화를 조사하였다. 조사 결과 인주시의 가구 수는 2001년에 15만 가구에서 2021년에는 21만 가구로 1.4배 증가하였다. 이는 인원수별 가구의 비율이 1인 가구는 2001년에 15%에서 2021년에는 30%로 크게 증가하였고 2~3인 가구는 45%에서 50%로 증가한 반면, 4인 이상 가구는 40%에서 20%로 큰 폭으로 감소하였기 때문이다. 이러한 변화는 독립한 20대와 노인 가구 증가의 결과로 보인다. 2040년에는 1인 가구가 43% 이상이 될 전망이다. (287자)',
    difficulty: 4,
    timeLimitSeconds: 900,
    options: [],
    media: [
      QuestionMedia(
        id: 'topik2-83-writing-q53-img',
        mediaType: 'image',
        url: 'https://damqug77a9y1r.cloudfront.net/test/photos/mock-exams/topik2-83/writing-q53.png',
        transcript: null,
      ),
    ],
  ),
  const Question(
    id: 'topik2-83-writing-q54',
    setId: 'topik2-83-writing',
    section: 'writing',
    questionType: 'writing_essay',
    questionNumber: 54,
    level: 5,
    prompt: '다음을 참고하여 600~700자로 글을 쓰시오. 단, 문제를 그대로 옮겨 쓰지 마시오. (50점)',
    passageText: '창의력은 새로운 것을 생각해 내는 능력이다. 현대 사회는 개인에게 창의력을 더 많이 요구하고 있다. 아래의 내용을 중심으로 "창의력의 필요성과 이를 기르기 위한 노력"에 대한 자신의 생각을 쓰라.\n\n• 창의력이 필요한 이유는 무엇인가?\n• 창의력을 발휘했을 때 얻을 수 있는 성과는 무엇인가?\n• 창의력을 기르기 위해서 어떠한 노력을 할 수 있는가?',
    correctAnswer: '변화와 발전을 끊임없이 요구하는 현대 사회에서 창의력은 꼭 필요하다. 먼저 창의력은 새로운 관점을 가져온다. 정보가 넘쳐나는 오늘날 새로운 관점이 있으면 차별화된 시각으로 정보를 통합하고 활용할 수 있다. 또한 우리 사회는 새로운 시도 없이는 발전하기 어려운데 창의력은 기존 사고에 머무르지 않고 변화를 시도할 수 있게 돕는다. 나아가 창의력은 기존의 사고만으로는 해결하기 어려운 문제를 해결하는 데에 중요한 역할을 한다.\n\n이와 같이 창의력은 새로운 사고를 할 수 있게 하므로 창의력을 발휘했을 때 우리는 다양한 성과를 얻을 수 있다. 창의력을 발휘하면 자신의 업무 분야에서 뛰어난 업무 성과를 보일 수 있다. 또한 예술과 문화의 영역에서 음악이나 영화 등 새로운 콘텐츠를 만들어 냄으로써 사람들에게 신선한 감동을 줄 수도 있다. 뿐만 아니라 획기적인 사고를 바탕으로 삶의 질을 높여주는 새로운 상품이나 기술을 발명하여 사회에 기여할 수 있다.\n\n창의력을 기르기 위해서는 먼저 독서 및 다양한 경험을 통해 사고의 폭을 넓혀야 한다. 또한 눈에 보이는 현상에만 집중하는 것이 아니라 현상 뒤에 숨겨진 원인을 탐색하고 새로운 관점으로 문제에 접근하는 태도를 가져야 한다. 마지막으로 기존의 정답에만 머무는 것이 아니라 비판적 사고를 바탕으로 새로운 해결 방안이 없는지를 모색하는 노력을 기울여야 한다. (682자)',
    explanation: '[모범답안 분석]\n- 서론: 창의력이 필요한 이유 (새로운 관점, 사회 발전의 원동력, 난제 해결)\n- 본론: 창의력을 발휘했을 때의 성과 (업무 성과, 문화 예술 콘텐츠 창출, 신기술 발명)\n- 결론: 창의력을 기르기 위한 노력 (독서와 다양한 경험, 원인 탐색 태도, 비판적 사고)\n\n[글자 수: 682자]',
    difficulty: 5,
    timeLimitSeconds: 1800,
    options: [],
    media: [],
  ),
];

// ==========================================
// 표준 실전 연습 쓰기 (4문항)
// ==========================================
final _fallbackWritingQuestions = [
  const Question(
    id: 'writing-51-fallback',
    setId: 'writing-fallback-set',
    section: 'writing',
    questionType: 'writing_short_completion',
    questionNumber: 51,
    level: 3,
    prompt: '다음을 읽고 빈칸에 알맞은 말을 쓰십시오. (51번)',
    passageText: '민수 씨, 안녕하세요?\n내일 한국어 발표 모임 시간이 오후 3시에서 오후 4시로 바뀌었습니다. 발표 자료를 준비하는 데 시간이 더 필요하다는 친구들이 많았기 때문입니다. 혹시 시간이 괜찮으시면 4시까지 동아리방으로 와 주세요.\n\n발표 모임 시간이 바뀌었으니까 민수 씨는 내일 오후 4시에 (        ).',
    correctAnswer: '동아리방으로 가야 합니다 (또는 동아리방으로 오시기 바랍니다)',
    explanation: '[작성 포인트]\n- 장소(동아리방)와 행동(가야 합니다/오셔야 합니다)을 완성해야 합니다.\n\n[모범 답안]\n동아리방으로 가야 합니다 (또는 동아리방으로 오시기 바랍니다)',
    difficulty: 3,
    timeLimitSeconds: 300,
    options: [],
    media: [],
  ),
  const Question(
    id: 'writing-52-fallback',
    setId: 'writing-fallback-set',
    section: 'writing',
    questionType: 'writing_short_completion',
    questionNumber: 52,
    level: 4,
    prompt: '다음을 읽고 빈칸에 알맞은 말을 쓰십시오. (52번)',
    passageText: '최근 우리 학교 도서관은 저녁 운영 시간을 두 시간 연장했습니다. 예전에는 수업이 늦게 끝나는 학생들이 도서관을 이용하기 어려웠습니다. 하지만 운영 시간이 길어진 후에는 저녁에도 공부하는 학생들이 많아졌습니다. 이처럼 도서관 운영 시간 연장은 학생들에게 (        ).',
    correctAnswer: '공부할 수 있는 기회를 더 많이 제공합니다 (또는 많은 도움을 줍니다)',
    explanation: '[작성 포인트]\n- 운영 시간 연장의 긍정적 효과(공부할 수 있는 기회를 줌)를 연결하여 완성합니다.\n\n[모범 답안]\n공부할 수 있는 기회를 더 많이 제공합니다 (또는 많은 도움을 줍니다)',
    difficulty: 4,
    timeLimitSeconds: 300,
    options: [],
    media: [],
  ),
  const Question(
    id: 'writing-53-fallback',
    setId: 'writing-fallback-set',
    section: 'writing',
    questionType: 'writing_graph_description',
    questionNumber: 53,
    level: 4,
    prompt: '다음 자료를 보고 200~300자로 글을 쓰십시오. (53번)',
    passageText: '자료: 직장인의 점심시간 이용 방법 변화\n\n2018년\n- 식당에서 식사: 55%\n- 도시락: 20%\n- 산책 또는 휴식: 15%\n- 자기계발: 10%\n\n2026년\n- 식당에서 식사: 35%\n- 도시락: 25%\n- 산책 또는 휴식: 25%\n- 자기계발: 15%\n\n쓰기 조건:\n1. 2018년과 2026년의 변화를 비교하십시오.\n2. 주요 항목의 비율 변화를 설명하십시오.\n3. 변화의 이유를 추측하여 쓰십시오.',
    correctAnswer: '자료에 따르면 직장인의 점심시간 이용 방법은 2018년과 2026년에 차이를 보인다. 식당에서 식사하는 비율은 55%에서 35%로 크게 줄었다. 반면 도시락은 20%에서 25%로, 산책 또는 휴식은 15%에서 25%로 증가했다. 자기계발도 10%에서 15%로 늘었다. 이는 건강과 개인 시간을 중요하게 생각하는 직장인이 많아졌기 때문으로 보인다.',
    explanation: '[작성 포인트]\n- 제목을 쓰지 않고 200~300자로 작성합니다.\n- 수치 비교(55%->35% 감소, 도시락/휴식/자기계발 증가)와 원인 추측을 포함합니다.\n\n[모범 답안]\n자료에 따르면 직장인의 점심시간 이용 방법은 2018년과 2026년에 차이를 보인다. 식당에서 식사하는 비율은 55%에서 35%로 크게 줄었다. 반면 도시락은 20%에서 25%로, 산책 또는 휴식은 15%에서 25%로 증가했다. 자기계발도 10%에서 15%로 늘었다. 이는 건강과 개인 시간을 중요하게 생각하는 직장인이 많아졌기 때문으로 보인다.',
    difficulty: 4,
    timeLimitSeconds: 900,
    options: [],
    media: [],
  ),
  const Question(
    id: 'writing-54-fallback',
    setId: 'writing-fallback-set',
    section: 'writing',
    questionType: 'writing_essay',
    questionNumber: 54,
    level: 5,
    prompt: '다음을 주제로 하여 600~700자로 글을 쓰십시오. (54번)',
    passageText: '주제: 현대 사회에서 온라인 학습의 장점과 한계\n\n쓰기 조건:\n1. 온라인 학습이 늘어난 이유를 설명하십시오.\n2. 온라인 학습의 장점을 두 가지 이상 쓰십시오.\n3. 온라인 학습의 한계와 이를 보완할 방법에 대해 쓰십시오.',
    correctAnswer: '현대 사회에서는 인터넷 기술이 발달하고 시간과 장소의 제약을 줄이려는 요구가 커지면서 온라인 학습이 빠르게 늘고 있다. 온라인 학습의 가장 큰 장점은 원하는 장소에서 공부할 수 있다는 점이다. 학교나 학원에 가지 않아도 수업을 들을 수 있기 때문에 이동 시간이 줄어든다. 또한 녹화 강의를 반복해서 들을 수 있어 이해가 부족한 부분을 다시 공부하기 쉽다. 그러나 온라인 학습에는 한계도 있다. 학습자가 스스로 시간을 관리하지 못하면 수업을 미루기 쉽고, 교사나 친구와 직접 소통할 기회가 부족할 수 있다. 이러한 문제를 해결하기 위해서는 학습 계획을 세우고 정해진 시간에 수업을 듣는 습관을 만들어야 한다. 또한 온라인 토론이나 화상 모임을 활용하면 부족한 소통을 보완할 수 있다. 결국 온라인 학습은 편리한 도구이지만 효과적으로 활용하려면 학습자의 자기 관리와 적절한 상호 작용이 함께 필요하다.',
    explanation: '[작성 포인트]\n- 서론(필요성/이유), 본론(장점 2가지 & 한계/보완책), 결론의 3단 구조로 600~700자를 작성합니다.',
    difficulty: 5,
    timeLimitSeconds: 1800,
    options: [],
    media: [],
  ),
];
