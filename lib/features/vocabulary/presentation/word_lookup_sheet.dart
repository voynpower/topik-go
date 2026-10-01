import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/user_vocabulary_service.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';

/// 단어/문법 번역 및 내 단어장 자동 추가를 위한 미니 바텀시트
Future<void> showWordLookupSheet(
  BuildContext context, {
  String? initialWord,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WordLookupSheet(initialWord: initialWord),
  );
}

class WordLookupSheet extends ConsumerStatefulWidget {
  const WordLookupSheet({super.key, this.initialWord});

  final String? initialWord;

  @override
  ConsumerState<WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends ConsumerState<WordLookupSheet> {
  late final TextEditingController _controller;
  late final FlutterTts _tts;

  bool _loading = false;
  bool _translating = false;
  String? _errorMessage;
  String? _autoTranslation;
  List<VocabularyItem> _vocabResults = [];
  List<GrammarItem> _grammarResults = [];
  final Set<String> _bookmarkedVocabIds = {};
  final Set<String> _bookmarkedGrammarIds = {};
  bool _customWordBookmarked = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _cleanWord(widget.initialWord ?? ''));
    _tts = FlutterTts();
    _tts.setLanguage('ko-KR');
    _tts.setSpeechRate(0.45);

    if (_controller.text.trim().isNotEmpty) {
      _performSearch(_controller.text.trim());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  String _cleanWord(String raw) {
    // Remove brackets, trailing punctuation, and whitespace
    return raw
        .replaceAll(RegExp(r'''[()[\]{}「」『』"'“”‘’,\.!?~·…\n\r]'''), '')
        .trim();
  }

  String? _stripKoreanParticles(String word) {
    if (word.length <= 1) return null;
    const multiParticles = [
      '에서는', '에게는', '으로는', '까지는', '부터는',
      '에서', '에게', '으로', '까지', '부터',
      '과의', '와의',
    ];
    for (final p in multiParticles) {
      if (word.endsWith(p) && word.length > p.length) {
        return word.substring(0, word.length - p.length);
      }
    }
    const singleParticles = [
      '은', '는', '이', '가', '을', '를', '에', '의', '와', '과', '도', '만', '로'
    ];
    for (final p in singleParticles) {
      if (word.endsWith(p) && word.length > p.length) {
        return word.substring(0, word.length - p.length);
      }
    }
    return null;
  }

  Future<void> _performSearch(String query) async {
    final term = _cleanWord(query);
    if (term.isEmpty) {
      setState(() {
        _vocabResults = [];
        _grammarResults = [];
        _autoTranslation = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _translating = true;
      _autoTranslation = null;
      _errorMessage = null;
      _customWordBookmarked = false;
    });

    final targetLang = ref.read(currentLanguageProvider);
    if (targetLang != 'ko') {
      TranslationService.translate(text: term, targetLang: targetLang).then((trans) {
        if (mounted) {
          setState(() {
            _autoTranslation = trans;
            _translating = false;
          });
        }
      });
    } else {
      _translating = false;
    }

    try {
      final vocabRepo = ref.read(vocabularyRepositoryProvider);
      final grammarRepo = ref.read(grammarRepositoryProvider);

      final vocabFuture = vocabRepo.getVocabulary(
        VocabularyQuery(q: term, limit: 10),
      );
      final grammarFuture = grammarRepo.getGrammar(
        GrammarQuery(q: term, limit: 5),
      );

      final results = await Future.wait([vocabFuture, grammarFuture]);
      var vocabPage = results[0] as VocabularyPage;
      final grammarPage = results[1] as GrammarPage;

      if (vocabPage.items.isEmpty) {
        final stem = _stripKoreanParticles(term);
        if (stem != null && stem != term && stem.isNotEmpty) {
          try {
            final fallbackPage = await vocabRepo.getVocabulary(
              VocabularyQuery(q: stem, limit: 10),
            );
            if (fallbackPage.items.isNotEmpty) {
              vocabPage = fallbackPage;
            }
          } catch (_) {}
        }
      }

      final savedBookmarks =
          ref.read(bookmarkedVocabularyProvider).asData?.value ?? [];
      final savedVocabIds =
          savedBookmarks.map((b) => b.vocabulary.id).toSet();
      final savedGrammar =
          ref.read(bookmarkedGrammarProvider).asData?.value ?? [];
      final savedGrammarIds =
          savedGrammar.map((b) => b.grammar.id).toSet();
      final isCustomSaved =
          savedBookmarks.any((b) => _cleanWord(b.vocabulary.word) == term);

      if (mounted) {
        setState(() {
          _vocabResults = vocabPage.items;
          _grammarResults = grammarPage.items;
          for (final item in _vocabResults) {
            if (item.isBookmarked || savedVocabIds.contains(item.id)) {
              _bookmarkedVocabIds.add(item.id);
            }
          }
          for (final item in _grammarResults) {
            if (item.isBookmarked || savedGrammarIds.contains(item.id)) {
              _bookmarkedGrammarIds.add(item.id);
            }
          }
          if (isCustomSaved) {
            _customWordBookmarked = true;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = ref.read(appStringsProvider).error;
        });
      }
    }
  }

  Future<void> _toggleVocabBookmark(VocabularyItem item, AppStrings strings) async {
    final isBookmarked = _bookmarkedVocabIds.contains(item.id);
    final newStatus = !isBookmarked;

    setState(() {
      if (newStatus) {
        _bookmarkedVocabIds.add(item.id);
      } else {
        _bookmarkedVocabIds.remove(item.id);
      }
    });

    try {
      final repo = ref.read(bookmarkRepositoryProvider);
      final targetLang = ref.read(currentLanguageProvider);
      String? translationToSave;
      if (newStatus && targetLang != 'ko') {
        final translated = await TranslationService.translate(
          text: item.word,
          targetLang: targetLang,
        );
        translationToSave = (translated != null && translated.trim().isNotEmpty)
            ? translated.trim()
            : (item.meaningUserLang?.trim().isNotEmpty == true
                ? item.meaningUserLang
                : item.meaningKo);
      }

      await repo.setVocabularyBookmark(
        vocabularyId: item.id,
        bookmarked: newStatus,
        meaningUserLang: translationToSave,
      );

      if (newStatus) {
        await ref.read(userVocabularyOverrideProvider.notifier).registerBookmarkedWord(
          item.copyWith(
            meaningUserLang: translationToSave ?? item.meaningUserLang,
            isBookmarked: true,
          ),
        );
      } else {
        await ref.read(userVocabularyOverrideProvider.notifier).removeBookmarkedWord(
          item.id,
          item.word,
        );
      }

      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedVocabularyProvider);
      ref.invalidate(vocabularyProvider);
      ref.invalidate(studyWordsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? strings.savedToVocabulary : strings.delete,
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isBookmarked) {
            _bookmarkedVocabIds.add(item.id);
          } else {
            _bookmarkedVocabIds.remove(item.id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addCustomWordToBookmark(String word, AppStrings strings) async {
    final clean = _cleanWord(word);
    if (clean.isEmpty) return;

    setState(() {
      _customWordBookmarked = true;
    });

    try {
      final repo = ref.read(bookmarkRepositoryProvider);
      final targetLang = ref.read(currentLanguageProvider);
      String? translationToSave;
      if (targetLang != 'ko') {
        final translated = await TranslationService.translate(
          text: clean,
          targetLang: targetLang,
        );
        translationToSave = (translated != null && translated.trim().isNotEmpty)
            ? translated.trim()
            : _autoTranslation;
      }

      await repo.addVocabularyByWord(
        word: clean,
        meaningKo: clean,
        meaningUserLang: translationToSave,
      );
      await ref.read(userVocabularyOverrideProvider.notifier).addCustomWord(
        word: clean,
        meaning: translationToSave ?? clean,
      );
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedVocabularyProvider);
      ref.invalidate(vocabularyProvider);
      ref.invalidate(studyWordsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.savedToVocabulary),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _customWordBookmarked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleGrammarBookmark(GrammarItem item, AppStrings strings) async {
    final isBookmarked = _bookmarkedGrammarIds.contains(item.id);
    final newStatus = !isBookmarked;

    setState(() {
      if (newStatus) {
        _bookmarkedGrammarIds.add(item.id);
      } else {
        _bookmarkedGrammarIds.remove(item.id);
      }
    });

    try {
      final repo = ref.read(bookmarkRepositoryProvider);
      await repo.setGrammarBookmark(
        grammarId: item.id,
        bookmarked: newStatus,
      );
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedGrammarProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? strings.savedToGrammar : strings.delete,
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isBookmarked) {
            _bookmarkedGrammarIds.add(item.id);
          } else {
            _bookmarkedGrammarIds.remove(item.id);
          }
        });
      }
    }
  }

  Future<void> _openNaverDictionary(String word) async {
    final clean = _cleanWord(word);
    final uri = Uri.parse(
      'https://ko.dict.naver.com/#/search?query=${Uri.encodeComponent(clean)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _speak(String text) async {
    if (text.trim().isNotEmpty) {
      await _tts.stop();
      await _tts.speak(text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final term = _controller.text.trim();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title Row
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.mintDark, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.dictTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search input
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: strings.searchWordOrGrammar,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                onPressed: () => _performSearch(_controller.text),
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _performSearch,
          ),
          const SizedBox(height: 14),
          // Results list or loading
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(term, strings),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(String term, AppStrings strings) {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final hasVocab = _vocabResults.isNotEmpty;
    final hasGrammar = _grammarResults.isNotEmpty;

    if (!hasVocab && !hasGrammar) {
      return _buildNoResultsView(term, strings);
    }

    return ListView(
      children: [
        if (hasVocab) ...[
          Text(
            strings.vocabSection,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          ..._vocabResults.map((it) => _buildVocabCard(it, strings)),
          const SizedBox(height: 14),
        ],
        if (hasGrammar) ...[
          Text(
            strings.grammarSection,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          ..._grammarResults.map((it) => _buildGrammarCard(it, strings)),
          const SizedBox(height: 14),
        ],
        _buildExternalDictionaryButton(term, strings),
      ],
    );
  }

  Widget _buildVocabCard(VocabularyItem item, AppStrings strings) {
    final isBookmarked = _bookmarkedVocabIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.word,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, size: 20, color: AppColors.mintDark),
                onPressed: () => _speak(item.word),
                visualDensity: VisualDensity.compact,
                tooltip: strings.listenPronunciation,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.meaningKo,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          if (item.meaningUserLang != null && item.meaningUserLang!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.meaningUserLang!,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ] else if (_autoTranslation != null && _autoTranslation!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${strings.dictTranslationLabel}$_autoTranslation',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF0D9488),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: isBookmarked
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2FBE8),
                      foregroundColor: const Color(0xFF166534),
                      elevation: 0,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(strings.savedToVocabulary),
                    onPressed: () => _toggleVocabBookmark(item, strings),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(strings.addToVocabulary),
                    onPressed: () => _toggleVocabBookmark(item, strings),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarCard(GrammarItem item, AppStrings strings) {
    final isBookmarked = _bookmarkedGrammarIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.pattern,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4338CA),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, size: 20, color: Color(0xFF4338CA)),
                onPressed: () => _speak(item.pattern),
                visualDensity: VisualDensity.compact,
                tooltip: strings.listenPronunciation,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: isBookmarked
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEF2FF),
                      foregroundColor: const Color(0xFF4338CA),
                      elevation: 0,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(strings.savedToGrammar),
                    onPressed: () => _toggleGrammarBookmark(item, strings),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(strings.addToGrammar),
                    onPressed: () => _toggleGrammarBookmark(item, strings),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView(String term, AppStrings strings) {
    final clean = _cleanWord(term);

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 36, color: Colors.black38),
              const SizedBox(height: 10),
              Text(
                '\'$clean\'',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (_autoTranslation != null && _autoTranslation!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.mintDark.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${strings.dictTranslationLabel}$_autoTranslation',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mintDark,
                    ),
                  ),
                ),
              ] else if (_translating) ...[
                const SizedBox(height: 6),
                Text(
                  strings.dictTranslating,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                strings.dictNoResultsDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 14),
              _customWordBookmarked
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2FBE8),
                        foregroundColor: const Color(0xFF166534),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(strings.savedToVocabulary),
                      onPressed: null,
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(strings.addToVocabulary),
                      onPressed: () => _addCustomWordToBookmark(clean, strings),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildExternalDictionaryButton(clean, strings),
      ],
    );
  }

  Widget _buildExternalDictionaryButton(String term, AppStrings strings) {
    final clean = _cleanWord(term);
    if (clean.isEmpty) return const SizedBox.shrink();

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF03C75A),
        side: const BorderSide(color: Color(0xFF03C75A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 11),
      ),
      icon: const Icon(Icons.open_in_new_rounded, size: 16),
      label: Text('${strings.viewNaverDict} (\'$clean\')'),
      onPressed: () => _openNaverDictionary(clean),
    );
  }
}
