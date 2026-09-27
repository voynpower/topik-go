import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_mastery_service.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';
import 'package:topik_go/features/vocabulary/presentation/sheets/voca_study_setup_sheet.dart';

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
  Offset _dragOffset = Offset.zero;
  double _speechRate = 0.45;

  final Set<String> _masteredIds = {};
  final Set<String> _reviewIds = {};

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts()
      ..setLanguage('ko-KR')
      ..setSpeechRate(_speechRate);

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
    await _tts.setSpeechRate(_speechRate);
    await _tts.stop();
    await _tts.speak(text);
  }

  void _setSpeed(double rate) {
    setState(() => _speechRate = rate);
  }

  void _onAnswer(VocabularyItem item, bool isMastered, int totalLength) {
    // Mastery 상태 갱신
    if (isMastered) {
      _masteredIds.add(item.id);
      _reviewIds.remove(item.id);
      ref.read(wordMasteryProvider.notifier).setStatus(item.id, WordMasteryStatus.mastered);
    } else {
      _reviewIds.add(item.id);
      ref.read(wordMasteryProvider.notifier).setStatus(item.id, WordMasteryStatus.hard);
    }

    if (_currentIndex + 1 < totalLength) {
      if (_isBack) {
        _flipController.reverse();
        _isBack = false;
      }
      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
      });

      // Speak next word
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
    final strings = ref.read(appStringsProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Color(0xFF6366F1), size: 28),
            const SizedBox(width: 8),
            Text(strings.finishStudy, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '총 $total개 단어 학습 완료!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Text('${strings.memorized}: ${_masteredIds.length}개', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.replay, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 8),
                Text('${strings.needReview}: ${_reviewIds.length}개', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: Text(strings.confirm, style: const TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (_isBack) {
                _flipController.reverse();
                _isBack = false;
              }
              setState(() {
                _currentIndex = 0;
                _dragOffset = Offset.zero;
                _masteredIds.clear();
                _reviewIds.clear();
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
    final wordsAsync = ref.watch(studyWordsProvider(widget.source));

    return Scaffold(
      backgroundColor: const Color(0xFF13161F), // OneVoca 다크 테마
      appBar: AppBar(
        backgroundColor: const Color(0xFF13161F),
        elevation: 0,
        title: wordsAsync.when(
          data: (items) => Text(
            '${_currentIndex + 1} / ${items.length}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => VocaStudySetupSheet.show(context, VocabularyStudyMode.flashcard),
          ),
        ],
      ),
      body: wordsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(strings.noBookmarks, style: const TextStyle(color: Colors.white54)),
            );
          }

          final currentItem = items[_currentIndex];
          final dragX = _dragOffset.dx;
          final rotateAngle = (dragX / 300) * 0.15;
          final isSwipeRight = dragX > 40;
          final isSwipeLeft = dragX < -40;

          return Column(
            children: [
              // 1. Top Progress Indicator
              LinearProgressIndicator(
                value: (_currentIndex + 1) / items.length,
                backgroundColor: const Color(0xFF1E222D),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                minHeight: 4,
              ),

              // 2. Tinder-style Swipe Flashcard Stack (voca_img2, voca_img3, voca_img4)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: GestureDetector(
                    onTap: _flipCard,
                    onPanUpdate: (details) {
                      setState(() {
                        _dragOffset += details.delta;
                      });
                    },
                    onPanEnd: (details) {
                      if (_dragOffset.dx > 120) {
                        _onAnswer(currentItem, true, items.length);
                      } else if (_dragOffset.dx < -120) {
                        _onAnswer(currentItem, false, items.length);
                      } else {
                        setState(() {
                          _dragOffset = Offset.zero;
                        });
                      }
                    },
                    child: Transform.translate(
                      offset: _dragOffset,
                      child: Transform.rotate(
                        angle: rotateAngle,
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle = _flipAnimation.value * pi;
                            final isUnderHalf = _flipAnimation.value < 0.5;

                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                              alignment: Alignment.center,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E222D),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSwipeRight
                                        ? const Color(0xFF10B981) // 초록 테두리 (외웠어요)
                                        : isSwipeLeft
                                            ? const Color(0xFFEF4444) // 빨간 테두리 (아직 외우고 있어요)
                                            : const Color(0xFF2D3342),
                                    width: (isSwipeRight || isSwipeLeft) ? 2.5 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Main Card Content
                                    isUnderHalf
                                        ? _CardFront(
                                            item: currentItem,
                                            speechRate: _speechRate,
                                            onSpeedChange: _setSpeed,
                                            onSpeak: _speak,
                                          )
                                        : Transform(
                                            transform: Matrix4.identity()..rotateY(pi),
                                            alignment: Alignment.center,
                                            child: _CardBack(
                                              item: currentItem,
                                              strings: strings,
                                              speechRate: _speechRate,
                                              onSpeedChange: _setSpeed,
                                              onSpeak: _speak,
                                            ),
                                          ),

                                    // Swipe Overlay Labels (voca_img2 & voca_img3)
                                    if (isSwipeRight)
                                      Positioned(
                                        right: 30,
                                        top: 30,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFF10B981), width: 2),
                                          ),
                                          child: Text(
                                            strings.statusMastered,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (isSwipeLeft)
                                      Positioned(
                                        left: 30,
                                        top: 30,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFEF4444), width: 2),
                                          ),
                                          child: Text(
                                            strings.statusHard,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Bottom One-Touch Buttons (voca_img2, voca_img3, voca_img4)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E1A24),
                          foregroundColor: const Color(0xFFFDA4AF),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xFF4C1D2F)),
                          ),
                        ),
                        onPressed: () => _onAnswer(currentItem, false, items.length),
                        child: Text(
                          '아직 외우고 있어요',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF143026),
                          foregroundColor: const Color(0xFF86EFAC),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xFF1A4736)),
                          ),
                        ),
                        onPressed: () => _onAnswer(currentItem, true, items.length),
                        child: Text(
                          strings.statusMastered,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
        error: (_, _) => Center(child: Text(strings.error, style: const TextStyle(color: Colors.white70))),
      ),
    );
  }
}

