import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/network/api_error_message.dart';
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
    required this.onPrevious,
    required this.onNext,
  });

  final VocabularyPage page;
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
        Text('총 ${page.total}개', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        ...page.items.map((item) => _VocabularyTile(item: item)),
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
        trailing: Icon(
          item.isDownloaded ? Icons.download_done : Icons.chevron_right,
        ),
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
