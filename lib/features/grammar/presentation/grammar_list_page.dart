import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';

class GrammarListPage extends ConsumerStatefulWidget {
  const GrammarListPage({super.key});

  @override
  ConsumerState<GrammarListPage> createState() => _GrammarListPageState();
}

class _GrammarListPageState extends ConsumerState<GrammarListPage> {
  final _searchController = TextEditingController();
  int _page = 1;

  GrammarQuery get _query {
    return GrammarQuery(
      q: _searchController.text,
      page: _page,
      limit: 20,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final grammar = ref.watch(grammarProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(strings.grammarStudy)),
      body: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: strings.searchGrammarHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _page = 1);
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onSubmitted: (_) => setState(() => _page = 1),
              ),
            ),
          ),
          Expanded(
            child: grammar.when(
              data: (page) => _GrammarList(
                page: page,
                query: _query,
                strings: strings,
                onPrevious: page.page > 1
                    ? () => setState(() => _page = _page - 1)
                    : null,
                onNext: page.page * page.limit < page.total
                    ? () => setState(() => _page = _page + 1)
                    : null,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: apiErrorMessage(
                  error,
                  missingApiMessage: strings.error,
                ),
                retryText: strings.retry,
                onRetry: () => ref.invalidate(grammarProvider(_query)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarList extends StatelessWidget {
  const _GrammarList({
    required this.page,
    required this.query,
    required this.strings,
    required this.onPrevious,
    required this.onNext,
  });

  final GrammarPage page;
  final GrammarQuery query;
  final AppStrings strings;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return Center(child: Text(strings.noBookmarks));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '총 ${page.total}개',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(
              '${page.page} 페이지',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...page.items.map((item) => _GrammarTile(item: item, query: query, strings: strings)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                child: Text(strings.prev),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${page.page}'),
            ),
            Expanded(
              child: OutlinedButton(onPressed: onNext, child: Text(strings.next)),
            ),
          ],
        ),
      ],
    );
  }
}

class _GrammarTile extends ConsumerStatefulWidget {
  const _GrammarTile({required this.item, required this.query, required this.strings});

  final GrammarItem item;
  final GrammarQuery query;
  final AppStrings strings;

  @override
  ConsumerState<_GrammarTile> createState() => _GrammarTileState();
}

class _GrammarTileState extends ConsumerState<_GrammarTile> {
  bool _savingBookmark = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final strings = widget.strings;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/grammar/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.pattern,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in item.tags.take(3))
                            _SmallBadge(text: tag),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: item.isBookmarked ? strings.bookmarked : strings.bookmark,
                onPressed: _savingBookmark ? null : () => _toggleBookmark(item),
                icon: Icon(
                  item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: item.isBookmarked ? Colors.orange : Colors.grey,
                ),
              ),
              Icon(
                item.isDownloaded ? Icons.download_done : Icons.chevron_right,
                color: item.isDownloaded ? AppColors.mintDark : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(GrammarItem item) async {
    setState(() => _savingBookmark = true);
    try {
      await ref
          .read(grammarRepositoryProvider)
          .setGrammarBookmark(id: item.id, bookmarked: !item.isBookmarked);
      ref.invalidate(grammarProvider(widget.query));
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedGrammarProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _savingBookmark = false);
    }
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.mintDark,
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
