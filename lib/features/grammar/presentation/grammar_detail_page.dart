import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';

class GrammarDetailPage extends ConsumerStatefulWidget {
  const GrammarDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<GrammarDetailPage> createState() => _GrammarDetailPageState();
}

class _GrammarDetailPageState extends ConsumerState<GrammarDetailPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final item = ref.watch(grammarItemProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(strings.grammarDetail)),
      body: item.when(
        data: (grammar) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grammar.pattern,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      grammar.description,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(height: 1.45),
                    ),
                    if (grammar.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: grammar.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (grammar.examples.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(strings.examples, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...grammar.examples.map(
                (example) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(example),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () => _toggleBookmark(
                      grammar.id,
                      bookmarked: !grammar.isBookmarked,
                    ),
              icon: Icon(
                grammar.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_add_outlined,
              ),
              label: Text(grammar.isBookmarked ? strings.savedToGrammar : strings.addToGrammar),
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
          onRetry: () => ref.invalidate(grammarItemProvider(widget.id)),
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(String id, {required bool bookmarked}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(grammarRepositoryProvider)
          .setGrammarBookmark(id: id, bookmarked: bookmarked);
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedGrammarProvider);
      ref.invalidate(grammarItemProvider(widget.id));
      final strings = ref.read(appStringsProvider);
      _showMessage(bookmarked ? strings.savedToGrammar : strings.delete);
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
