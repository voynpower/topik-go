import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/presentation/grammar_source_sheet.dart';

class GrammarListPage extends ConsumerStatefulWidget {
  const GrammarListPage({super.key});

  @override
  ConsumerState<GrammarListPage> createState() => _GrammarListPageState();
}

class _GrammarListPageState extends ConsumerState<GrammarListPage> {
  final _searchController = TextEditingController();
  int _page = 1;
  GrammarCategoryType _selectedCategory = GrammarCategoryType.all;

  GrammarQuery get _query {
    return GrammarQuery(
      q: _searchController.text,
      page: _page,
      limit: 30,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openStudyMode(GrammarStudyMode mode) {
    GrammarSourceSheet.show(context, mode);
  }

  String _getCategoryLabel(GrammarCategoryType type, AppStrings strings) {
    switch (type) {
      case GrammarCategoryType.all:
        return strings.grammarCategoryAll;
      case GrammarCategoryType.reason:
        return strings.grammarCategoryReason;
      case GrammarCategoryType.contrast:
        return strings.grammarCategoryContrast;
      case GrammarCategoryType.purpose:
        return strings.grammarCategoryPurpose;
      case GrammarCategoryType.condition:
        return strings.grammarCategoryCondition;
      case GrammarCategoryType.time:
        return strings.grammarCategoryTime;
      case GrammarCategoryType.other:
        return strings.grammarCategoryOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final grammar = ref.watch(grammarProvider(_query));
    final bookmarksAsync = ref.watch(bookmarkedGrammarProvider);
    final savedCount = bookmarksAsync.asData?.value.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(strings.grammarStudy)),
      body: Column(
        children: [
          // 1. OneGrammar 2 Study Launchers Hub
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
                          const Icon(Icons.psychology_alt_outlined, color: Color(0xFF7C3AED), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            strings.oneGrammarTitle,
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
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          strings.wordsSavedCount.replaceAll('{count}', '$savedCount'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _GrammarLaunchButton(
                          icon: Icons.style_outlined,
                          title: strings.grammarFlashcard,
                          subtitle: strings.grammarFlashcardDesc,
                          color: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFEDE9FE),
                          onTap: () => _openStudyMode(GrammarStudyMode.flashcard),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GrammarLaunchButton(
                          icon: Icons.quiz_outlined,
                          title: strings.grammarQuiz,
                          subtitle: strings.grammarQuizDesc,
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEFF6FF),
                          onTap: () => _openStudyMode(GrammarStudyMode.quiz),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Search Field
          Material(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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

          // 3. Category Filter Chips
          Material(
            color: AppColors.surface,
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  GrammarCategoryType.all,
                  GrammarCategoryType.reason,
                  GrammarCategoryType.contrast,
                  GrammarCategoryType.purpose,
                  GrammarCategoryType.condition,
                  GrammarCategoryType.time,
                ].map((type) {
                  final isSelected = _selectedCategory == type;
                  final label = _getCategoryLabel(type, strings);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: const Color(0xFFEDE9FE),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = type;
                            _page = 1;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 4. Grammar List
          Expanded(
            child: grammar.when(
              data: (page) {
                // Filter by category if not all
                final filteredItems = _selectedCategory == GrammarCategoryType.all
                    ? page.items
                    : page.items
                        .where((item) => GrammarCategory.matches(item, _selectedCategory))
                        .toList();

                return _GrammarList(
                  items: filteredItems,
                  page: page,
                  query: _query,
                  strings: strings,
                  onPrevious: page.page > 1
                      ? () => setState(() => _page = _page - 1)
                      : null,
                  onNext: page.page * page.limit < page.total
                      ? () => setState(() => _page = _page + 1)
                      : null,
                );
              },
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

class _GrammarLaunchButton extends StatelessWidget {
  const _GrammarLaunchButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrammarList extends StatelessWidget {
  const _GrammarList({
    required this.items,
    required this.page,
    required this.query,
    required this.strings,
    required this.onPrevious,
    required this.onNext,
  });

  final List<GrammarItem> items;
  final GrammarPage page;
  final GrammarQuery query;
  final AppStrings strings;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          strings.noBookmarks,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        ...items.map((item) => _GrammarTile(item: item, strings: strings)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: onPrevious,
              child: Text(strings.prev),
            ),
            Text(
              '${page.page} / ${(page.total / page.limit).ceil().clamp(1, 999)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            OutlinedButton(
              onPressed: onNext,
              child: Text(strings.next),
            ),
          ],
        ),
      ],
    );
  }
}

class _GrammarTile extends ConsumerStatefulWidget {
  const _GrammarTile({required this.item, required this.strings});

  final GrammarItem item;
  final AppStrings strings;

  @override
  ConsumerState<_GrammarTile> createState() => _GrammarTileState();
}

class _GrammarTileState extends ConsumerState<_GrammarTile> {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.pattern,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _speak(item.pattern),
              icon: const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF7C3AED)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: item.isBookmarked ? const Color(0xFFD07A21) : Colors.grey,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _savingBookmark
                  ? null
                  : () async {
                      setState(() => _savingBookmark = true);
                      try {
                        await ref.read(bookmarkRepositoryProvider).setGrammarBookmark(
                              grammarId: item.id,
                              bookmarked: !item.isBookmarked,
                            );
                        ref.invalidate(grammarProvider);
                        ref.invalidate(bookmarkedGrammarProvider);
                        ref.invalidate(bookmarkSummaryProvider);
                      } finally {
                        if (mounted) {
                          setState(() => _savingBookmark = false);
                        }
                      }
                    },
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: item.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        onTap: () => context.push('/grammar/${item.id}'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: Text(retryText)),
        ],
      ),
    );
  }
}
