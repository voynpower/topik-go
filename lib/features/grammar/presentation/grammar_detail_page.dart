import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/network/api_error_message.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_master.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_service.dart';
import 'package:topik_go/features/grammar/domain/ai_grammar_service.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/domain/user_grammar_service.dart';
import 'package:topik_go/features/grammar/presentation/grammar_flashcard_page.dart';

class GrammarDetailPage extends ConsumerStatefulWidget {
  const GrammarDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<GrammarDetailPage> createState() => _GrammarDetailPageState();
}

class _GrammarDetailPageState extends ConsumerState<GrammarDetailPage> {
  FlutterTts? _tts;
  bool _saving = false;
  final Map<int, int> _selectedQuizAnswers = {};

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts()
      ..setLanguage('ko-KR')
      ..setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }

  void _speak(String text) async {
    await _tts?.stop();
    await _tts?.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final targetLang = ref.watch(currentLanguageProvider);
    final masterItem = ref.watch(masterGrammarDetailProvider(widget.id));

    // If found in Master Korean Grammar list, render full rich study experience
    if (masterItem != null) {
      return _buildMasterGrammarView(context, masterItem, targetLang);
    }

    // Fallback to server grammar item
    final serverItem = ref.watch(grammarItemProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: Text(strings.grammarDetail)),
      body: serverItem.when(
        data: (grammar) => _buildServerGrammarView(context, grammar, targetLang),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: apiErrorMessage(error, missingApiMessage: strings.error),
          retryText: strings.retry,
          onRetry: () => ref.invalidate(grammarItemProvider(widget.id)),
        ),
      ),
    );
  }

  Widget _buildMasterGrammarView(
    BuildContext context,
    MasterGrammarItem item,
    String targetLang,
  ) {
    final userGrammarState = ref.watch(userGrammarProvider);
    final isSaved = userGrammarState.isSaved(item.pattern);
    final langName = getLanguageDisplayName(targetLang);

    Color levelColor;
    if (item.level <= 2) {
      levelColor = const Color(0xFF059669); // Emerald
    } else if (item.level <= 4) {
      levelColor = const Color(0xFF2563EB); // Blue
    } else {
      levelColor = const Color(0xFF7C3AED); // Purple
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(item.pattern, style: const TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? const Color(0xFFD07A21) : null,
            ),
            onPressed: () => _toggleMasterBookmark(item, isSaved),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. Hero Card: Pattern, Level, Category & TTS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.levelLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: levelColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.pattern,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _speak(item.pattern),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          size: 22,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.getMeaning(targetLang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Native Language Deep Explanation Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_alt_outlined, color: Color(0xFF7C3AED), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$langName 상세 용법 & 뉘앙스',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.getExplanation(targetLang),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4C1D95),
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Conjugation Formula Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rule_folder_outlined, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 8),
                    Text(
                      '형태 결합 공식 (Conjugation Rule)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    item.conjugationRule,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Confusing Grammar Comparisons (if available)
          if (item.comparisons.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.compare_arrows_rounded, color: Color(0xFFD97706), size: 22),
                      SizedBox(width: 8),
                      Text(
                        '헷갈리는 유사 문법 비교 (Comparison)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...item.comparisons.map((c) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.targetPattern,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8))),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.comparisonPattern,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.getDifference(targetLang),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF78350F),
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. Graded Real Examples
          if (item.examples.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_quote_rounded, color: Color(0xFF475569), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '단계별 실전 예문 (${item.examples.length}개)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...item.examples.map((ex) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ex.tag,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ex.korean,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF7C3AED)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _speak(ex.korean),
                                ),
                              ],
                            ),
                            if (ex.getTranslation(targetLang).isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: Text(
                                  ex.getTranslation(targetLang),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 6. Interactive Self-Check Quizzes
          if (item.quizzes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.quiz_outlined, color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 8),
                      Text(
                        '즉석 이해도 자가점검 퀴즈',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...item.quizzes.asMap().entries.map((entry) {
                    final qIndex = entry.key;
                    final quiz = entry.value;
                    final selected = _selectedQuizAnswers[qIndex];
                    final isAnswered = selected != null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q. ${quiz.question}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...quiz.options.asMap().entries.map((optEntry) {
                          final optIndex = optEntry.key;
                          final optText = optEntry.value;

                          Color optBg = Colors.white;
                          Color optBorder = const Color(0xFFE2E8F0);
                          Color optTextCol = const Color(0xFF1E293B);

                          if (isAnswered) {
                            if (optIndex == quiz.correctIndex) {
                              optBg = const Color(0xFFDCFCE7);
                              optBorder = const Color(0xFF22C55E);
                              optTextCol = const Color(0xFF15803D);
                            } else if (optIndex == selected) {
                              optBg = const Color(0xFFFEE2E2);
                              optBorder = const Color(0xFFEF4444);
                              optTextCol = const Color(0xFFB91C1C);
                            }
                          }

                          return InkWell(
                            onTap: isAnswered
                                ? null
                                : () => setState(() => _selectedQuizAnswers[qIndex] = optIndex),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: optBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: optBorder, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: optBorder.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${optIndex + 1}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: optTextCol),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      optText,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: optTextCol),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (isAnswered) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected == quiz.correctIndex ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '💡 ${quiz.getExplanation(targetLang)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: selected == quiz.correctIndex ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 7. Flashcard Launcher Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.style_outlined, size: 20),
            label: const Text(
              '이 문법 플래시카드로 집중 학습하기',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GrammarFlashcardPage(
                    source: GrammarStudySource.custom([
                      item.toGrammarItem(isBookmarked: isSaved),
                    ]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServerGrammarView(
    BuildContext context,
    GrammarItem grammar,
    String targetLang,
  ) {
    final strings = ref.watch(appStringsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        grammar.pattern,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _speak(grammar.pattern),
                      icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF7C3AED)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  grammar.description,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.45),
                ),
                if (grammar.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: grammar.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (grammar.examples.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(strings.examples, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...grammar.examples.map(
            (example) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(example),
                trailing: IconButton(
                  icon: const Icon(Icons.volume_up_outlined, size: 18),
                  onPressed: () => _speak(example),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : () => _toggleBookmark(
                    grammar.id,
                    bookmarked: !grammar.isBookmarked,
                  ),
          icon: Icon(
            grammar.isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
          ),
          label: Text(grammar.isBookmarked ? strings.savedToGrammar : strings.addToGrammar),
        ),
      ],
    );
  }

  Future<void> _toggleMasterBookmark(MasterGrammarItem item, bool isSaved) async {
    final userNotifier = ref.read(userGrammarProvider.notifier);
    final strings = ref.read(appStringsProvider);

    if (isSaved) {
      await userNotifier.removeGrammar(item.pattern);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.delete), duration: const Duration(seconds: 1)),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.savedToGrammar), duration: const Duration(seconds: 1)),
        );
      }
    }
  }

  Future<void> _toggleBookmark(String id, {required bool bookmarked}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(grammarRepositoryProvider)
          .setGrammarBookmark(id: id, bookmarked: bookmarked);
      ref.invalidate(bookmarkSummaryProvider);
      ref.invalidate(bookmarkedGrammarProvider);
      ref.invalidate(grammarItemProvider(widget.id));
      final strings = ref.read(appStringsProvider);
      _showMessage(bookmarked ? strings.savedToGrammar : strings.delete);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
