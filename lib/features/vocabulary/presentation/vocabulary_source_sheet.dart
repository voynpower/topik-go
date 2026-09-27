import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';

class VocabularySourceSheet extends ConsumerWidget {
  const VocabularySourceSheet({
    super.key,
    required this.mode,
  });

  final VocabularyStudyMode mode;

  static void show(BuildContext context, VocabularyStudyMode mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VocabularySourceSheet(mode: mode),
    );
  }

  String _getModeTitle(AppStrings strings) {
    switch (mode) {
      case VocabularyStudyMode.flashcard:
        return strings.flashcard;
      case VocabularyStudyMode.quiz:
        return strings.quiz;
      case VocabularyStudyMode.dictation:
        return strings.dictation;
      case VocabularyStudyMode.autoplay:
        return strings.autoplay;
    }
  }

  String get _routePath {
    switch (mode) {
      case VocabularyStudyMode.flashcard:
        return '/vocabulary/flashcard';
      case VocabularyStudyMode.quiz:
        return '/vocabulary/quiz';
      case VocabularyStudyMode.dictation:
        return '/vocabulary/dictation';
      case VocabularyStudyMode.autoplay:
        return '/vocabulary/autoplay';
    }
  }

  void _startStudy(BuildContext context, StudyWordSource source) {
    Navigator.of(context).pop();
    final queryParams = <String, String>{};
    if (source.type == StudyWordSourceType.saved) {
      queryParams['source'] = 'saved';
    } else {
      queryParams['source'] = 'all';
    }
    context.push(
      Uri(path: _routePath, queryParameters: queryParams).toString(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final bookmarksAsync = ref.watch(bookmarkedVocabularyProvider);
    final savedCount = bookmarksAsync.asData?.value.length ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: AppColors.mintDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getModeTitle(strings),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.studySourceSheetTitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Option 1: Saved Words
          Material(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _startStudy(context, const StudyWordSource.saved()),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                strings.mySavedWordbook,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  strings.wordsSavedCount.replaceAll('{count}', '$savedCount'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.mySavedWordbookDesc,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF15803D)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Option 2: All TOPIK vocabulary
          InkWell(
            onTap: () => _startStudy(context, const StudyWordSource.all()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mintDark.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.mintDark, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.allTopikVocab,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.allTopikVocabDesc,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mintDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