class _CardFront extends ConsumerWidget {
  const _CardFront({
    required this.item,
    required this.speechRate,
    required this.onSpeedChange,
    required this.onSpeak,
  });

  final VocabularyItem item;
  final double speechRate;
  final void Function(double) onSpeedChange;
  final void Function(String) onSpeak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Star & Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  item.isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: item.isBookmarked ? const Color(0xFFFBBF24) : Colors.white38,
                  size: 26,
                ),
                onPressed: () async {
                  await ref.read(bookmarkRepositoryProvider).setVocabularyBookmark(
                        vocabularyId: item.id,
                        bookmarked: !item.isBookmarked,
                      );
                  ref.invalidate(vocabularyProvider);
                  ref.invalidate(bookmarkedVocabularyProvider);
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF272C3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TOPIK ${item.level}급',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),

          // Center Giant Word (voca_img4.jpeg)
          Text(
            item.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          // Bottom Accent / Speed Chips & Speaker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _SpeedChip(
                    label: '0.5x',
                    isSelected: speechRate == 0.35,
                    onTap: () => onSpeedChange(0.35),
                  ),
                  const SizedBox(width: 6),
                  _SpeedChip(
                    label: '0.8x',
                    isSelected: speechRate == 0.45,
                    onTap: () => onSpeedChange(0.45),
                  ),
                  const SizedBox(width: 6),
                  _SpeedChip(
                    label: '1.0x',
                    isSelected: speechRate == 0.60,
                    onTap: () => onSpeedChange(0.60),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, color: Colors.white70, size: 24),
                onPressed: () => onSpeak(item.word),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.item,
    required this.strings,
    required this.speechRate,
    required this.onSpeedChange,
    required this.onSpeak,
  });

  final VocabularyItem item;
  final AppStrings strings;
  final double speechRate;
  final void Function(double) onSpeedChange;
  final void Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Word & POS
          Column(
            children: [
              Text(
                item.word,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF818CF8)),
              ),
              const SizedBox(height: 6),
              Text(
                item.meaningUserLang ?? item.meaningKo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),

          // Example Box
          if (item.example != null && item.example!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF272C3E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬 실전 예문', style: TextStyle(fontSize: 11, color: Color(0xFF818CF8), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(item.example!, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.35)),
                  if (item.exampleMeaning != null) ...[
                    const SizedBox(height: 4),
                    Text(item.exampleMeaning!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ],
              ),
            ),

          // Bottom Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.flipCardHint, style: const TextStyle(fontSize: 12, color: Colors.white38)),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, color: Colors.white70, size: 24),
                onPressed: () => onSpeak(item.word),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF272C3E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}
