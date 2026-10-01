import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/domain/ai_grammar_service.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/domain/user_grammar_service.dart';
import 'package:topik_go/features/grammar/presentation/ai_grammar_sheet.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

class MockLanguageNotifier extends LanguageNotifier {
  @override
  String build() => 'uz';
}

class FakeBookmarkRepository implements BookmarkRepository {
  @override
  Future<BookmarkSummary> getSummary() async => const BookmarkSummary(questions: 0, vocabulary: 0, grammar: 0);

  @override
  Future<List<BookmarkedQuestion>> getQuestionBookmarks() async => [];

  @override
  Future<void> setQuestionBookmark({required String questionId, required bool bookmarked}) async {}

  @override
  Future<List<BookmarkedVocabulary>> getVocabularyBookmarks() async => [];

  @override
  Future<void> setVocabularyBookmark({required String vocabularyId, required bool bookmarked, String? meaningUserLang}) async {}

  @override
  Future<VocabularyItem> addVocabularyByWord({required String word, String? meaningKo, String? meaningUserLang, int? level}) async {
    return VocabularyItem(id: '1', word: word, meaningKo: meaningKo ?? '', meaningUserLang: meaningUserLang, level: level ?? 1, isBookmarked: true, isDownloaded: false);
  }

  @override
  Future<List<BookmarkedGrammar>> getGrammarBookmarks() async => [];

  @override
  Future<void> setGrammarBookmark({required String grammarId, required bool bookmarked}) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiGrammarService Unit Tests', () {
    test('Matches seed grammar -는 바람에 and returns Uzbek explanations for uz', () async {
      final detail = await AiGrammarService.analyzeGrammar(
        selectedText: '늦잠을 자는 바람에 지각했다',
        contextSentence: '늦잠을 자는 바람에 시험에 늦었습니다.',
        targetLang: 'uz',
      );

      expect(detail.pattern, equals('-는 바람에'));
      expect(detail.category, equals('이유·원인'));
      expect(detail.level, equals(3));
      // Uzbek explanation check
      expect(detail.meaning.isNotEmpty, isTrue);
      expect(detail.meaning.contains('sabab'), isTrue);
      expect(detail.explanation.isNotEmpty, isTrue);
      expect(detail.examples.isNotEmpty, isTrue);
      expect(detail.contextSentence, equals('늦잠을 자는 바람에 시험에 늦었습니다.'));
    });

    test('Matches seed grammar -(으)ㄹ 뿐만 아니라 with Russian explanations for ru', () async {
      final detail = await AiGrammarService.analyzeGrammar(
        selectedText: '예쁠 뿐만 아니라',
        targetLang: 'ru',
      );

      expect(detail.pattern, equals('-(으)ㄹ 뿐만 아니라'));
      expect(detail.category, equals('대조·양보'));
      expect(detail.meaning.contains('не только') || detail.meaning.contains('только'), isTrue);
      expect(detail.examples.length, greaterThanOrEqualTo(1));
    });

    test('Matches seed grammar -(으)ㄴ/는 대신에 with English explanations for en', () async {
      final detail = await AiGrammarService.analyzeGrammar(
        selectedText: '밥 대신에 빵을 먹었다',
        targetLang: 'en',
      );

      expect(detail.pattern, equals('-(으)ㄴ/는 대신에'));
      expect(detail.meaning.toLowerCase().contains('instead'), isTrue);
      expect(detail.conjugationRule.isNotEmpty, isTrue);
    });

