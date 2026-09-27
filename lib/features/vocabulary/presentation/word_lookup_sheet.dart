import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

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
  String? _errorMessage;
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

  Future<void> _performSearch(String query) async {
    final term = _cleanWord(query);
    if (term.isEmpty) {
      setState(() {
        _vocabResults = [];
        _grammarResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _customWordBookmarked = false;
    });

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
      final vocabPage = results[0] as VocabularyPage;
      final grammarPage = results[1] as GrammarPage;

      if (mounted) {
        setState(() {
          _vocabResults = vocabPage.items;
          _grammarResults = grammarPage.items;
          for (final item in _vocabResults) {
            if (item.isBookmarked) _bookmarkedVocabIds.add(item.id);
          }
          for (final item in _grammarResults) {
            if (item.isBookmarked) _bookmarkedGrammarIds.add(item.id);
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = '단어 검색 중 오류가 발생했습니다.';
        });
      }
    }
  }

  Future<void> _toggleVocabBookmark(VocabularyItem item) async {
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
      await repo.setVocabularyBookmark(
        vocabularyId: item.id,
        bookmarked: newStatus,
      );
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedVocabularyProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '\'${item.word}\'이(가) 내 단어장에 추가되었습니다.'
                  : '\'${item.word}\'이(가) 내 단어장에서 삭제되었습니다.',
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
          const SnackBar(
            content: Text('단어장 저장에 실패했습니다. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addCustomWordToBookmark(String word) async {
    final clean = _cleanWord(word);
    if (clean.isEmpty) return;

    setState(() {
      _customWordBookmarked = true;
    });

    try {
      final repo = ref.read(bookmarkRepositoryProvider);
      await repo.addVocabularyByWord(word: clean);
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedVocabularyProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\'$clean\'이(가) 내 단어장에 추가되었습니다.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _customWordBookmarked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('단어장에 추가하지 못했습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleGrammarBookmark(GrammarItem item) async {
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
              newStatus
                  ? '\'${item.pattern}\'이(가) 내 문법장에 추가되었습니다.'
                  : '\'${item.pattern}\'이(가) 내 문법장에서 삭제되었습니다.',
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
              const Text(
                '단어 · 문법 사전',
                style: TextStyle(
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
              hintText: '단어 또는 문법 검색...',
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
                : _buildResultsList(term),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(String term) {
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
      return _buildNoResultsView(term);
    }

    return ListView(
      children: [
        if (hasVocab) ...[
          const Text(
            '어휘 (단어)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          ..._vocabResults.map(_buildVocabCard),
          const SizedBox(height: 14),
        ],
        if (hasGrammar) ...[
          const Text(
            '문법 표현',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          ..._grammarResults.map(_buildGrammarCard),
          const SizedBox(height: 14),
        ],
        _buildExternalDictionaryButton(term),
      ],
    );
  }

  Widget _buildVocabCard(VocabularyItem item) {
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
              const SizedBox(width: 8),
              if (item.level > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.level}급',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mintDark,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, size: 20, color: AppColors.mintDark),
                onPressed: () => _speak(item.word),
                visualDensity: VisualDensity.compact,
                tooltip: '발음 듣기',
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
                    label: const Text('단어장에 저장됨'),
                    onPressed: () => _toggleVocabBookmark(item),
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
                    label: const Text('+ 내 단어장에 추가'),
                    onPressed: () => _toggleVocabBookmark(item),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarCard(GrammarItem item) {
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
                tooltip: '발음 듣기',
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
                    label: const Text('문법장에 저장됨'),
                    onPressed: () => _toggleGrammarBookmark(item),
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
                    label: const Text('+ 내 문법장에 추가'),
                    onPressed: () => _toggleGrammarBookmark(item),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView(String term) {
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
              const SizedBox(height: 6),
              const Text(
                '사전 기본 등록어 목록에 없지만,\n내 단어장에 바로 추가하여 나중에 복습할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
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
                      label: const Text('내 단어장에 저장 완료!'),
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
                      label: const Text('+ 내 단어장에 추가'),
                      onPressed: () => _addCustomWordToBookmark(clean),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildExternalDictionaryButton(clean),
      ],
    );
  }

  Widget _buildExternalDictionaryButton(String term) {
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
      label: Text('네이버 국어사전에서 \'$clean\' 자세히 보기'),
      onPressed: () => _openNaverDictionary(clean),
    );
  }
}
