import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';

class VocabularyQuizPage extends ConsumerStatefulWidget {
  const VocabularyQuizPage({
    super.key,
    required this.source,
  });

  final StudyWordSource source;

  @override
  ConsumerState<VocabularyQuizPage> createState() => _VocabularyQuizPageState();
}

class _VocabularyQuizPageState extends ConsumerState<VocabularyQuizPage> {
  late final FlutterTts _tts;

  List<VocabularyQuizQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswerChecked = false;
  int _score = 0;
  final List<VocabularyItem> _wrongWords = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('ko-KR');
    _tts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  void _initQuestions(List<VocabularyItem> words) {
    if (_isInitialized) return;
    _questions = VocabularyQuizQuestion.generateQuestions(words, maxQuestions: 15);
    _currentIndex = 0;
    _score = 0;
    _wrongWords.clear();
    _isInitialized = true;
    _isAnswerChecked = false;
    _selectedOptionIndex = null;
  }

  void _selectOption(int index) {
    if (_isAnswerChecked) return;

    final currentQ = _questions[_currentIndex];
    final isCorrect = index == currentQ.correctIndex;

    setState(() {
      _selectedOptionIndex = index;
      _isAnswerChecked = true;
      if (isCorrect) {
        _score++;
      } else {
        _wrongWords.add(currentQ.targetWord);
      }
    });

    _speak(currentQ.targetWord.word);
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswerChecked = false;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final total = _questions.length;
    final percentage = (total > 0 ? (_score / total * 100) : 0).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.military_tech, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('퀴즈 완료!', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    '$percentage점',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: percentage >= 80 ? const Color(0xFF16A34A) : AppColors.mintDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '총 $total문제 중 $_score문제 정답',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_wrongWords.isNotEmpty) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '틀린 단어 (${_wrongWords.length}개)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _wrongWords.length,
                  itemBuilder: (context, i) {
                    final item = _wrongWords[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            item.word,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.meaningKo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 16, color: AppColors.mintDark),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _speak(item.word),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('종료'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final wordsAsync = ref.read(studyWordsProvider(widget.source));
              final words = wordsAsync.asData?.value ?? [];
              setState(() {
                _isInitialized = false;
                _initQuestions(words);
              });
            },
            child: const Text('다시 풀기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(studyWordsProvider(widget.source));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.source.title} 퀴즈'),
      ),
      body: wordsAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('퀴즈를 생성할 단어가 부족합니다.'));
          }

          if (!_isInitialized) {
            _initQuestions(words);
          }

          if (_questions.isEmpty) {
            return const Center(child: Text('퀴즈를 생성할 단어가 부족합니다.'));
          }

          final currentQ = _questions[_currentIndex];
          final progress = (_currentIndex + 1) / _questions.length;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '문제 ${_currentIndex + 1} / ${_questions.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mintDark,
                        ),
                      ),
                      Text(
                        '맞힌 개수: $_score',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation(AppColors.mintDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),

                  // Question Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          currentQ.isWordToMeaning ? '다음 단어의 알맞은 뜻을 고르세요' : '다음 뜻에 해당하는 한국어 단어를 고르세요',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                currentQ.prompt,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: currentQ.isWordToMeaning ? 28 : 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (currentQ.isWordToMeaning) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.volume_up, color: AppColors.mintDark),
                                onPressed: () => _speak(currentQ.targetWord.word),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4 Options
                  Expanded(
                    child: ListView.separated(
                      itemCount: currentQ.options.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final optionText = currentQ.options[index];
                        final isCorrect = index == currentQ.correctIndex;
                        final isSelected = index == _selectedOptionIndex;

                        Color borderColor = const Color(0xFFE2E8F0);
                        Color bgColor = Colors.white;
                        Color textColor = const Color(0xFF1E293B);

                        if (_isAnswerChecked) {
                          if (isCorrect) {
                            borderColor = const Color(0xFF16A34A);
                            bgColor = const Color(0xFFF0FDF4);
                            textColor = const Color(0xFF166534);
                          } else if (isSelected) {
                            borderColor = const Color(0xFFDC2626);
                            bgColor = const Color(0xFFFEF2F2);
                            textColor = const Color(0xFF991B1B);
                          }
                        }

                        return InkWell(
                          onTap: () => _selectOption(index),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: isSelected || (_isAnswerChecked && isCorrect) ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: borderColor.withValues(alpha: 0.2),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (_isAnswerChecked && isCorrect)
                                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 22)
                                else if (_isAnswerChecked && isSelected)
                                  const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 22),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Next Button
                  if (_isAnswerChecked)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _nextQuestion,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mintDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _currentIndex + 1 < _questions.length ? '다음 문제' : '결과 확인',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('오류 발생: $err')),
      ),
    );
  }
}
