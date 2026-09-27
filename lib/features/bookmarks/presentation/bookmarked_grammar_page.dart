import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';

class BookmarkedGrammarPage extends ConsumerWidget {
  const BookmarkedGrammarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final grammar = ref.watch(bookmarkedGrammarProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.bookmarkedGrammar)),
      body: grammar.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(strings.noBookmarks));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookmarkedGrammarProvider);
              ref.invalidate(bookmarkSummaryProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _GrammarTile(item: items[index].grammar);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: apiErrorMessage(
            error,
            missingApiMessage: strings.error,
          ),
          retryText: strings.retry,
          onRetry: () => ref.invalidate(bookmarkedGrammarProvider),
        ),
      ),
    );
  }
}

class _GrammarTile extends StatelessWidget {
  const _GrammarTile({required this.item});

  final GrammarItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          item.pattern,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/grammar/${item.id}'),
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
