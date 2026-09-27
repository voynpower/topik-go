import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';

class GrammarQuizPage extends ConsumerStatefulWidget {
  const GrammarQuizPage({
    super.key,
    required this.source,
  });

  final GrammarStudySource source;

  @override
  ConsumerState<GrammarQuizPage> createState() => _GrammarQuizPageState();
}

class _GrammarQuizPageState extends ConsumerState<GrammarQuizPage> {
  List<GrammarQuizQuestion> _questions = [];
  bool _initialized = false;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  int _correctCount = 0;

  void _setupQuestions(List<GrammarQuizQuestion> questions) {
    if (!_initialized) {
      _questions = questions;
      _initialized = true;
    }
  }

  void _onSelectOption(int index) {
    if (_isAnswered) return;

    final currentQuestion = _questions[_currentIndex];
    final isCorrect = index == currentQuestion.correctIndex;

    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
      if (isCorrect) {
        _correctCount++;
      }
    });
  }

  void _onNext() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final strings = ref.read(appStringsProvider);
    final total = _questions.length;
    final percent = total > 0 ? ((_correctCount / total) * 100).round() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
            const SizedBox(width: 8),
            Text(strings.examResult),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(
              strings.quizScoreResult
                  .replaceAll('{total}', '$total')
                  .replaceAll('{correct}', '$_correctCount'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '정답률 $percent%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: Text(strings.confirm),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _initialized = false;
                _currentIndex = 0;
                _selectedOptionIndex = null;
                _isAnswered = false;
                _correctCount = 0;
              });
            },
            child: Text(strings.retryQuiz),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final grammarAsync = ref.watch(studyGrammarProvider(widget.source));

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.grammarQuiz),
        actions: [
          if (_questions.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q ${_currentIndex + 1} / ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: grammarAsync.when(
        data: (items) {
          if (!_initialized) {
            final questions = GrammarQuizQuestion.generateQuestions(items, maxQuestions: 10);
            _setupQuestions(questions);
          }

          if (_questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 64, color: Colors.black26),
                    const SizedBox(height: 16),
                    Text(
                      strings.noGrammarForQuiz,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          final question = _questions[_currentIndex];

          return Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: const Color(0xFFEDE9FE),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                minHeight: 4,
              ),

              // Main Quiz Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Question Prompt
                    Text(
                      '다음 빈칸에 알맞은 문법 표현을 고르십시오.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Context Sentence Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        question.clozeSentence,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4 Options
                    ...List.generate(question.options.length, (index) {
                      final option = question.options[index];
                      final isSelected = _selectedOptionIndex == index;
                      final isCorrect = index == question.correctIndex;

                      Color bgColor = Colors.white;
                      Color borderColor = const Color(0xFFE2E8F0);
                      Color textColor = const Color(0xFF0F172A);
                      Widget? trailingIcon;

                      if (_isAnswered) {
                        if (isCorrect) {
                          bgColor = const Color(0xFFDCFCE7);
                          borderColor = const Color(0xFF22C55E);
                          textColor = const Color(0xFF15803D);
                          trailingIcon = const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20);
                        } else if (isSelected) {
                          bgColor = const Color(0xFFFEE2E2);
                          borderColor = const Color(0xFFEF4444);
                          textColor = const Color(0xFFB91C1C);
                          trailingIcon = const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 20);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _isAnswered ? null : () => _onSelectOption(index),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor, width: isSelected || (_isAnswered && isCorrect) ? 2 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _isAnswered && isCorrect
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFEDE9FE),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _isAnswered && isCorrect
                                            ? Colors.white
                                            : const Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  ?trailingIcon,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Explanation Feedback Card (Shown after answered)
                    if (_isAnswered) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _selectedOptionIndex == question.correctIndex
                                      ? Icons.check_circle_outline
                                      : Icons.info_outline,
                                  color: _selectedOptionIndex == question.correctIndex
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedOptionIndex == question.correctIndex
                                      ? strings.correctAnswer
                                      : '정답: ${question.options[question.correctIndex]}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedOptionIndex == question.correctIndex
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.targetGrammar.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '원문: ${question.sentence}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Button
              if (_isAnswered)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _onNext,
                      child: Text(
                        _currentIndex + 1 < _questions.length
                            ? strings.nextQuestion
                            : strings.finishStudy,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(strings.error)),
      ),
    );
  }
}
