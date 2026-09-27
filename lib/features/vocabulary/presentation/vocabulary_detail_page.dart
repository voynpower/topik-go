import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

class VocabularyDetailPage extends ConsumerStatefulWidget {
  const VocabularyDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<VocabularyDetailPage> createState() =>
      _VocabularyDetailPageState();
}

class _VocabularyDetailPageState extends ConsumerState<VocabularyDetailPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final item = ref.watch(vocabularyItemProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(strings.smartWordbook)),
      body: item.when(
        data: (vocabulary) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            vocabulary.word,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vocabulary.meaningKo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (vocabulary.partOfSpeech?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Chip(label: Text(vocabulary.partOfSpeech!)),
                    ],
                    if (vocabulary.meaningUserLang?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        vocabulary.meaningUserLang!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (vocabulary.example?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              _StudyCard(
                title: strings.examples,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vocabulary.example!,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(height: 1.45),
                    ),
                    if (vocabulary.exampleMeaning?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        vocabulary.exampleMeaning!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () => _toggleBookmark(
                      vocabulary.id,
                      bookmarked: !vocabulary.isBookmarked,
                    ),
              icon: Icon(
                vocabulary.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_add_outlined,
              ),
              label: Text(vocabulary.isBookmarked ? strings.savedToVocabulary : strings.addToVocabulary),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: apiErrorMessage(
            error,
            missingApiMessage: strings.error,
          ),
          retryText: strings.retry,
          onRetry: () => ref.invalidate(vocabularyItemProvider(widget.id)),
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(String id, {required bool bookmarked}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(vocabularyRepositoryProvider)
          .setVocabularyBookmark(id: id, bookmarked: bookmarked);
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedVocabularyProvider);
      ref.invalidate(vocabularyItemProvider(widget.id));
      final strings = ref.read(appStringsProvider);
      _showMessage(bookmarked ? strings.savedToVocabulary : strings.delete);
    } catch (error) {
      _showMessage(apiErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
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
