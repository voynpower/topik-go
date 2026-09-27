import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_mastery_service.dart';
import 'package:topik_go/features/vocabulary/presentation/widgets/voca_word_card.dart';

class VocaListTabView extends ConsumerStatefulWidget {
  const VocaListTabView({super.key});

  @override
  ConsumerState<VocaListTabView> createState() => _VocaListTabViewState();
}

class _VocaListTabViewState extends ConsumerState<VocaListTabView> {
  final _searchController = TextEditingController();
  int? _level;
  int _page = 1;
  bool _onlySaved = false;
  WordMasteryStatus? _statusFilter;
  bool _isSearching = false;

  VocabularyQuery get _query {
    return VocabularyQuery(
      level: _level,
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

  void _showAddWordModal(BuildContext context, AppStrings strings) {
    final wordCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E222D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '새 단어 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wordCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '한국어 단어',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF272C3E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meaningCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '단어 뜻 (모국어 또는 한국어)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF272C3E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final word = wordCtrl.text.trim();
                    final meaning = meaningCtrl.text.trim();
                    if (word.isEmpty) return;

                    Navigator.of(ctx).pop();
                    try {
                      await ref.read(bookmarkRepositoryProvider).addVocabularyByWord(
                            word: word,
                            meaningUserLang: meaning,
                            level: 3,
                          );
                      ref.invalidate(vocabularyProvider);
                      ref.invalidate(bookmarkedVocabularyProvider);
                    } catch (_) {}
                  },
                  child: const Text('단어장에 저장', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final vocabulary = ref.watch(vocabularyProvider(_query));
    final bookmarksAsync = ref.watch(bookmarkedVocabularyProvider);
    final masteryMap = ref.watch(wordMasteryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13161F), // OneVoca 딥 다크 배경
      body: Column(
        children: [
          // 1. OneVoca Style Group Header & Controls (voca_img1)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Group Dropdown Menu
                PopupMenuButton<int?>(
                  color: const Color(0xFF1E222D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  initialValue: _level,
                  onSelected: (val) {
                    setState(() {
                      _level = val;
                      _page = 1;
                    });
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('모든 그룹 (전체)', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 1,
                      child: Text('TOPIK I (1·2급 기초)', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 3,
                      child: Text('TOPIK II 3급', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 4,
                      child: Text('TOPIK II 4급', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 5,
                      child: Text('TOPIK II 5급', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 6,
                      child: Text('TOPIK II 6급 심화', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  child: Row(
                    children: [
                      Text(
                        _level == null ? '모든 그룹' : 'TOPIK $_level급',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
                const Spacer(),
                // Search Toggle
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white70,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        _page = 1;
                      }
                    });
                  },
                ),
                // Only Bookmarked Filter Toggle
                IconButton(
                  icon: Icon(
                    _onlySaved ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: _onlySaved ? const Color(0xFFFBBF24) : Colors.white70,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _onlySaved = !_onlySaved;
                      _page = 1;
                    });
                  },
                ),
              ],
            ),
          ),

          // Search Field (Expands when search is active)
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: strings.searchVocabulary,
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF1E222D),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => setState(() => _page = 1),
              ),
            ),

          // 2. Status Level Filter Chips (어려워요, 애매해요, 외웠어요)
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _StatusFilterChip(
                  label: strings.all,
                  color: Colors.white70,
                  isSelected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                _StatusFilterChip(
                  label: '🔴 ${strings.statusHard}',
                  color: const Color(0xFFEF4444),
                  isSelected: _statusFilter == WordMasteryStatus.hard,
                  onTap: () => setState(() => _statusFilter = WordMasteryStatus.hard),
                ),
                _StatusFilterChip(
                  label: '🟡 ${strings.statusUnsure}',
                  color: const Color(0xFFF59E0B),
                  isSelected: _statusFilter == WordMasteryStatus.unsure,
                  onTap: () => setState(() => _statusFilter = WordMasteryStatus.unsure),
                ),
                _StatusFilterChip(
                  label: '🟢 ${strings.statusMastered}',
                  color: const Color(0xFF10B981),
                  isSelected: _statusFilter == WordMasteryStatus.mastered,
                  onTap: () => setState(() => _statusFilter = WordMasteryStatus.mastered),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. Word Card List
          Expanded(
            child: vocabulary.when(
              data: (page) {
                var items = page.items;

                // Bookmarked Filter
                if (_onlySaved) {
                  final savedIds = bookmarksAsync.asData?.value.map((b) => b.id).toSet() ?? {};
                  items = items.where((it) => savedIds.contains(it.id) || it.isBookmarked).toList();
                }

                // Status Filter
                if (_statusFilter != null) {
                  items = items.where((it) {
                    final st = masteryMap[it.id] ?? WordMasteryStatus.hard;
                    return st == _statusFilter;
                  }).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.style_outlined, size: 54, color: Colors.white24),
                        const SizedBox(height: 14),
                        Text(
                          strings.noBookmarks,
                          style: const TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  children: [
                    ...items.map((item) => VocaWordCard(item: item, strings: strings)),
                    // Pagination
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                          onPressed: page.page > 1 ? () => setState(() => _page = _page - 1) : null,
                          child: Text(strings.prev),
                        ),
                        Text(
                          '${page.page} / ${(page.total / page.limit).ceil().clamp(1, 999)}',
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                          onPressed: page.page * page.limit < page.total ? () => setState(() => _page = _page + 1) : null,
                          child: Text(strings.next),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
              error: (err, _) => Center(
                child: Text(
                  apiErrorMessage(err, missingApiMessage: strings.error),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
      // Floating Action Button (+)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => _showAddWordModal(context, strings),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        backgroundColor: const Color(0xFF1E222D),
        selectedColor: const Color(0xFF272C3E),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF2D3342),
          width: isSelected ? 1.5 : 1.0,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.white60,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
