import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
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
  bool _showMeaning = false; // 문제 2: 처음에는 번역을 숨기고 단어를 눌러야 표시
  bool _isAiExpanded = false; // 문제 3: AI 아이콘 버튼을 눌러야 AI 예문 표시
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

  Color _getStatusBgColor(WordMasteryStatus status) {
    switch (status) {
      case WordMasteryStatus.unseen:
      case WordMasteryStatus.hard:
        return const Color(0xFFFEE2E2);
      case WordMasteryStatus.unsure:
        return const Color(0xFFFEF3C7);
      case WordMasteryStatus.mastered:
        return const Color(0xFFDCFCE7);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isAiExpanded ? AppColors.mintDark : const Color(0xFFE2E8F0),
          width: _isAiExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Card Content Area
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge & More Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge (Cycle on tap)
                    InkWell(
                      onTap: () => ref.read(wordMasteryProvider.notifier).cycleStatus(item.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(status),
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
                    // Level Tag & Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TOPIK ${strings.levelUnit.replaceAll('{level}', '${item.level}')}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8), size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => context.push('/vocabulary/${item.id}'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Large Word Title & Toggle Meaning Area (문제 2: 단어 누르면 뜻 표시)
                InkWell(
                  onTap: () => setState(() => _showMeaning = !_showMeaning),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.word,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Meaning Preview or Tap to Reveal
                        if (_showMeaning)
                          Text(
                            item.meaningUserLang ?? item.meaningKo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mintDark,
                              height: 1.3,
                            ),
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                strings.tapToViewMeaning,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Action Buttons Row (문제 3: 플래시카드 아이콘 대신 AI 아이콘 버튼!)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bookmark Star
                    IconButton(
                      icon: Icon(
                        item.isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: item.isBookmarked ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
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

                    // AI Example Toggle Button (문제 3)
                    IconButton(
                      tooltip: strings.aiExample,
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _isAiExpanded
                              ? AppColors.mintDark.withValues(alpha: 0.15)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isAiExpanded ? AppColors.mintDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: _isAiExpanded ? AppColors.mintDark : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                      onPressed: () => setState(() => _isAiExpanded = !_isAiExpanded),
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

          // 2. Accordion Expanded AI Sentence Box (문제 1: 라이트 디자인)
          if (_isAiExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // 부드럽고 가독성 높은 연녹/민트 배경
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
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
                                  color: AppColors.mintDark,
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
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Korean Example Sentence (Bold, Dark)
                          Text(
                            sentence.korean,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
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
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                          const SizedBox(height: 14),

                          // Sub Action Controls
                          Row(
                            children: [
                              // Translation Toggle Chip
                              InkWell(
                                onTap: () => setState(() => _showTranslation = !_showTranslation),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _showTranslation ? const Color(0xFFE2E8F0) : AppColors.mintDark,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _showTranslation ? strings.hideTranslation : strings.showTranslation,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _showTranslation ? const Color(0xFF334155) : Colors.white,
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
                                    color: const Color(0xFFE2E8F0),
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
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.refresh, size: 13, color: Color(0xFF475569)),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Sentence Speaker
                              IconButton(
                                icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF64748B), size: 20),
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
                        child: CircularProgressIndicator(color: AppColors.mintDark, strokeWidth: 2),
                      ),
                    ),
                    error: (_, _) => Text(
                      item.example ?? '예문을 불러올 수 없습니다.',
                      style: const TextStyle(color: Color(0xFF64748B)),
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
