import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';

class VocabularyDictationPage extends ConsumerStatefulWidget {
  const VocabularyDictationPage({
    super.key,
    required this.source,
  });

  final StudyWordSource source;

  @override
  ConsumerState<VocabularyDictationPage> createState() =>
      _VocabularyDictationPageState();
}

class _VocabularyDictationPageState
    extends ConsumerState<VocabularyDictationPage> {
  late final FlutterTts _tts;
  late final TextEditingController _inputController;
  late final FocusNode _focusNode;

  int _currentIndex = 0;
  bool _showHint = false;
  bool _isAnswerChecked = false;
  bool _isCorrect = false;
  int _score = 0;
  final List<VocabularyItem> _wrongWords = [];

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('ko-KR');
    _tts.setSpeechRate(0.45);
    _inputController = TextEditingController();
    _focusNode = FocusNode();

    // Speak initial word after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playCurrentWord();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _tts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  void _playCurrentWord() {
    final wordsAsync = ref.read(studyWordsProvider(widget.source));
    final words = wordsAsync.asData?.value;
    if (words != null && words.isNotEmpty && _currentIndex < words.length) {
      _speak(words[_currentIndex].word);
    }
  }

  void _checkAnswer(VocabularyItem currentWord) {
    if (_isAnswerChecked) return;

    final input = _inputController.text.trim();
    final match = HangulHelper.isSpellingMatch(input, currentWord.word);

    setState(() {
      _isAnswerChecked = true;
      _isCorrect = match;
      if (match) {
        _score++;
      } else {
        _wrongWords.add(currentWord);
      }
    });

    _speak(currentWord.word);
  }

  void _nextWord(int totalLength) {
    if (_currentIndex + 1 < totalLength) {
      setState(() {
        _currentIndex++;
        _inputController.clear();
        _showHint = false;
        _isAnswerChecked = false;
        _isCorrect = false;
      });
      _playCurrentWord();
      _focusNode.requestFocus();
    } else {
      _showResultDialog(totalLength);
    }
  }

  void _skipWord(VocabularyItem currentWord, int totalLength) {
    if (_isAnswerChecked) return;
    setState(() {
      _isAnswerChecked = true;
      _isCorrect = false;
      _wrongWords.add(currentWord);
    });
    _speak(currentWord.word);
  }

  void _showResultDialog(int total) {
    final percentage = (total > 0 ? (_score / total * 100) : 0).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.blueAccent, size: 28),
            SizedBox(width: 8),
            Text('받아쓰기 완료!', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
              '총 $total단어 중 $_score단어 맞춤',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (_wrongWords.isNotEmpty) ...[
              const Divider(height: 24),
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
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _wrongWords.clear();
                _inputController.clear();
                _showHint = false;
                _isAnswerChecked = false;
              });
              _playCurrentWord();
              _focusNode.requestFocus();
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
        title: Text('${widget.source.title} 받아쓰기'),
      ),
      body: wordsAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('학습할 단어가 부족합니다.'));
          }

          final currentWord = words[_currentIndex];
          final progress = (_currentIndex + 1) / words.length;
          final initials = HangulHelper.getInitials(currentWord.word);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Progress header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '단어 ${_currentIndex + 1} / ${words.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mintDark,
                        ),
                      ),
                      Text(
                        '정답: $_score',
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

                  // Audio Play Card
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
                      children: [
                        const Text(
                          '발음을 잘 듣고 정확한 철자를 입력하세요',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        // Big Speaker Button
                        InkWell(
                          onTap: () => _speak(currentWord.word),
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.mint.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.volume_up,
                              size: 38,
                              color: AppColors.mintDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '터치하여 다시 듣기',
                          style: TextStyle(fontSize: 11, color: AppColors.mintDark, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        // Meaning Hint
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '뜻: ${currentWord.meaningKo}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        // Consonant Hint
                        if (_showHint) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '초성 힌트: $initials (${currentWord.word.length}글자)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Text Input
                  TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    enabled: !_isAnswerChecked,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: '한국어 단어 입력',
                      hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 0),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.mintDark, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _checkAnswer(currentWord),
                  ),

                  const SizedBox(height: 12),

                  // Hint and Skip buttons (before checking)
                  if (!_isAnswerChecked)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _showHint = !_showHint),
                          icon: Icon(_showHint ? Icons.lightbulb : Icons.lightbulb_outline, size: 18),
                          label: Text(_showHint ? '힌트 숨기기' : '초성 힌트 보기'),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => _skipWord(currentWord, words.length),
                          child: const Text('모르겠어요 (건너뛰기)', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ],
                    ),

                  // Feedback Banner (after checking)
                  if (_isAnswerChecked) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.cancel,
                            color: _isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isCorrect ? '정답입니다! 🎉' : '아쉬워요!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '정답 철자: ${currentWord.word}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Bottom Button: Check Answer or Next Word
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isAnswerChecked
                          ? () => _nextWord(words.length)
                          : () => _checkAnswer(currentWord),
                      style: FilledButton.styleFrom(
                        backgroundColor: _isAnswerChecked
                            ? (_isCorrect ? const Color(0xFF16A34A) : AppColors.mintDark)
                            : AppColors.mintDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _isAnswerChecked
                            ? (_currentIndex + 1 < words.length ? '다음 단어' : '결과 확인')
                            : '정답 확인',
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
