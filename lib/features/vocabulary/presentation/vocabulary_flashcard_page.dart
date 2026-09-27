import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';

class VocabularyFlashcardPage extends ConsumerStatefulWidget {
  const VocabularyFlashcardPage({
    super.key,
    required this.source,
  });

  final StudyWordSource source;

  @override
  ConsumerState<VocabularyFlashcardPage> createState() =>
      _VocabularyFlashcardPageState();
}

class _VocabularyFlashcardPageState
    extends ConsumerState<VocabularyFlashcardPage>
    with SingleTickerProviderStateMixin {
  late final FlutterTts _tts;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  int _currentIndex = 0;
  bool _isBack = false;
  final Set<String> _masteredIds = {};
  final Set<String> _reviewIds = {};

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('ko-KR');
    _tts.setSpeechRate(0.45);

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    if (_isBack) {
      _flipController.reverse();
      setState(() => _isBack = false);
    } else {
      _flipController.forward();
      setState(() => _isBack = true);
    }
  }

  void _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  void _onAnswer(VocabularyItem item, bool isMastered, int totalLength) {
    if (isMastered) {
      _masteredIds.add(item.id);
      _reviewIds.remove(item.id);
    } else {
      _reviewIds.add(item.id);
    }

    if (_currentIndex + 1 < totalLength) {
      if (_isBack) {
        _flipController.reverse();
        _isBack = false;
      }
      setState(() {
        _currentIndex++;
      });
      // Automatically speak the next word
      final wordsAsync = ref.read(studyWordsProvider(widget.source));
      final nextWord = wordsAsync.asData?.value[_currentIndex];
      if (nextWord != null) {
        _speak(nextWord.word);
      }
    } else {
      _showCompletionDialog(totalLength);
    }
  }

  void _showCompletionDialog(int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('플래시카드 완료!', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('총 $total개 단어 학습을 완료했습니다.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('외웠어요', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '${_masteredIds.length}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 32, color: Colors.black12),
                  Column(
                    children: [
                      const Text('복습 필요', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '${_reviewIds.length}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('학습 종료'),
          ),
          if (_reviewIds.isNotEmpty)
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _currentIndex = 0;
                  if (_isBack) {
                    _flipController.reverse();
                    _isBack = false;
                  }
                });
              },
              child: const Text('다시 학습'),
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
        title: Text(widget.source.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '처음부터 다시하기',
            onPressed: () {
              setState(() {
                _currentIndex = 0;
                if (_isBack) {
                  _flipController.reverse();
                  _isBack = false;
                }
              });
            },
          ),
        ],
      ),
      body: wordsAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(
              child: Text(
                '학습할 단어가 없습니다.\n지문에서 모르는 단어를 북마크해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
            );
          }

          final currentWord = words[_currentIndex];
          final progress = (_currentIndex + 1) / words.length;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '단어 ${_currentIndex + 1} / ${words.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '외움 ${_masteredIds.length}개',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mintDark,
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
                  const SizedBox(height: 20),

                  // 3D Flip Card
                  Expanded(
                    child: GestureDetector(
                      onTap: _flipCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * pi;
                          final isUnder = (angle > pi / 2);
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isUnder
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _CardBack(
                                      item: currentWord,
                                      onSpeak: () => _speak(currentWord.word),
                                    ),
                                  )
                                : _CardFront(
                                    item: currentWord,
                                    onSpeak: () => _speak(currentWord.word),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          '카드를 터치하면 뒤집힙니다',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      // Still Reviewing Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onAnswer(currentWord, false, words.length),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text(
                            '아직 몰라요',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Mastered Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _onAnswer(currentWord, true, words.length),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text(
                            '외웠어요!',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
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

class _CardFront extends StatelessWidget {
  const _CardFront({required this.item, required this.onSpeak});

  final VocabularyItem item;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TOPIK 필수 어휘',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mintDark,
                  ),
                ),
              ),
              if (item.partOfSpeech != null && item.partOfSpeech!.isNotEmpty)
                Text(
                  item.partOfSpeech!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            item.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          IconButton.filledTonal(
            onPressed: onSpeak,
            icon: const Icon(Icons.volume_up, size: 24),
            tooltip: '발음 듣기',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.mint.withValues(alpha: 0.15),
              foregroundColor: AppColors.mintDark,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '앞면',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.item, required this.onSpeak});

  final VocabularyItem item;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.word,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mintDark,
                ),
              ),
              IconButton(
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up, size: 20, color: AppColors.mintDark),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Divider(height: 20),
          const Text(
            '한국어 뜻',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            item.meaningKo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
          if (item.meaningUserLang != null && item.meaningUserLang!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '번역 / Translation',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              item.meaningUserLang!,
              style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
            ),
          ],
          if (item.example != null && item.example!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '예문',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.example!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                  if (item.exampleMeaning != null && item.exampleMeaning!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.exampleMeaning!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '뒷면 (해설)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
