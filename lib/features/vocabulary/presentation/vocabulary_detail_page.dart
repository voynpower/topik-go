import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
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
    final item = ref.watch(vocabularyItemProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('단어 상세')),
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
                        Text(
                          '${vocabulary.level}급',
                          style: TextStyle(
                            color: AppColors.mintDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(vocabulary.meaningKo),
                    if (vocabulary.meaningUserLang?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(vocabulary.meaningUserLang!),
                    ],
                    if (vocabulary.ttsUrl?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 12),
                      Text(
                        vocabulary.ttsUrl!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : () => _bookmark(vocabulary.id),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('북마크 저장'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _toggleDownload(
                      vocabulary.id,
                      downloaded: !vocabulary.isDownloaded,
                    ),
              icon: Icon(
                vocabulary.isDownloaded
                    ? Icons.download_done
                    : Icons.download_outlined,
              ),
              label: Text(vocabulary.isDownloaded ? '다운로드 해제' : '오프라인 저장'),
            ),
            const SizedBox(height: 8),
            Text(
              '현재 다운로드 상태는 backend DB의 global field를 사용합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: apiErrorMessage(
            error,
            missingApiMessage: '단어 상세 API가 아직 백엔드에 연결되지 않았습니다.',
          ),
          onRetry: () => ref.invalidate(vocabularyItemProvider(widget.id)),
        ),
      ),
    );
  }

  Future<void> _bookmark(String id) async {
    setState(() => _saving = true);
    try {
      await ref.read(vocabularyRepositoryProvider).bookmarkVocabulary(id);
      ref.invalidate(bookmarkSummaryProvider);
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
      final repository = ref.read(vocabularyRepositoryProvider);
      if (downloaded) {
        await repository.downloadVocabulary(id);
      } else {
        await repository.removeVocabularyDownload(id);
      }
      ref.invalidate(vocabularyItemProvider(widget.id));
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
