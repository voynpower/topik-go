import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_dataset.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_master.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_service.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/presentation/grammar_detail_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_list_page.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

class MockKoreanLanguageNotifier extends LanguageNotifier {
  @override
  String build() => 'ko';
}

class MockUzbekLanguageNotifier extends LanguageNotifier {
  @override
  String build() => 'uz';
}

class FakeBookmarkRepository implements BookmarkRepository {
  @override
  Future<BookmarkSummary> getSummary() async =>
      const BookmarkSummary(questions: 0, vocabulary: 0, grammar: 0);

  @override
  Future<List<BookmarkedQuestion>> getQuestionBookmarks() async => [];

  @override
  Future<void> setQuestionBookmark(
      {required String questionId, required bool bookmarked}) async {}

  @override
  Future<List<BookmarkedVocabulary>> getVocabularyBookmarks() async => [];

  @override
  Future<void> setVocabularyBookmark(
      {required String vocabularyId,
      required bool bookmarked,
      String? meaningUserLang}) async {}

  @override
  Future<VocabularyItem> addVocabularyByWord(
      {required String word,
      String? meaningKo,
      String? meaningUserLang,
      int? level}) async {
    return VocabularyItem(
      id: '1',
      word: word,
      meaningKo: meaningKo ?? '',
      meaningUserLang: meaningUserLang,
      level: level ?? 1,
      isBookmarked: true,
      isDownloaded: false,
    );
  }

  @override
  Future<List<BookmarkedGrammar>> getGrammarBookmarks() async => [];

  @override
  Future<void> setGrammarBookmark(
      {required String grammarId, required bool bookmarked}) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Korean Master Grammar Dataset & Service Tests', () {
    test('Dataset has comprehensive 초급, 중급, 고급 coverage', () {
      final allItems = kMasterGrammarList;
      expect(allItems.length, greaterThanOrEqualTo(25));

      final beginner = allItems.where((g) => g.level <= 2).toList();
      final intermediate =
          allItems.where((g) => g.level == 3 || g.level == 4).toList();
      final advanced =
          allItems.where((g) => g.level == 5 || g.level == 6).toList();

      expect(beginner.isNotEmpty, isTrue, reason: '초급 문법 포함');
      expect(intermediate.isNotEmpty, isTrue, reason: '중급 문법 포함');
      expect(advanced.isNotEmpty, isTrue, reason: '고급 문법 포함');
    });

    test('All items have multilingual support (uz, ru, en, ko)', () {
      for (final item in kMasterGrammarList) {
        expect(item.getMeaning('uz').isNotEmpty, isTrue);
        expect(item.getMeaning('ru').isNotEmpty, isTrue);
        expect(item.getMeaning('en').isNotEmpty, isTrue);
        expect(item.getMeaning('ko').isNotEmpty, isTrue);

        expect(item.getExplanation('uz').isNotEmpty, isTrue);
        expect(item.getExplanation('ru').isNotEmpty, isTrue);
        expect(item.getExplanation('en').isNotEmpty, isTrue);
        expect(item.getExplanation('ko').isNotEmpty, isTrue);

        expect(item.examples.isNotEmpty, isTrue);
        for (final ex in item.examples) {
          expect(ex.korean.isNotEmpty, isTrue);
          expect(ex.getTranslation('uz').isNotEmpty, isTrue);
        }
      }
    });

    test('Search by Korean pattern keyword works via KoreanGrammarService.filterGrammars', () {
      final results = KoreanGrammarService.filterGrammars(
        allItems: kMasterGrammarList,
        params: const GrammarFilterParams(searchQuery: '바람에'),
        savedPatterns: {},
      );
      expect(results.any((g) => g.pattern == '-는 바람에'), isTrue);
    });

    test('Search by category works via KoreanGrammarService.filterGrammars', () {
      final results = KoreanGrammarService.filterGrammars(
        allItems: kMasterGrammarList,
        params: const GrammarFilterParams(category: GrammarCategoryType.reason),
        savedPatterns: {},
      );
      expect(results.length, greaterThanOrEqualTo(4));
      for (final g in results) {
        expect(g.category, equals('이유·원인'));
      }
    });

    test('Search by level group works via KoreanGrammarService.filterGrammars', () {
      final intermediate = KoreanGrammarService.filterGrammars(
        allItems: kMasterGrammarList,
        params: const GrammarFilterParams(levelGroup: GrammarLevelGroup.intermediate),
        savedPatterns: {},
      );
      for (final g in intermediate) {
        expect(g.level == 3 || g.level == 4, isTrue);
      }
    });

    test('Search by multilingual keyword in English / Uzbek works', () {
      final uzResults = KoreanGrammarService.filterGrammars(
        allItems: kMasterGrammarList,
        params: const GrammarFilterParams(searchQuery: 'sabab'),
        savedPatterns: {},
      );
      expect(uzResults.isNotEmpty, isTrue);

      final enResults = KoreanGrammarService.filterGrammars(
        allItems: kMasterGrammarList,
        params: const GrammarFilterParams(searchQuery: 'instead'),
        savedPatterns: {},
      );
      expect(enResults.any((g) => g.pattern.contains('대신에')), isTrue);
    });

