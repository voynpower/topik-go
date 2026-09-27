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
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_source_sheet.dart';

class VocabularyListPage extends ConsumerStatefulWidget {
  const VocabularyListPage({super.key});

  @override
  ConsumerState<VocabularyListPage> createState() => _VocabularyListPageState();
}

class _VocabularyListPageState extends ConsumerState<VocabularyListPage> {
  final _searchController = TextEditingController();
  int? _level;
  int _page = 1;
  bool _onlySaved = false;

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

  void _openStudyMode(VocabularyStudyMode mode) {
    VocabularySourceSheet.show(context, mode);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final vocabulary = ref.watch(vocabularyProvider(_query));
    final bookmarksAsync = ref.watch(bookmarkedVocabularyProvider);
    final savedCount = bookmarksAsync.asData?.value.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.smartWordbook),
      ),
      body: Column(
        children: [
          // 1. OneVoca 4 Study Launchers Hub
          Material(
            color: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: AppColors.mintDark, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            strings.oneVocaTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          strings.wordsSavedCount.replaceAll('{count}', '$savedCount'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Mode 1: Flashcard
                      Expanded(
                        child: _StudyModeCard(
                          icon: Icons.style,
                          iconColor: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFF0F9FF),
                          borderColor: const Color(0xFFBAE6FD),
                          title: strings.flashcard,
                          subtitle: strings.flashcardDesc,
                          onTap: () => _openStudyMode(VocabularyStudyMode.flashcard),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mode 2: Quiz
                      Expanded(
                        child: _StudyModeCard(
                          icon: Icons.quiz,
                          iconColor: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFF5F3FF),
                          borderColor: const Color(0xFFDDD6FE),
                          title: strings.quiz,
                          subtitle: strings.quizDesc,
                          onTap: () => _openStudyMode(VocabularyStudyMode.quiz),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mode 3: Dictation
                      Expanded(
                        child: _StudyModeCard(
                          icon: Icons.edit_note,
                          iconColor: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFFFBEB),
                          borderColor: const Color(0xFFFDE68A),
                          title: strings.dictation,
                          subtitle: strings.dictationDesc,
                          onTap: () => _openStudyMode(VocabularyStudyMode.dictation),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mode 4: Autoplay
                      Expanded(
                        child: _StudyModeCard(
                          icon: Icons.headset,
                          iconColor: const Color(0xFF059669),
                          bgColor: const Color(0xFFECFDF5),
                          borderColor: const Color(0xFFA7F3D0),
                          title: strings.autoplay,
                          subtitle: strings.autoplayDesc,
                          onTap: () => _openStudyMode(VocabularyStudyMode.autoplay),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Search & Filter Bar
          Material(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: strings.searchVocabulary,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _page = 1);
                              },
                              icon: const Icon(Icons.close, size: 18),
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
                          label: strings.all,
                          selected: !_onlySaved && _level == null,
                          onTap: () => setState(() {
                            _onlySaved = false;
                            _level = null;
                            _page = 1;
                          }),
                        ),
                        _LevelChip(
                          label: strings.savedWords,
                          selected: _onlySaved,
                          color: const Color(0xFF15803D),
                          onTap: () => setState(() {
                            _onlySaved = true;
                            _level = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Word List Content
          Expanded(
            child: _onlySaved
                ? bookmarksAsync.when(
                    data: (bookmarks) {
                      final items = bookmarks.map((b) => b.vocabulary).toList();
                      final queryText = _searchController.text.trim().toLowerCase();
                      final filtered = queryText.isEmpty
                          ? items
                          : items.where((it) {
                              return it.word.toLowerCase().contains(queryText) ||
                                  it.meaningKo.toLowerCase().contains(queryText);
                            }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_border, size: 48, color: Colors.black26),
                              const SizedBox(height: 12),
                              Text(
                                strings.noBookmarks,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strings.mySavedWordbookDesc,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _VocabularyTile(
                            item: filtered[index],
                            ref: ref,
                            query: _query,
                            strings: strings,
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('${strings.error}: $error')),
                  )
                : vocabulary.when(
                    data: (page) => _VocabularyList(
                      page: page,
                      ref: ref,
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
                      onRetry: () => ref.invalidate(vocabularyProvider(_query)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudyModeCard extends StatelessWidget {
  const _StudyModeCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: iconColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: color?.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? (color ?? AppColors.mintDark) : Colors.black87,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          fontSize: 12,
        ),
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
    required this.strings,
    required this.onPrevious,
    required this.onNext,
  });

  final VocabularyPage page;
  final WidgetRef ref;
  final VocabularyQuery query;
  final AppStrings strings;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return Center(child: Text(strings.noBookmarks));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _ListSummary(total: page.total, page: page.page),
        const SizedBox(height: 10),
        ...page.items.map(
          (item) => _VocabularyTile(item: item, ref: ref, query: query, strings: strings),
        ),
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
            '총 $total개 단어',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        Text(
          '$page 페이지',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontSize: 12),
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
    required this.strings,
  });

  final VocabularyItem item;
  final WidgetRef ref;
  final VocabularyQuery query;
  final AppStrings strings;

  @override
  ConsumerState<_VocabularyTile> createState() => _VocabularyTileState();
}

class _VocabularyTileState extends ConsumerState<_VocabularyTile> {
  bool _savingBookmark = false;
  FlutterTts? _tts;

  void _speak(String text) async {
    _tts ??= FlutterTts()
      ..setLanguage('ko-KR')
      ..setSpeechRate(0.45);
    await _tts?.stop();
    await _tts?.speak(text);
  }

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final strings = widget.strings;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Row(
          children: [
            Text(
              item.word,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const Spacer(),
            // TTS Audio speaker button
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20, color: AppColors.mintDark),
              tooltip: strings.listenPronunciation,
              visualDensity: VisualDensity.compact,
              onPressed: () => _speak(item.word),
            ),
            // Bookmark toggle
            IconButton(
              icon: _savingBookmark
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 22,
                      color: item.isBookmarked ? const Color(0xFF16A34A) : AppColors.textSecondary,
                    ),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                setState(() => _savingBookmark = true);
                try {
                  await ref.read(bookmarkRepositoryProvider).setVocabularyBookmark(
                        vocabularyId: item.id,
                        bookmarked: !item.isBookmarked,
                      );
                  ref.invalidate(vocabularyProvider(widget.query));
                  ref.invalidate(bookmarkedVocabularyProvider);
                  ref.invalidate(bookmarkSummaryProvider);
                } finally {
                  if (mounted) setState(() => _savingBookmark = false);
                }
              },
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.meaningKo,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
              ),
              if (item.meaningUserLang != null && item.meaningUserLang!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item.meaningUserLang!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
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
