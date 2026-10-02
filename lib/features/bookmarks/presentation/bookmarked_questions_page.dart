import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';

class BookmarkedQuestionsPage extends ConsumerWidget {
  const BookmarkedQuestionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final bookmarks = ref.watch(bookmarkedQuestionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          strings.bookmarkedQuestions,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: bookmarks.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF1DC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        size: 40,
                        color: Color(0xFFD07A21),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.noBookmarks,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '연습이나 모의고사에서 헷갈리는 문제를 저장해두고 시험 전에 집중 복습해 보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookmarkedQuestionsProvider);
              ref.invalidate(bookmarkSummaryProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _ReviewQuestionTile(item: items[index], strings: strings);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mintDark),
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          retryText: strings.retry,
          onRetry: () => ref.invalidate(bookmarkedQuestionsProvider),
        ),
      ),
    );
  }
}

class _ReviewQuestionTile extends StatelessWidget {
  const _ReviewQuestionTile({required this.item, required this.strings});

  final BookmarkedQuestion item;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final question = item.question;
    final numberLabel = question.questionNumber > 0
        ? '${question.questionNumber}번'
        : '문제';
    final sectionName = _sectionLabel(question.section, strings);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/questions/${question.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta: Section Badge + Level
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$sectionName $numberLabel',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    if (question.level != null)
                      Text(
                        'TOPIK ${question.level}급',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Question Prompt
                Text(
                  question.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Footer Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (question.questionType.isNotEmpty)
                      Text(
                        question.questionType,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: const [
                        Text(
                          '다시 풀기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mintDark,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 18, color: AppColors.mintDark),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sectionLabel(String section, AppStrings strings) {
    switch (section.toLowerCase()) {
      case 'reading':
        return strings.readingPractice;
      case 'listening':
        return strings.listeningPractice;
      case 'writing':
        return strings.writingPractice;
      default:
        return section;
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryText,
    required this.onRetry,
  });

  final String message;
  final String retryText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.mintDark),
              onPressed: onRetry,
              child: Text(retryText),
            ),
          ],
        ),
      ),
    );
  }
}