    test('Convert MasterGrammarItem to GrammarItem for OneGrammar study', () {
      final item = KoreanGrammarService.findByPatternOrId('g_neun_barame')!;
      final studyItem = item.toGrammarItem();

      expect(studyItem.id, equals('g_neun_barame'));
      expect(studyItem.pattern, equals('-는 바람에'));
      expect(studyItem.tags.contains('이유·원인'), isTrue);
      expect(studyItem.examples.length, equals(item.examples.length));
    });

    test('MasterGrammarItem toJson and fromJson preserve rich data', () {
      final item = KoreanGrammarService.findByPatternOrId('g_neun_barame')!;
      final json = item.toJson();

      expect(json['id'], equals('g_neun_barame'));
      expect(json['meaning_uz'], contains('Kutilmagan'));
      expect((json['comparisons_json'] as List).isNotEmpty, isTrue);
      expect((json['quizzes_json'] as List).isNotEmpty, isTrue);

      final restored = MasterGrammarItem.fromJson(json);
      expect(restored.id, equals(item.id));
      expect(restored.pattern, equals(item.pattern));
      expect(restored.meaningUz, equals(item.meaningUz));
      expect(restored.comparisons.length, equals(item.comparisons.length));
      expect(restored.quizzes.length, equals(item.quizzes.length));
    });

    test('GrammarItem parses server JSON payload and converts to MasterGrammarItem', () {
      final serverJson = {
        'id': 'g_server_test',
        'pattern': '-느니 차라리',
        'description': '차라리 뒤의 행동을 하겠다는 선택',
        'level': 5,
        'category': '대조·양보',
        'meaning_ko': '차라리 뒤의 행동을 하겠다는 선택',
        'meaning_uz': 'Undan ko\'ra orqadagi ishni qilish afzalligini bildiradi',
        'explanation_ko': '둘 다 마음에 들지 않지만 차라리 뒤의 행동을 선택함',
        'conjugation_rule': '동사 어간 + 느니 차라리',
        'examples_json': [
          {
            'korean': '그런 모욕을 당하느니 차라리 회사를 그만두겠어요.',
            'uzbek': 'Bunday haqoratga chidagandan ko\'ra ishdan ketganim afzal.',
            'tag': 'TOPIK 고급',
          }
        ],
        'tags_json': ['TOPIK 5급', '선택', '대조'],
        'is_downloaded': 0,
        'is_bookmarked': 0,
      };

      final grammarItem = GrammarItem.fromJson(serverJson);
      expect(grammarItem.id, equals('g_server_test'));
      expect(grammarItem.level, equals(5));
      expect(grammarItem.meaningUz, contains('afzal'));

      final master = grammarItem.toMasterGrammarItem();
      expect(master.id, equals('g_server_test'));
      expect(master.pattern, equals('-느니 차라리'));
      expect(master.level, equals(5));
      expect(master.category, equals('대조·양보'));
      expect(master.getMeaning('uz'), contains('afzal'));
    });
  });

  group('Master Grammar UI Tests', () {
    testWidgets('GrammarListPage displays level tabs, chips, and master grammar items',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLanguageProvider.overrideWith(() => MockKoreanLanguageNotifier()),
            bookmarkRepositoryProvider
                .overrideWithValue(FakeBookmarkRepository()),
            bookmarkedGrammarProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GrammarListPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check level tabs exist
      expect(find.text('전체 문법'), findsOneWidget);
      expect(find.text('초급 (1~2급)'), findsOneWidget);
      expect(find.text('중급 (3~4급)'), findsOneWidget);
      expect(find.text('고급 (5~6급)'), findsOneWidget);
      expect(find.textContaining('내 문법장'), findsOneWidget);

      // Check search input hint
      expect(find.byType(TextField), findsOneWidget);

      // Check category chips
      expect(find.text('전체'), findsWidgets);
      expect(find.text('이유·원인'), findsWidgets);
      expect(find.text('대조·양보'), findsWidgets);

      // Check master grammar cards are rendered
      expect(find.text('-아서/어서'), findsOneWidget);
      expect(find.text('-기 때문에'), findsOneWidget);
    });

    testWidgets('GrammarDetailPage renders deep explanation, conjugation rules, and quiz',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLanguageProvider.overrideWith(() => MockUzbekLanguageNotifier()),
            bookmarkRepositoryProvider
                .overrideWithValue(FakeBookmarkRepository()),
            bookmarkedGrammarProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: GrammarDetailPage(id: 'g_neun_barame'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header pattern
      expect(find.text('-는 바람에'), findsWidgets);
      expect(find.text('이유·원인'), findsOneWidget);

      // Native explanation card
      expect(find.textContaining('O\'zbekcha'), findsOneWidget);

      // Conjugation rules matrix
      expect(find.text('형태 결합 공식 (Conjugation Rule)'), findsOneWidget);
      expect(find.textContaining('동사 어간 + 는 바람에'), findsOneWidget);

      // Confusing comparison section
      expect(find.text('헷갈리는 유사 문법 비교 (Comparison)'), findsOneWidget);
      expect(find.text('-느라고'), findsWidgets);
    });
  });
}
