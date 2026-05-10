import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

class BookmarkedVocabularyPage extends ConsumerWidget {
  const BookmarkedVocabularyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = ref.watch(bookmarkedVocabularyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('북마크 단어')),
      body: vocabulary.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('북마크한 단어가 없습니다.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookmarkedVocabularyProvider);
              ref.invalidate(bookmarkSummaryProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _VocabularyTile(item: items[index].vocabulary);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: apiErrorMessage(
            error,
            missingApiMessage: '북마크 단어 API가 아직 백엔드에 연결되지 않았습니다.',
          ),
          onRetry: () => ref.invalidate(bookmarkedVocabularyProvider),
        ),
      ),
    );
  }
}

class _VocabularyTile extends StatelessWidget {
  const _VocabularyTile({required this.item});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          item.word,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('${item.level}급 / ${item.meaningKo}'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/vocabulary/${item.id}'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
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
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
