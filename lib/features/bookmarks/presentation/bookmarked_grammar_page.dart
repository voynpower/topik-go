import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/domain/user_grammar_service.dart';
import 'package:topik_go/features/grammar/presentation/ai_grammar_sheet.dart';

class BookmarkedGrammarPage extends ConsumerWidget {
  const BookmarkedGrammarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final grammarAsync = ref.watch(bookmarkedGrammarProvider);
    final userSavedItems = ref.watch(userGrammarProvider).toGrammarItems();

    final allItems = <GrammarItem>[...userSavedItems];
    final seen = <String>{...userSavedItems.map((g) => g.pattern)};

    grammarAsync.whenData((serverItems) {
      for (final item in serverItems) {
        if (seen.add(item.grammar.pattern)) {
          allItems.add(item.grammar);
        }
      }
    });

    if (allItems.isEmpty && grammarAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.bookmarkedGrammar)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (allItems.isEmpty && grammarAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.bookmarkedGrammar)),
        body: _ErrorState(
          message: apiErrorMessage(
            grammarAsync.error!,
            missingApiMessage: strings.error,
          ),
          retryText: strings.retry,
          onRetry: () => ref.invalidate(bookmarkedGrammarProvider),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.bookmarkedGrammar)),
      body: allItems.isEmpty
          ? Center(child: Text(strings.noBookmarks))
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(bookmarkedGrammarProvider);
                ref.invalidate(bookmarkSummaryProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  return _GrammarTile(item: allItems[index]);
                },
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.pattern,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 16),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        onTap: () => showAiGrammarSheet(context, selectedText: item.pattern),
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
