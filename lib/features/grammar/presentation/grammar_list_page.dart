import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_master.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_service.dart';
import 'package:topik_go/features/grammar/domain/ai_grammar_service.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/domain/user_grammar_service.dart';
import 'package:topik_go/features/grammar/presentation/grammar_source_sheet.dart';

class GrammarListPage extends ConsumerStatefulWidget {
  const GrammarListPage({
    super.key,
    this.initialLevelGroup = GrammarLevelGroup.all,
  });

  final GrammarLevelGroup initialLevelGroup;

  @override
  ConsumerState<GrammarListPage> createState() => _GrammarListPageState();
}

class _GrammarListPageState extends ConsumerState<GrammarListPage> {
  final _searchController = TextEditingController();
  late GrammarLevelGroup _selectedLevelGroup;
  GrammarCategoryType _selectedCategory = GrammarCategoryType.all;

  @override
  void initState() {
    super.initState();
    _selectedLevelGroup = widget.initialLevelGroup;
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
    final targetLang = ref.watch(currentLanguageProvider);
    final bookmarksAsync = ref.watch(bookmarkedGrammarProvider);
    final userSavedGrammars = ref.watch(userGrammarProvider).savedGrammars;
    final bookmarksList = bookmarksAsync.asData?.value ?? [];
    final uniquePatterns = <String>{
      ...userSavedGrammars.map((g) => g.pattern),
      ...bookmarksList.map((b) => b.grammar.pattern),
    };
    final savedCount = uniquePatterns.length;

    // Filter params for Master Korean Grammar Database
    final filterParams = GrammarFilterParams(
      searchQuery: _searchController.text,
      levelGroup: _selectedLevelGroup,
      category: _selectedCategory,
      targetLang: targetLang,
    );
    final masterItems = ref.watch(filteredMasterGrammarProvider(filterParams));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '문법명, 키워드, 모국어 의미(sabab, because 등) 검색',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                ),
              ),
            ),
          ),

          // 3. Level Group Tabs (전체 / 초급 / 중급 / 고급 / 내 문법장)
          Material(
            color: Colors.white,
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildLevelTab(GrammarLevelGroup.all, '전체 문법'),
                  _buildLevelTab(GrammarLevelGroup.beginner, '초급 (1~2급)'),
                  _buildLevelTab(GrammarLevelGroup.intermediate, '중급 (3~4급)'),
                  _buildLevelTab(GrammarLevelGroup.advanced, '고급 (5~6급)'),
                  _buildLevelTab(GrammarLevelGroup.saved, '내 문법장 ($savedCount)'),
                ],
              ),
            ),
          ),

          // 4. Category Filter Chips
          Material(
            color: Colors.white,
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
                  GrammarCategoryType.other,
                ].map((type) {
                  final isSelected = _selectedCategory == type;
                  final label = _getCategoryLabel(type, strings);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: const Color(0xFFEDE9FE),
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = type);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 5. Match Count Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 ${masterItems.length}개 문법',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (_searchController.text.isNotEmpty ||
                    _selectedLevelGroup != GrammarLevelGroup.all ||
                    _selectedCategory != GrammarCategoryType.all)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _selectedLevelGroup = GrammarLevelGroup.all;
                        _selectedCategory = GrammarCategoryType.all;
                      });
                    },
                    child: const Text(
                      '필터 초기화',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 6. Master Grammar List
          Expanded(
            child: masterItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        const Text(
                          '조건에 맞는 문법이 없습니다.',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedLevelGroup = GrammarLevelGroup.all;
                              _selectedCategory = GrammarCategoryType.all;
                            });
                          },
                          child: const Text('전체 문법 보기'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: masterItems.length,
                    itemBuilder: (context, index) {
                      return _MasterGrammarTile(
                        item: masterItems[index],
                        targetLang: targetLang,
                        strings: strings,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTab(GrammarLevelGroup group, String title) {
    final isSelected = _selectedLevelGroup == group;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevelGroup = group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
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

class _MasterGrammarTile extends ConsumerStatefulWidget {
  const _MasterGrammarTile({
    required this.item,
    required this.targetLang,
    required this.strings,
  });

  final MasterGrammarItem item;
  final String targetLang;
  final AppStrings strings;

  @override
  ConsumerState<_MasterGrammarTile> createState() => _MasterGrammarTileState();
}

class _MasterGrammarTileState extends ConsumerState<_MasterGrammarTile> {
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
    final userGrammarState = ref.watch(userGrammarProvider);
    final isSaved = userGrammarState.isSaved(item.pattern);

    Color levelColor;
    if (item.level <= 2) {
      levelColor = const Color(0xFF059669); // Emerald
    } else if (item.level <= 4) {
      levelColor = const Color(0xFF2563EB); // Blue
    } else {
      levelColor = const Color(0xFF7C3AED); // Purple
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () => context.push('/grammar/${item.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Level & Category Badges + Bookmark Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.levelLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: levelColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _speak(item.pattern),
                        icon: const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF7C3AED)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? const Color(0xFFD07A21) : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final userNotifier = ref.read(userGrammarProvider.notifier);
                          if (isSaved) {
                            await userNotifier.removeGrammar(item.pattern);
                          } else {
                            await userNotifier.saveGrammar(
                              AiGrammarDetail(
                                id: item.id,
                                pattern: item.pattern,
                                category: item.category,
                                level: item.level,
                                meaning: item.meaningKo,
                                explanation: item.explanationKo,
                                conjugationRule: item.conjugationRule,
                                examples: item.examples
                                    .map((e) => AiGrammarExample(korean: e.korean, translation: e.english ?? ''))
                                    .toList(),
                                isBookmarked: true,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Pattern Name
              Text(
                item.pattern,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),

              // 3. Meaning in configured native language
              Text(
                item.getMeaning(widget.targetLang),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
