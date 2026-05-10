import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
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
    final item = ref.watch(grammarItemProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('문법 상세')),
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
                    Text(grammar.description),
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
              Text('예문', style: Theme.of(context).textTheme.titleMedium),
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
              onPressed: _saving ? null : () => _bookmark(grammar.id),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('북마크 저장'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _toggleDownload(
                      grammar.id,
                      downloaded: !grammar.isDownloaded,
                    ),
              icon: Icon(
                grammar.isDownloaded
                    ? Icons.download_done
                    : Icons.download_outlined,
              ),
              label: Text(grammar.isDownloaded ? '다운로드 해제' : '오프라인 저장'),
            ),
            const SizedBox(height: 8),
            Text(
              '현재 다운로드 상태는 backend DB의 global field를 사용합니다.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: apiErrorMessage(
            error,
            missingApiMessage: '문법 상세 API가 아직 백엔드에 연결되지 않았습니다.',
          ),
          onRetry: () => ref.invalidate(grammarItemProvider(widget.id)),
        ),
      ),
    );
  }

  Future<void> _bookmark(String id) async {
    setState(() => _saving = true);
    try {
      await ref.read(grammarRepositoryProvider).bookmarkGrammar(id);
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedGrammarProvider);
      _showMessage('북마크에 저장되었습니다.');
    } catch (error) {
      _showMessage(apiErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleDownload(String id, {required bool downloaded}) async {
    setState(() => _saving = true);
    try {
      final repository = ref.read(grammarRepositoryProvider);
      if (downloaded) {
        await repository.downloadGrammar(id);
      } else {
        await repository.removeGrammarDownload(id);
      }
      ref.invalidate(grammarItemProvider(widget.id));
      _showMessage(downloaded ? '오프라인 저장되었습니다.' : '다운로드가 해제되었습니다.');
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
