import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/user_vocabulary_service.dart';

class BookmarkedVocabularyPage extends ConsumerWidget {
  const BookmarkedVocabularyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final vocabulary = ref.watch(bookmarkedVocabularyProvider);
    final overrides = ref.watch(userVocabularyOverrideProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.bookmarkedVocab)),
      body: vocabulary.when(
        data: (items) {
          final visibleItems = items.where((it) => !overrides.isDeleted(it.vocabulary.id)).toList();
          if (visibleItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_border, size: 52, color: Colors.black26),
                  const SizedBox(height: 14),
                  Text(
                    strings.noBookmarks,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.mySavedWordbookDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonal(
                    onPressed: () => context.push('/vocabulary'),
                    child: Text(strings.allTopikVocab),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookmarkedVocabularyProvider);
              ref.invalidate(bookmarkSummaryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Quick Launch Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: Color(0xFF16A34A), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                strings.wordsSavedCount.replaceAll('{count}', '${items.length}'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickStudyBtn(
                              icon: Icons.style,
                              label: strings.flashcard,
                              color: const Color(0xFF0284C7),
                              bgColor: const Color(0xFFE0F2FE),
                              onTap: () => context.push('/vocabulary/flashcard?source=saved'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickStudyBtn(
                              icon: Icons.quiz,
                              label: strings.quiz,
                              color: const Color(0xFF7C3AED),
                              bgColor: const Color(0xFFEDE9FE),
                              onTap: () => context.push('/vocabulary/quiz?source=saved'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickStudyBtn(
                              icon: Icons.edit_note,
                              label: strings.dictation,
                              color: const Color(0xFFD97706),
                              bgColor: const Color(0xFFFEF3C7),
                              onTap: () => context.push('/vocabulary/dictation?source=saved'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickStudyBtn(
                              icon: Icons.headset,
                              label: strings.autoplay,
                              color: const Color(0xFF059669),
                              bgColor: const Color(0xFFD1FAE5),
                              onTap: () => context.push('/vocabulary/autoplay?source=saved'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in visibleItems)
                  _VocabularyTile(
                    item: () {
                      final edit = overrides.getEdit(item.vocabulary.id);
                      if (edit != null) {
                        return item.vocabulary.copyWith(
                          word: edit.word.isNotEmpty ? edit.word : item.vocabulary.word,
                          meaningKo: edit.meaning.isNotEmpty ? edit.meaning : item.vocabulary.meaningKo,
                          meaningUserLang: edit.meaning.isNotEmpty ? edit.meaning : item.vocabulary.meaningUserLang,
                        );
                      }
                      return item.vocabulary;
                    }(),
                    strings: strings,
                  ),
              ],
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
          onRetry: () => ref.invalidate(bookmarkedVocabularyProvider),
        ),
      ),
    );
  }
}

class _QuickStudyBtn extends StatelessWidget {
  const _QuickStudyBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularyTile extends StatelessWidget {
  const _VocabularyTile({required this.item, required this.strings});

  final VocabularyItem item;
  final AppStrings strings;

  void _speak(String text) async {
    final tts = FlutterTts()
      ..setLanguage('ko-KR')
      ..setSpeechRate(0.45);
    await tts.stop();
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Row(
          children: [
            Text(
              item.word,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20, color: AppColors.mintDark),
              tooltip: strings.listenPronunciation,
              visualDensity: VisualDensity.compact,
              onPressed: () => _speak(item.word),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.meaningKo,
            style: const TextStyle(color: Color(0xFF334155)),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => context.push('/vocabulary/${item.id}'),
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
