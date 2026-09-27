import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(title: Text(strings.bookmarkedQuestions)),
      body: bookmarks.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(strings.noBookmarks));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookmarkedQuestionsProvider);
              ref.invalidate(bookmarkSummaryProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _BookmarkedQuestionTile(item: items[index], strings: strings);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          retryText: strings.retry,
          onRetry: () => ref.invalidate(bookmarkedQuestionsProvider),
        ),
      ),
    );
  }
}

class _BookmarkedQuestionTile extends StatelessWidget {
  const _BookmarkedQuestionTile({required this.item, required this.strings});

  final BookmarkedQuestion item;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final question = item.question;
    final numberLabel = question.questionNumber > 0
        ? '${question.questionNumber}번'
        : '문제';
    final levelLabel = question.level == null ? '' : ' / ${question.level}급';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          '$numberLabel ${question.prompt}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${_sectionLabel(question.section, strings)}$levelLabel / ${question.questionType}',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/questions/${question.id}'),
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
            FilledButton(onPressed: onRetry, child: Text(retryText)),
          ],
        ),
      ),
    );
  }
}
