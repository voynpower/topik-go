import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/ai_sentence_service.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_mastery_service.dart';

class VocaWordCard extends ConsumerStatefulWidget {
  const VocaWordCard({
    super.key,
    required this.item,
    required this.strings,
  });

  final VocabularyItem item;
  final AppStrings strings;

  @override
  ConsumerState<VocaWordCard> createState() => _VocaWordCardState();
}

class _VocaWordCardState extends ConsumerState<VocaWordCard> {
  bool _isExpanded = false;
  int _exampleIndex = 0;
  bool _showTranslation = true;
  bool _savingBookmark = false;
  FlutterTts? _tts;

  void _speak(String text) async {
    _tts ??= FlutterTts()
      ..setLanguage('ko-KR')
      ..setSpeechRate(0.45);
    await _tts?.stop();
    await _tts?.speak(text);
  }

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }

  Color _getStatusColor(WordMasteryStatus status) {
    switch (status) {
      case WordMasteryStatus.unseen:
      case WordMasteryStatus.hard:
        return const Color(0xFFEF4444); // 🔴
      case WordMasteryStatus.unsure:
        return const Color(0xFFF59E0B); // 🟡
      case WordMasteryStatus.mastered:
        return const Color(0xFF10B981); // 🟢
    }
  }

  String _getStatusLabel(WordMasteryStatus status, AppStrings strings) {
    switch (status) {
      case WordMasteryStatus.unseen:
      case WordMasteryStatus.hard:
        return strings.statusHard;
      case WordMasteryStatus.unsure:
        return strings.statusUnsure;
      case WordMasteryStatus.mastered:
        return strings.statusMastered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final strings = widget.strings;
    final currentLang = ref.watch(currentLanguageProvider);
    final masteryMap = ref.watch(wordMasteryProvider);
    final status = masteryMap[item.id] ?? WordMasteryStatus.hard;
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D), // OneVoca 스타일 딥 다크 카드
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded ? const Color(0xFF6366F1).withValues(alpha: 0.5) : const Color(0xFF2D3342),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Card Top Bar & Word
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge & More Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Badge (Cycle on tap!)
                      InkWell(
                        onTap: () => ref.read(wordMasteryProvider.notifier).cycleStatus(item.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusLabel(status, strings),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Level Tag or Details
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF333B4F),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TOPIK ${item.level}급',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => context.push('/vocabulary/${item.id}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Large Word Title
                  Text(
                    item.word,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Meaning Preview
                  Text(
                    item.meaningUserLang ?? item.meaningKo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons Row (Star / Study / Speaker)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bookmark Star
                      IconButton(
                        icon: Icon(
                          item.isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: item.isBookmarked ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                          size: 24,
                        ),
                        onPressed: _savingBookmark
                            ? null
                            : () async {
                                setState(() => _savingBookmark = true);
                                try {
                                  await ref.read(bookmarkRepositoryProvider).setVocabularyBookmark(
                                        vocabularyId: item.id,
                                        bookmarked: !item.isBookmarked,
                                      );
                                  ref.invalidate(vocabularyProvider);
                                  ref.invalidate(bookmarkedVocabularyProvider);
                                  ref.invalidate(bookmarkSummaryProvider);
                                } finally {
                                  if (mounted) setState(() => _savingBookmark = false);
                                }
                              },
                      ),
                      const SizedBox(width: 4),
                      // Flashcard Launcher Icon
                      IconButton(
                        icon: const Icon(Icons.note_add_outlined, color: Color(0xFF64748B), size: 22),
                        onPressed: () => context.push('/vocabulary/flashcard?source=all'),
                      ),
                      const SizedBox(width: 4),
                      // Audio Speaker
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF64748B), size: 22),
                        onPressed: () => _speak(item.word),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Accordion Expanded AI Sentence Box (voca_img1.jpeg)
          if (_isExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF272C3E), // 보라빛 감도는 AI 서브 박스
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3F4660)),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final aiAsync = ref.watch(aiSentenceProvider((
                    word: item.word,
                    index: _exampleIndex,
                    targetLang: currentLang,
                    predefinedExample: item.example,
                    predefinedMeaning: item.exampleMeaning,
                  )));

                  return aiAsync.when(
                    data: (sentence) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI Badge & Context Tag
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('✨', style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Text(
                                      strings.aiExample,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sentence.contextTag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Korean Example Sentence (Bold)
                          Text(
                            sentence.korean,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Translated Sentence
                          if (_showTranslation)
                            Text(
                              sentence.translation,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFCBD5E1),
                                height: 1.35,
                              ),
                            ),
                          const SizedBox(height: 14),

                          // Sub Action Controls (Chips & Other Example Button)
                          Row(
                            children: [
                              // Translation Toggle Chip
                              InkWell(
                                onTap: () => setState(() => _showTranslation = !_showTranslation),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _showTranslation ? const Color(0xFF3B4257) : const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _showTranslation ? '번역 끄기' : '번역 켜기',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // See Other Examples Button (AI Re-generate)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _exampleIndex++;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B4257),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        strings.seeOtherExamples,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.refresh, size: 13, color: Colors.white70),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Sentence Speaker
                              IconButton(
                                icon: const Icon(Icons.volume_up_outlined, color: Colors.white70, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _speak(sentence.korean),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2),
                      ),
                    ),
                    error: (_, _) => Text(
                      item.example ?? '예문을 불러올 수 없습니다.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
