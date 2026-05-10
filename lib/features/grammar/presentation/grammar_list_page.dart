import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/network/api_error_message.dart';
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
    return GrammarQuery(q: _searchController.text, page: _page, limit: 20);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grammar = ref.watch(grammarProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('문법 공부')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '문법 검색',
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
          Expanded(
            child: grammar.when(
              data: (page) => _GrammarList(
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
                  missingApiMessage: '문법 공부 API가 아직 백엔드에 연결되지 않았습니다.',
                ),
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
    required this.onPrevious,
    required this.onNext,
  });

  final GrammarPage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return const Center(child: Text('조건에 맞는 문법이 없습니다.'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('총 ${page.total}개', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        ...page.items.map((item) => _GrammarTile(item: item)),
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
        trailing: Icon(
          item.isDownloaded ? Icons.download_done : Icons.chevron_right,
        ),
        onTap: () => context.push('/grammar/${item.id}'),
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
