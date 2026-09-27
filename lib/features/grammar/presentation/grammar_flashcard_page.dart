import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';

class GrammarFlashcardPage extends ConsumerStatefulWidget {
  const GrammarFlashcardPage({
    super.key,
    required this.source,
  });

  final GrammarStudySource source;

  @override
  ConsumerState<GrammarFlashcardPage> createState() =>
      _GrammarFlashcardPageState();
}

class _GrammarFlashcardPageState
    extends ConsumerState<GrammarFlashcardPage>
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
    _tts = FlutterTts()
      ..setLanguage('ko-KR')
      ..setSpeechRate(0.45);

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

  void _onAnswer(GrammarItem item, bool isMastered, int totalLength) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Color(0xFF7C3AED), size: 28),
            const SizedBox(width: 8),
            Text(strings.finishStudy),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${strings.grammarCount.replaceAll('{count}', '$total')} ${strings.completed}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 6),
                Text('${strings.memorized}: ${_masteredIds.length}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.replay, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Text('${strings.needReview}: ${_reviewIds.length}'),
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
            child: Text(strings.confirm),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (_isBack) {
                _flipController.reverse();
                _isBack = false;
              }
              setState(() {
                _currentIndex = 0;
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
    final grammarAsync = ref.watch(studyGrammarProvider(widget.source));

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.grammarFlashcard),
        actions: [
          grammarAsync.when(
            data: (items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${items.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: grammarAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology_alt_outlined, size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  Text(
                    strings.noBookmarks,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          final currentItem = items[_currentIndex];

          return Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / items.length,
                backgroundColor: const Color(0xFFEDE9FE),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                minHeight: 4,
              ),

              // Card Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _flipCard,
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
                          child: isUnderHalf
                              ? _GrammarCardFront(
                                  item: currentItem,
                                  strings: strings,
                                  onSpeak: _speak,
                                )
                              : Transform(
                                  transform: Matrix4.identity()..rotateY(pi),
                                  alignment: Alignment.center,
                                  child: _GrammarCardBack(
                                    item: currentItem,
                                    strings: strings,
                                    onSpeak: _speak,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          foregroundColor: const Color(0xFFEA580C),
                          side: const BorderSide(color: Color(0xFFFED7AA), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _onAnswer(currentItem, false, items.length),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.replay_rounded, size: 20),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.needReview,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          backgroundColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _onAnswer(currentItem, true, items.length),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.memorized,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

class _GrammarCardFront extends StatelessWidget {
  const _GrammarCardFront({
    required this.item,
    required this.strings,
    required this.onSpeak,
  });

  final GrammarItem item;
  final AppStrings strings;
  final void Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    final firstExample = item.examples.isNotEmpty ? item.examples.first : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Tags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.tags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.tags.first,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              IconButton(
                onPressed: () => onSpeak(item.pattern),
                icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF7C3AED)),
              ),
            ],
          ),

          // Center Grammar Pattern
          Column(
            children: [
              Text(
                item.pattern,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              if (firstExample.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          firstExample,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Bottom Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_outlined, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  strings.flipCardHint,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrammarCardBack extends StatelessWidget {
  const _GrammarCardBack({
    required this.item,
    required this.strings,
    required this.onSpeak,
  });

  final GrammarItem item;
  final AppStrings strings;
  final void Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: ListView(
        children: [
          // Header Pattern
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.pattern,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onSpeak(item.pattern),
                icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF7C3AED)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Text(
              item.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Examples
          if (item.examples.isNotEmpty) ...[
            Text(
              strings.examples,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            ...item.examples.map(
              (ex) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ex,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => onSpeak(ex),
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.volume_up_outlined,
                            size: 16,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