    test('Handles arbitrary unfamiliar grammar gracefully with fallback generator', () async {
      final detail = await AiGrammarService.analyzeGrammar(
        selectedText: '모르는문법형태',
        targetLang: 'ko',
      );

      expect(detail.pattern.contains('모르는문법형태'), isTrue);
      expect(detail.examples.isNotEmpty, isTrue);
      expect(detail.conjugationRule.contains('모르는문법형태'), isTrue);
    });
  });

  group('UserGrammarNotifier & Persistence Tests', () {
    test('Saves, checks, and removes grammar correctly', () async {
      final container = ProviderContainer(
        overrides: [
          bookmarkRepositoryProvider.overrideWithValue(FakeBookmarkRepository()),
          bookmarkedGrammarProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userGrammarProvider.notifier);

      expect(container.read(userGrammarProvider).isSaved('-는 바람에'), isFalse);

      const testGrammar = AiGrammarDetail(
        id: 'test_barame',
        pattern: '-는 바람에',
        category: '이유·원인',
        level: 3,
        meaning: 'Salbiy oqibatga sabab bo\'lish',
        explanation: 'Kutilmagan salbiy natija bildiradi',
        conjugationRule: 'Fe\'l + 는 바람에',
        examples: [
          AiGrammarExample(
            korean: '비가 오는 바람에 축구가 취소되었다.',
            translation: 'Yomg\'ir yoqqanligi sababli futbol bekor qilindi.',
          ),
        ],
        isBookmarked: true,
      );

      await notifier.saveGrammar(testGrammar);

      final stateAfterSave = container.read(userGrammarProvider);
      expect(stateAfterSave.isSaved('-는 바람에'), isTrue);
      expect(stateAfterSave.isSaved('는 바람에'), isTrue);
      expect(stateAfterSave.savedGrammars.length, equals(1));

      // Test toGrammarItems conversion for OneGrammar study
      final grammarItems = stateAfterSave.toGrammarItems();
      expect(grammarItems.length, equals(1));
      expect(grammarItems.first.pattern, equals('-는 바람에'));
      expect(grammarItems.first.isBookmarked, isTrue);
      expect(grammarItems.first.examples.first, equals('비가 오는 바람에 축구가 취소되었다.'));

      // Remove grammar
      await notifier.removeGrammar('-는 바람에');
      final stateAfterRemove = container.read(userGrammarProvider);
      expect(stateAfterRemove.isSaved('-는 바람에'), isFalse);
      expect(stateAfterRemove.savedGrammars.isEmpty, isTrue);
    });

    test('studyGrammarProvider includes user saved grammars in saved source', () async {
      final container = ProviderContainer(
        overrides: [
          bookmarkRepositoryProvider.overrideWithValue(FakeBookmarkRepository()),
          bookmarkedGrammarProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      const testGrammar = AiGrammarDetail(
        id: 'test_g1',
        pattern: '-(으)ㄹ 뿐만 아니라',
        category: '대조·양보',
        level: 3,
        meaning: 'Not only but also',
        explanation: 'Additional fact',
        conjugationRule: 'V/A + (으)ㄹ 뿐만 아니라',
        examples: [
          AiGrammarExample(korean: '공부도 잘할 뿐만 아니라 운동도 잘해요.', translation: ''),
        ],
      );

      await container.read(userGrammarProvider.notifier).saveGrammar(testGrammar);

      final items = await container.read(studyGrammarProvider(const GrammarStudySource.saved()).future);
      expect(items.any((g) => g.pattern == '-(으)ㄹ 뿐만 아니라'), isTrue);
    });
  });

  group('AiGrammarSheet Widget Tests', () {
    testWidgets('Renders AI Grammar sheet details with pattern, badges, and examples', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLanguageProvider.overrideWith(() => MockLanguageNotifier()),
            bookmarkRepositoryProvider.overrideWithValue(FakeBookmarkRepository()),
            bookmarkedGrammarProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AiGrammarSheet(
                selectedText: '-는 바람에',
                contextSentence: '비가 오는 바람에 길이 막혔습니다.',
              ),
            ),
          ),
        ),
      );

      // Wait for async provider to finish loading
      await tester.pumpAndSettle();

      // Verify pattern header
      expect(find.text('-는 바람에'), findsOneWidget);

      // Verify category & AI tag
      expect(find.text('이유·원인'), findsOneWidget);
      expect(find.text('AI 문법 분석'), findsOneWidget);

      // Verify context passage sentence
      expect(find.textContaining('비가 오는 바람에 길이 막혔습니다.'), findsAtLeastNWidgets(1));

      // Verify AI explanation in target language (Uzbek) is rendered
      expect(find.textContaining("O'zbekcha"), findsOneWidget);
      expect(find.textContaining('해설'), findsAtLeastNWidgets(1));

      // Verify save to grammar book button is present
      expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);

      // Tap save to grammar book
      await tester.tap(find.byIcon(Icons.bookmark_add_outlined));
      await tester.pumpAndSettle();

      // Icon should now be active bookmark
      expect(find.byIcon(Icons.bookmark_added), findsOneWidget);
    });
  });
}
