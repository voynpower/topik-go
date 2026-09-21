import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

class VocabularyListPage extends ConsumerStatefulWidget {
  const VocabularyListPage({super.key});

  @override
  ConsumerState<VocabularyListPage> createState() => _VocabularyListPageState();
}

class _VocabularyListPageState extends ConsumerState<VocabularyListPage> {
  final _searchController = TextEditingController();
  int? _level;
  int _page = 1;

  VocabularyQuery get _query {
    return VocabularyQuery(
      level: _level,
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
    final vocabulary = ref.watch(vocabularyProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('단어장')),
      body: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: '단어 검색',
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
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _LevelChip(
                          label: '전체',
                          selected: _level == null,
                          onTap: () => setState(() {
                            _level = null;
                            _page = 1;
                          }),
                        ),
                        for (final level in const [1, 2, 3, 4, 5, 6])
                          _LevelChip(
                            label: '$level급',
                            selected: _level == level,
                            onTap: () => setState(() {
                              _level = level;
                              _page = 1;
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: vocabulary.when(
              data: (page) => _VocabularyList(
                page: page,
                ref: ref,
                query: _query,
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
                  missingApiMessage: '단어장 API가 아직 백엔드에 연결되지 않았습니다.',
                ),
                onRetry: () => ref.invalidate(vocabularyProvider(_query)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _VocabularyList extends StatelessWidget {
  const _VocabularyList({
    required this.page,
    required this.ref,
    required this.query,
    required this.onPrevious,
    required this.onNext,
  });

  final VocabularyPage page;
  final WidgetRef ref;
  final VocabularyQuery query;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return const Center(child: Text('조건에 맞는 단어가 없습니다.'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ListSummary(total: page.total, page: page.page),
        const SizedBox(height: 12),
        ...page.items.map(
          (item) => _VocabularyTile(item: item, ref: ref, query: query),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                child: const Text('이전'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${page.page}'),
            ),
            Expanded(
              child: OutlinedButton(onPressed: onNext, child: const Text('다음')),
            ),
          ],
        ),
      ],
    );
  }
}

class _ListSummary extends StatelessWidget {
  const _ListSummary({required this.total, required this.page});

  final int total;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '총 $total개',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          '$page 페이지',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _VocabularyTile extends ConsumerStatefulWidget {
  const _VocabularyTile({
    required this.item,
    required this.ref,
    required this.query,
  });

  final VocabularyItem item;
  final WidgetRef ref;
  final VocabularyQuery query;

  @override
  ConsumerState<_VocabularyTile> createState() => _VocabularyTileState();
}

class _VocabularyTileState extends ConsumerState<_VocabularyTile> {
  bool _savingBookmark = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/vocabulary/${item.id}'),
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
                            item.word,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _SmallBadge(
                          text: item.level > 0 ? '${item.level}급' : 'TOPIK',
                        ),
                        if (item.partOfSpeech?.isNotEmpty ?? false) ...[
                          const SizedBox(width: 6),
                          _SmallBadge(text: item.partOfSpeech!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.meaningKo,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (item.example?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.example!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: item.isBookmarked ? '북마크 해제' : '북마크',
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

  Future<void> _toggleBookmark(VocabularyItem item) async {
    setState(() => _savingBookmark = true);
    try {
      await ref
          .read(vocabularyRepositoryProvider)
          .setVocabularyBookmark(id: item.id, bookmarked: !item.isBookmarked);
      widget.ref.invalidate(vocabularyProvider(widget.query));
      widget.ref.invalidate(bookmarkSummaryProvider);
      widget.ref.invalidate(bookmarkedVocabularyProvider);
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
