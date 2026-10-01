import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/domain/user_grammar_service.dart';

class GrammarSourceSheet extends ConsumerWidget {
  const GrammarSourceSheet({
    super.key,
    required this.mode,
  });

  final GrammarStudyMode mode;

  static void show(BuildContext context, GrammarStudyMode mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GrammarSourceSheet(mode: mode),
    );
  }

  String _getModeTitle(AppStrings strings) {
    switch (mode) {
      case GrammarStudyMode.flashcard:
        return strings.grammarFlashcard;
      case GrammarStudyMode.quiz:
        return strings.grammarQuiz;
    }
  }

  String get _routePath {
    switch (mode) {
      case GrammarStudyMode.flashcard:
        return '/grammar/flashcard';
      case GrammarStudyMode.quiz:
        return '/grammar/quiz';
    }
  }

  void _startStudy(BuildContext context, GrammarStudySource source) {
    Navigator.of(context).pop();
    final queryParams = <String, String>{};
    if (source.type == GrammarSourceType.saved) {
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
    final bookmarksAsync = ref.watch(bookmarkedGrammarProvider);
    final userSavedGrammars = ref.watch(userGrammarProvider).savedGrammars;
    final bookmarksList = bookmarksAsync.asData?.value ?? [];
    final uniquePatterns = <String>{
      ...userSavedGrammars.map((g) => g.pattern),
      ...bookmarksList.map((b) => b.grammar.pattern),
    };
    final savedCount = uniquePatterns.length;

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
                  color: const Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_alt_outlined,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getModeTitle(strings),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Option 1: Saved Grammar Bookmarks
          _SourceOptionCard(
            title: strings.mySavedGrammarbook,
            subtitle: strings.mySavedGrammarbookDesc,
            countBadge: strings.wordsSavedCount.replaceAll('{count}', '$savedCount'),
            icon: Icons.bookmark_rounded,
            iconColor: const Color(0xFFD07A21),
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFFEDD5),
            enabled: savedCount > 0,
            onTap: () => _startStudy(context, const GrammarStudySource.saved()),
          ),
          const SizedBox(height: 12),

          // Option 2: All Grammar List
          _SourceOptionCard(
            title: strings.allTopikGrammar,
            subtitle: strings.allTopikGrammarDesc,
            countBadge: strings.all,
            icon: Icons.auto_stories_rounded,
            iconColor: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFFBFBFE),
            borderColor: const Color(0xFFE2E8F0),
            enabled: true,
            onTap: () => _startStudy(context, const GrammarStudySource.all()),
          ),
        ],
      ),
    );
  }
}

class _SourceOptionCard extends StatelessWidget {
  const _SourceOptionCard({
    required this.title,
    required this.subtitle,
    required this.countBadge,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String countBadge;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? bgColor : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled ? borderColor : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled ? iconColor : Colors.black26,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: enabled ? const Color(0xFF0F172A) : Colors.black38,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: enabled
                                ? iconColor.withValues(alpha: 0.12)
                                : Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            countBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: enabled ? iconColor : Colors.black38,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? const Color(0xFF64748B) : Colors.black26,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: enabled ? AppColors.textSecondary : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
